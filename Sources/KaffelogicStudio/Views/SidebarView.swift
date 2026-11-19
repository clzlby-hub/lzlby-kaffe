import SwiftUI

private enum SidebarSelection: Hashable {
    case profile(UUID)
    case log(UUID)
}

public struct SidebarView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    @ObservedObject var device = DeviceManager.shared
    
    @State private var searchText = ""
    @State private var selection: SidebarSelection? = nil
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
        List(selection: $selection) {
            Section {
                HStack(spacing: 8) {
                    Circle()
                        .fill(device.state.isConnected ? Color.green : Color.secondary.opacity(0.45))
                        .frame(width: 8, height: 8)
                    Text(device.state.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button(action: { device.scanManually() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("重新扫描 USB 设备")
                    
                    Button(action: { state.openSyncFolder() }) {
                        Image(systemName: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("在 Finder 中打开同步目录")
                }
                .padding(.vertical, 2)
            } header: {
                Text("设备")
            }
            
            Section("烘焙方案 (\(filteredProfiles.count))") {
                ForEach(filteredProfiles) { profile in
                    HStack(spacing: 8) {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(state.selectedProfile.id == profile.id ? Color.orange : Color.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.shortName)
                                .font(.body)
                                .lineLimit(1)
                            
                            Text("Lv \(String(format: "%.1f", profile.recommendedLevel)) · \(Int(profile.referenceLoadSize))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(SidebarSelection.profile(profile.id))
                    .contextMenu {
                        Button {
                            targetProfileToRename = profile
                            renameText = profile.shortName
                            renameTargetType = "profile"
                            showingRenameAlert = true
                        } label: {
                            Label("重命名方案...", systemImage: "pencil")
                        }
                        
                        Button {
                            state.comparisonProfile = profile
                            state.isComparingDefault = false
                        } label: {
                            Label("设为对比图层", systemImage: "square.2.layers.3d")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            withAnimation { state.deleteProfile(profile) }
                        } label: {
                            Label("删除方案", systemImage: "trash")
                        }
                    }
                }
            }
            
            Section("历史烘焙记录 (\(filteredLogs.count))") {
                if filteredLogs.isEmpty {
                    Text("暂无历史记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLogs) { log in
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(state.selectedLog?.id == log.id ? Color.red : Color.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.title)
                                    .font(.body)
                                    .lineLimit(1)
                                
                                HStack(spacing: 5) {
                                    Text(log.profileUsed)
                                    if let loss = log.weightLossPercent {
                                        Text("· 失水 \(String(format: "%.1f%%", loss))")
                                    }
                                    if let score = log.cuppingScore, score > 0 {
                                        Text("· ★\(String(format: "%.0f", score))")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            }
                        }
                        .tag(SidebarSelection.log(log.id))
                        .contextMenu {
                            Button {
                                targetLogToRename = log
                                renameText = log.title
                                renameTargetType = "log"
                                showingRenameAlert = true
                            } label: {
                                Label("重命名记录...", systemImage: "pencil")
                            }
                            
                            Button {
                                state.comparisonLog = log
                            } label: {
                                Label("作为对比曲线叠加", systemImage: "square.2.layers.3d")
                            }
                            
                            Button {
                                extractProfile(from: log)
                            } label: {
                                Label("提取实测为新方案 (Make Profile)", systemImage: "wand.and.stars")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                withAnimation { state.deleteLog(log) }
                            } label: {
                                Label("删除此记录", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "搜索方案或烘焙记录")
        .onChange(of: selection) { _, newSel in
            switch newSel {
            case .profile(let id):
                if let p = state.profiles.first(where: { $0.id == id }) {
                    state.selectProfile(p)
                    state.inspectorTab = .profile
                }
            case .log(let id):
                if let l = state.logs.first(where: { $0.id == id }) {
                    state.selectLog(l)
                    state.inspectorTab = .log
                }
            case .none:
                break
            }
        }
        .onAppear {
            selection = .profile(state.selectedProfile.id)
        }
        .onDeleteCommand {
            switch selection {
            case .log(let id):
                if let l = state.logs.first(where: { $0.id == id }) {
                    withAnimation { state.deleteLog(l) }
                }
            case .profile(let id):
                if state.profiles.count > 1, let p = state.profiles.first(where: { $0.id == id }) {
                    withAnimation { state.deleteProfile(p) }
                }
            case .none:
                break
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Button(action: { state.createNewProfile() }) {
                    Label("新建", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("新建烘焙方案 (⌘N)")
                
                Button(action: { isImporting = true }) {
                    Label("导入", systemImage: "square.and.arrow.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("导入烘焙文件 (.kpro, .klog)")
                
                Spacer()
                
                Text("\(state.profiles.count)方案 · \(state.logs.count)记录")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
            .overlay(Divider(), alignment: .top)
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
