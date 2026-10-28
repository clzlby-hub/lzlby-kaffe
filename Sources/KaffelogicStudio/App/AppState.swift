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
    @Published public var showFanCurve: Bool = false
    @Published public var showPhasesOverlay: Bool = true
    @Published public var tempUnit: TemperatureUnit = .celsius
    @Published public var isInspectorPresented: Bool = true
    
    public init() {
        let defaultP = BuiltinProfiles.classic
        self.profiles = [defaultP, BuiltinProfiles.explorer]
        self.selectedProfile = defaultP
        
        let sampleLog = BuiltinProfiles.sampleLog(for: defaultP)
        self.logs = [sampleLog]
        self.selectedLog = sampleLog
    }
    
    public func selectProfile(_ profile: RoastProfile) {
        self.selectedProfile = profile
        if selectedLog?.profileUsed != profile.shortName {
            let log = BuiltinProfiles.sampleLog(for: profile)
            self.selectedLog = log
        }
    }
    
    // MARK: - 删除与管理操作 (新增)
    public func deleteProfile(_ profile: RoastProfile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles.remove(at: idx)
        if selectedProfile.id == profile.id {
            if let first = profiles.first {
                selectedProfile = first
            } else {
                let fallback = BuiltinProfiles.classic
                profiles.append(fallback)
                selectedProfile = fallback
            }
        }
    }
    
    public func deleteLog(_ log: RoastLog) {
        guard let idx = logs.firstIndex(where: { $0.id == log.id }) else { return }
        logs.remove(at: idx)
        if selectedLog?.id == log.id {
            selectedLog = logs.first
        }
    }
    
    public func renameProfile(_ profile: RoastProfile, newName: String) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[idx].shortName = newName
        if selectedProfile.id == profile.id {
            selectedProfile.shortName = newName
        }
    }
    
    public func renameLog(_ log: RoastLog, newTitle: String) {
        guard let idx = logs.firstIndex(where: { $0.id == log.id }) else { return }
        logs[idx].title = newTitle
        if selectedLog?.id == log.id {
            selectedLog?.title = newTitle
        }
    }
    
    // MARK: - 对比工具方法
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
    
    public func openSyncFolder() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let syncDir = docs.appendingPathComponent("kaffelogic", isDirectory: true)
        let profilesDir = syncDir.appendingPathComponent("roast-profiles", isDirectory: true)
        let logsDir = syncDir.appendingPathComponent("roast-logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: profilesDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(syncDir)
    }
    
    public func openBackupFolder() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupDir = docs.appendingPathComponent("kaffelogic-backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(backupDir)
    }
    
    public func importFile(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let (p, l) = KaffelogicParser.parse(content: content)
        self.profiles.append(p)
        self.selectedProfile = p
        if let l = l {
            self.logs.append(l)
            self.selectedLog = l
        }
    }
}
