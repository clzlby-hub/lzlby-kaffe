import SwiftUI

public struct SidebarView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    @ObservedObject var device = DeviceManager.shared
    
    @State private var searchText = ""
    @State private var isImporting = false
    @State private var showingRenameAlert = false
    @State private var renameTargetType: String = ""
    @State private var renameText: String = ""
    @State private var targetProfileToRename: RoastProfile? = nil
    @State private var targetLogToRename: RoastLog? = nil
    
    private var filteredProfiles: [RoastProfile] {
        guard !searchText.isEmpty else { return state.profiles }
        return state.profiles.filter {
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            $0.designer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredLogs: [RoastLog] {
        guard !searchText.isEmpty else { return state.logs }
        return state.logs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.profileUsed.localizedCaseInsensitiveContains(searchText) ||
            $0.beanOrigin.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索与设备状态条
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    TextField("搜索方案或烘焙记录...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(6)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(device.state.isConnected ? Color.green : Color.gray.opacity(0.55))
                        .frame(width: 7, height: 7)
                    Text(device.state.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button(action: { device.scanManually() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("重新扫描 USB 设备")
                    
                    Button(action: { state.openSyncFolder() }) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("打开本地同步目录 (~/Documents/kaffelogic)")
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)
            
            Divider()
            
            List {
                Section("烘焙方案 (\(filteredProfiles.count))") {
                    ForEach(filteredProfiles) { profile in
                        HStack(spacing: 8) {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundColor(state.selectedProfile.id == profile.id ? .orange : .secondary)
                                .font(.system(size: 13))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.shortName)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    Text("Lv \(String(format: "%.1f", profile.recommendedLevel))")
                                    Text("·")
                                    Text("\(Int(profile.referenceLoadSize))g")
                                }
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            state.selectProfile(profile)
                            state.inspectorTab = .profile
                        }
                        .listRowBackground(state.selectedProfile.id == profile.id ? Color.accentColor.opacity(0.18) : Color.clear)
                        .contextMenu {
                            Button(action: {
                                targetProfileToRename = profile
                                renameText = profile.shortName
                                renameTargetType = "profile"
                                showingRenameAlert = true
                            }) {
                                Label("重命名方案...", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                state.comparisonProfile = profile
                                state.isComparingDefault = false
                            }) {
                                Label("设为对比图层", systemImage: "square.2.layers.3d")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                withAnimation { state.deleteProfile(profile) }
                            }) {
                                Label("删除方案", systemImage: "trash")
                            }
                        }
                    }
                }
                
                Section("历史烘焙记录 (\(filteredLogs.count))") {
                    if filteredLogs.isEmpty {
                        Text("暂无历史记录")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(filteredLogs) { log in
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(state.selectedLog?.id == log.id ? .red : .secondary)
                                    .font(.system(size: 13))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 5) {
                                        Text(log.profileUsed)
                                        if let loss = log.weightLossPercent {
                                            Text("· 失水 \(String(format: "%.1f%%", loss))")
                                        }
                                        if let score = log.cuppingScore, score > 0 {
                                            Text("· ★\(String(format: "%.0f", score))")
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                state.selectLog(log)
                                state.inspectorTab = .log
                            }
                            .listRowBackground(state.selectedLog?.id == log.id ? Color.red.opacity(0.15) : Color.clear)
                            .contextMenu {
                                Button(action: {
                                    targetLogToRename = log
                                    renameText = log.title
                                    renameTargetType = "log"
                                    showingRenameAlert = true
                                }) {
                                    Label("重命名记录...", systemImage: "pencil")
                                }
                                
                                Button(action: { state.comparisonLog = log }) {
                                    Label("作为对比曲线叠加", systemImage: "square.2.layers.3d")
                                }
                                
                                Button(action: { extractProfile(from: log) }) {
                                    Label("提取实测为新方案 (Make Profile)", systemImage: "wand.and.stars")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    withAnimation { state.deleteLog(log) }
                                }) {
                                    Label("删除此记录", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .onDeleteCommand {
                if let log = state.selectedLog {
                    withAnimation { state.deleteLog(log) }
                }
            }
            
            Divider()
            
            HStack(spacing: 4) {
                Button(action: { state.createNewProfile() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("新建烘焙方案")
                
                Button(action: { isImporting = true }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("打开 / 导入烘焙文件 (.kpro, .klog)")
                
                Button(action: {
                    if let log = state.selectedLog {
                        withAnimation { state.deleteLog(log) }
                    } else {
                        withAnimation { state.deleteProfile(state.selectedProfile) }
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 28, height: 26)
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("删除选中的记录或方案")
                .disabled(state.selectedLog == nil && state.profiles.count <= 1)
                
                Spacer()
                
                Text("\(state.profiles.count)方案 · \(state.logs.count)记录")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Material.bar)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls { state.importFile(from: url) }
            }
        }
        .alert(renameTargetType == "profile" ? "重命名烘焙方案" : "重命名历史记录", isPresented: $showingRenameAlert) {
            TextField("输入新名称", text: $renameText)
            Button("保存") {
                if renameTargetType == "profile", let p = targetProfileToRename {
                    state.renameProfile(p, newName: renameText)
                } else if renameTargetType == "log", let l = targetLogToRename {
                    state.renameLog(l, newTitle: renameText)
                }
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    private func extractProfile(from log: RoastLog) {
        var newP = state.selectedProfile
        newP.id = UUID()
        newP.fileName = nil
        newP.shortName = "\(log.title) (提取)"
        newP.roastProfilePoints = log.samples.enumerated().compactMap { (idx, s) in
            if idx % 15 == 0 || idx == log.samples.count - 1 {
                return ProfilePoint(x: s.time, y: s.beanTemp)
            }
            return nil
        }
        state.profiles.append(newP)
        state.selectProfile(newP)
        state.saveProfileToDisk(newP)
    }
}
