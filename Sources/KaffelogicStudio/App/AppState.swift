import SwiftUI
import Combine
import AppKit

public enum DifficultyLevel: String, CaseIterable, Identifiable {
    case basic = "Basic"
    case advanced = "Advanced"
    case expert = "Expert"
    case engineer = "Engineer"
    public var id: String { rawValue }
    
    public var localizedName: String {
        switch self {
        case .basic: return loc("diff_basic")
        case .advanced: return loc("diff_advanced")
        case .expert: return loc("diff_expert")
        case .engineer: return loc("diff_engineer")
        }
    }
}

public enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"
    public var id: String { rawValue }
}

public enum ChartEditMode: String, CaseIterable, Identifiable {
    case view = "查看"
    case editTargetTemp = "编辑豆温"
    case editFanSpeed = "编辑风扇"
    public var id: String { rawValue }
}

public enum InspectorTab: String, CaseIterable, Identifiable {
    case profile = "方案参数"
    case log = "烘焙记录"
    public var id: String { rawValue }
}

public class AppState: ObservableObject {
    @Published public var profiles: [RoastProfile] = []
    @Published public var selectedProfile: RoastProfile
    @Published public var logs: [RoastLog] = []
    @Published public var selectedLog: RoastLog? = nil
    
    @Published public var comparisonProfile: RoastProfile? = nil
    @Published public var comparisonLog: RoastLog? = nil
    @Published public var isComparingDefault: Bool = false
    
    @AppStorage("difficulty_level") public var difficulty: DifficultyLevel = .advanced
    
    @Published public var showAUCDialog: Bool = false
    @Published public var showTimeCalculator: Bool = false
    @Published public var showTransformDialog: Bool = false
    @Published public var showMergeDialog: Bool = false
    @Published public var showGeneralOptions: Bool = false
    @Published public var showCompareOptions: Bool = false
    @Published public var showViewRoaster: Bool = false
    @Published public var showTipsSheet: Bool = false
    
    @Published public var showTargetCurve: Bool = true
    @Published public var showBeanTempCurve: Bool = true
    @Published public var showRoRCurve: Bool = true
    @Published public var showFanCurve: Bool = true
    @Published public var showPowerCurve: Bool = false
    @Published public var showPhasesOverlay: Bool = true
    @Published public var tempUnit: TemperatureUnit = .celsius
    @Published public var isInspectorPresented: Bool = true
    @Published public var inspectorTab: InspectorTab = .profile
    
    @Published public var chartEditMode: ChartEditMode = .editTargetTemp
    @Published public var selectedPointIndex: Int? = nil
    @Published public var chartZoomScale: Double = 1.0
    @Published public var chartTimeOffset: Double = 0.0
    
    // MARK: - 缓存计算结果（避免悬停重绘卡顿）
    @Published public private(set) var cachedTargetCurve: [EvaluatedCurvePoint] = []
    @Published public private(set) var cachedFanCurve: [EvaluatedCurvePoint] = []
    @Published public private(set) var cachedRoRCurve: [EvaluatedCurvePoint] = []
    @Published public private(set) var cachedPhaseSummary: RoastPhaseSummary = RoastPhaseSummary()
    
    // MARK: - 撤销/重做栈
    private var undoStack: [RoastProfile] = []
    private var redoStack: [RoastProfile] = []
    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }
    
    private var saveWorkItem: DispatchWorkItem?
    
    public var syncDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("kaffelogic", isDirectory: true)
    }
    
    public var profilesDirectoryURL: URL {
        syncDirectoryURL.appendingPathComponent("roast-profiles", isDirectory: true)
    }
    
    public var logsDirectoryURL: URL {
        syncDirectoryURL.appendingPathComponent("roast-logs", isDirectory: true)
    }
    
    public init() {
        let defaultP = BuiltinProfiles.classic
        self.profiles = [defaultP, BuiltinProfiles.explorer]
        self.selectedProfile = defaultP
        
        let sampleLog = BuiltinProfiles.sampleLog(for: defaultP)
        self.logs = [sampleLog]
        self.selectedLog = sampleLog
        
        ensureDirectories()
        loadFromDisk()
        recomputeCaches()
        
        DeviceManager.shared.onRoastFinished = { [weak self] finishedLog in
            DispatchQueue.main.async {
                guard let self else { return }
                self.logs.insert(finishedLog, at: 0)
                self.selectedLog = finishedLog
                self.inspectorTab = .log
                self.saveLogToDisk(finishedLog)
                self.recomputeCaches()
            }
        }
    }
    
    // MARK: - 温度单位换算
    public func displayTemp(_ celsius: Double) -> Double {
        tempUnit == .celsius ? celsius : (celsius * 9.0 / 5.0 + 32.0)
    }
    
    public func celsiusFromDisplay(_ value: Double) -> Double {
        tempUnit == .celsius ? value : ((value - 32.0) * 5.0 / 9.0)
    }
    
    public func formatTemp(_ celsius: Double, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f%@", displayTemp(celsius), tempUnit.rawValue)
    }
    
    public func formatRoR(_ cPerMin: Double) -> String {
        let v = tempUnit == .celsius ? cPerMin : (cPerMin * 9.0 / 5.0)
        return String(format: "%.1f %@/分", v, tempUnit.rawValue)
    }
    
    // MARK: - 缓存重算
    public func recomputeCaches() {
        let target = BezierMath.evaluateCurve(points: selectedProfile.roastProfilePoints, samplesPerSegment: 40)
        cachedTargetCurve = target
        cachedFanCurve = BezierMath.evaluateCurve(points: selectedProfile.fanProfilePoints, samplesPerSegment: 30)
        if let log = selectedLog, log.samples.count >= 2 {
            cachedRoRCurve = ROREngine.calculateRoR(samples: log.samples.map { ($0.time, $0.beanTemp) })
        } else {
            cachedRoRCurve = []
        }
        cachedPhaseSummary = ROREngine.computePhases(curve: target, expectFC: selectedProfile.expectFirstCrack)
    }
    
    // MARK: - 选择与同步更新（修复值类型修改不回写的问题）
    public func selectProfile(_ profile: RoastProfile) {
        self.selectedProfile = profile
        self.selectedPointIndex = nil
        self.undoStack.removeAll()
        self.redoStack.removeAll()
        if selectedLog?.profileUsed != profile.shortName {
            if let matchingLog = logs.first(where: { $0.profileUsed == profile.shortName }) {
                self.selectedLog = matchingLog
            } else {
                let log = BuiltinProfiles.sampleLog(for: profile)
                self.selectedLog = log
            }
        }
        recomputeCaches()
    }
    
    public func selectLog(_ log: RoastLog) {
        self.selectedLog = log
        recomputeCaches()
    }
    
    public func pushUndoSnapshot() {
        undoStack.append(selectedProfile)
        if undoStack.count > 40 { undoStack.removeFirst() }
        redoStack.removeAll()
    }
    
    public func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(selectedProfile)
        applyProfileUpdate(prev)
    }
    
    public func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(selectedProfile)
        applyProfileUpdate(next)
    }
    
    public func updateSelectedProfile(_ transform: (inout RoastProfile) -> Void) {
        var updated = selectedProfile
        transform(&updated)
        applyProfileUpdate(updated)
    }
    
    private func applyProfileUpdate(_ updated: RoastProfile) {
        selectedProfile = updated
        if let idx = profiles.firstIndex(where: { $0.id == updated.id }) {
            profiles[idx] = updated
        }
        recomputeCaches()
        scheduleSaveProfile(updated)
    }
    
    public func updateSelectedLog(_ transform: (inout RoastLog) -> Void) {
        guard var updated = selectedLog else { return }
        transform(&updated)
        selectedLog = updated
        if let idx = logs.firstIndex(where: { $0.id == updated.id }) {
            logs[idx] = updated
        }
        recomputeCaches()
        scheduleSaveLog(updated)
    }
    
    // MARK: - 增删改查
    public func createNewProfile() {
        var newP = RoastProfile(shortName: "未命名烘焙方案")
        newP.roastProfilePoints = [
            ProfilePoint(x: 0, y: 120),
            ProfilePoint(x: 120, y: 145),
            ProfilePoint(x: 260, y: 175),
            ProfilePoint(x: 420, y: 205),
            ProfilePoint(x: 510, y: 215)
        ]
        newP.fanProfilePoints = [
            ProfilePoint(x: 0, y: 15000),
            ProfilePoint(x: 240, y: 14000),
            ProfilePoint(x: 510, y: 12500)
        ]
        profiles.append(newP)
        selectProfile(newP)
        saveProfileToDisk(newP)
    }
    
    public func deleteProfile(_ profile: RoastProfile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles.remove(at: idx)
        deleteProfileFromDisk(profile)
        if selectedProfile.id == profile.id {
            if let first = profiles.first {
                selectProfile(first)
            } else {
                let fallback = BuiltinProfiles.classic
                profiles.append(fallback)
                selectProfile(fallback)
            }
        }
    }
    
    public func deleteLog(_ log: RoastLog) {
        guard let idx = logs.firstIndex(where: { $0.id == log.id }) else { return }
        logs.remove(at: idx)
        deleteLogFromDisk(log)
        if selectedLog?.id == log.id {
            selectedLog = logs.first
            recomputeCaches()
        }
    }
    
    public func renameProfile(_ profile: RoastProfile, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        deleteProfileFromDisk(profiles[idx])
        profiles[idx].shortName = trimmed
        profiles[idx].fileName = sanitizedFileName(trimmed, ext: "kpro")
        if selectedProfile.id == profile.id {
            selectedProfile = profiles[idx]
        }
        saveProfileToDisk(profiles[idx])
    }
    
    public func renameLog(_ log: RoastLog, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = logs.firstIndex(where: { $0.id == log.id }) else { return }
        deleteLogFromDisk(logs[idx])
        logs[idx].title = trimmed
        logs[idx].fileName = sanitizedFileName(trimmed, ext: "klog")
        if selectedLog?.id == log.id {
            selectedLog = logs[idx]
        }
        saveLogToDisk(logs[idx])
    }
    
    // MARK: - 对比工具
    public func toggleCompareDefault() {
        if isComparingDefault {
            clearComparison()
        } else {
            isComparingDefault = true
            comparisonProfile = BuiltinProfiles.classic
        }
    }
    
    public func compareWithFile(url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let (p, l) = KaffelogicParser.parse(content: content)
        if let log = l {
            comparisonLog = log
        } else {
            comparisonProfile = p
        }
    }
    
    public func clearComparison() {
        isComparingDefault = false
        comparisonProfile = nil
        comparisonLog = nil
    }
    
    // MARK: - 本地磁盘持久化与导入导出
    private func ensureDirectories() {
        try? FileManager.default.createDirectory(at: profilesDirectoryURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
    }
    
    private func sanitizedFileName(_ name: String, ext: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let clean = name.components(separatedBy: invalid).joined(separator: "_")
        return "\(clean.isEmpty ? "untitled" : clean).\(ext)"
    }
    
    private func scheduleSaveProfile(_ profile: RoastProfile) {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.saveProfileToDisk(profile)
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }
    
    private func scheduleSaveLog(_ log: RoastLog) {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.saveLogToDisk(log)
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }
    
    public func saveProfileToDisk(_ profile: RoastProfile) {
        ensureDirectories()
        let fname = profile.fileName ?? sanitizedFileName(profile.shortName, ext: "kpro")
        let url = profilesDirectoryURL.appendingPathComponent(fname)
        let content = KaffelogicParser.exportKPro(profile)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }), profiles[idx].fileName == nil {
            profiles[idx].fileName = fname
            if selectedProfile.id == profile.id { selectedProfile.fileName = fname }
        }
    }
    
    public func saveLogToDisk(_ log: RoastLog) {
        ensureDirectories()
        let fname = log.fileName ?? sanitizedFileName(log.title, ext: "klog")
        let url = logsDirectoryURL.appendingPathComponent(fname)
        let content = KaffelogicParser.exportKLog(log)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        if let idx = logs.firstIndex(where: { $0.id == log.id }), logs[idx].fileName == nil {
            logs[idx].fileName = fname
            if selectedLog?.id == log.id { selectedLog?.fileName = fname }
        }
    }
    
    private func deleteProfileFromDisk(_ profile: RoastProfile) {
        let fname = profile.fileName ?? sanitizedFileName(profile.shortName, ext: "kpro")
        let url = profilesDirectoryURL.appendingPathComponent(fname)
        try? FileManager.default.removeItem(at: url)
    }
    
    private func deleteLogFromDisk(_ log: RoastLog) {
        let fname = log.fileName ?? sanitizedFileName(log.title, ext: "klog")
        let url = logsDirectoryURL.appendingPathComponent(fname)
        try? FileManager.default.removeItem(at: url)
    }
    
    public func loadFromDisk() {
        let fm = FileManager.default
        if let profileFiles = try? fm.contentsOfDirectory(at: profilesDirectoryURL, includingPropertiesForKeys: nil) {
            let kpros = profileFiles.filter { ["kpro", "npro"].contains($0.pathExtension.lowercased()) }
            var loaded: [RoastProfile] = []
            for url in kpros.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    var (p, _) = KaffelogicParser.parse(content: content)
                    p.fileName = url.lastPathComponent
                    if p.shortName == "My Roast Profile" {
                        p.shortName = url.deletingPathExtension().lastPathComponent
                    }
                    loaded.append(p)
                }
            }
            if !loaded.isEmpty {
                self.profiles = loaded
                self.selectedProfile = loaded[0]
            } else {
                for p in profiles { saveProfileToDisk(p) }
            }
        }
        
        if let logFiles = try? fm.contentsOfDirectory(at: logsDirectoryURL, includingPropertiesForKeys: nil) {
            let klogs = logFiles.filter { ["klog", "nlog", "csv"].contains($0.pathExtension.lowercased()) }
            var loadedLogs: [RoastLog] = []
            for url in klogs.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    var (p, l) = KaffelogicParser.parse(content: content)
                    if var log = l ?? (content.contains("time,") ? KaffelogicParser.parseLog(content, profileUsed: p.shortName) : nil) {
                        log.fileName = url.lastPathComponent
                        if log.title == "Roast Log" {
                            log.title = url.deletingPathExtension().lastPathComponent
                        }
                        loadedLogs.append(log)
                    }
                }
            }
            if !loadedLogs.isEmpty {
                self.logs = loadedLogs
                self.selectedLog = loadedLogs[0]
            }
        }
    }
    
    public func openSyncFolder() {
        ensureDirectories()
        NSWorkspace.shared.open(syncDirectoryURL)
    }
    
    public func openBackupFolder() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupDir = docs.appendingPathComponent("kaffelogic-backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(backupDir)
    }
    
    public func importFile(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let ext = url.pathExtension.lowercased()
        let (p, l) = KaffelogicParser.parse(content: content)
        if ext == "klog" || ext == "nlog", var log = l ?? (content.contains("time,") ? KaffelogicParser.parseLog(content, profileUsed: p.shortName) : nil) {
            if log.title == "Roast Log" {
                log.title = url.deletingPathExtension().lastPathComponent
            }
            self.logs.insert(log, at: 0)
            self.selectedLog = log
            self.inspectorTab = .log
            saveLogToDisk(log)
            recomputeCaches()
            return
        }
        var profile = p
        if profile.shortName == "My Roast Profile" {
            profile.shortName = url.deletingPathExtension().lastPathComponent
        }
        self.profiles.append(profile)
        self.selectProfile(profile)
        saveProfileToDisk(profile)
        if var log = l {
            if log.title == "Roast Log" {
                log.title = "\(url.deletingPathExtension().lastPathComponent) 日志"
            }
            self.logs.insert(log, at: 0)
            self.selectedLog = log
            saveLogToDisk(log)
            recomputeCaches()
        }
    }
}
