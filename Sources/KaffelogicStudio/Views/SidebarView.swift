import SwiftUI

public struct SidebarView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    @ObservedObject var device = DeviceManager.shared
    
    @State private var isImporting = false
    @State private var showingRenameAlert = false
    @State private var renameTargetType: String = "" // "profile" or "log"
    @State private var renameText: String = ""
    @State private var targetProfileToRename: RoastProfile? = nil
    @State private var targetLogToRename: RoastLog? = nil
    
    public var body: some View {
        VStack(spacing: 0) {
            // 列表主体
            List {
                // 1. 设备连接状态
                Section("设备状态") {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(device.state.isConnected ? Color.green : Color.gray.opacity(0.6))
                            .frame(width: 8, height: 8)
                        Text(device.state.description)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 3)
                }
                
                // 2. 烘焙方案 (Profiles)
                Section("烘焙方案") {
                    ForEach(state.profiles) { profile in
                        HStack(spacing: 8) {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundColor(state.selectedProfile.id == profile.id ? .orange : .secondary)
                                .font(.system(size: 13))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.shortName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                                
                                Text("建议烘焙度: \(String(format: "%.1f", profile.recommendedLevel)) 级")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .onTapGesture { state.selectProfile(profile) }
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
                                state.toggleCompareDefault()
                            }) {
                                Label("设为对比图层", systemImage: "square.2.layers.3d")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                withAnimation {
                                    state.deleteProfile(profile)
                                }
                            }) {
                                Label("删除方案", systemImage: "trash")
                            }
                        }
                    }
                }
                
                // 3. 历史烘焙记录 (Logs)
                Section("历史烘焙记录") {
                    if state.logs.isEmpty {
                        Text("暂无历史记录")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(state.logs) { log in
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(state.selectedLog?.id == log.id ? .red : .secondary)
                                    .font(.system(size: 13))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    
                                    Text(log.profileUsed)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                            .onTapGesture { state.selectedLog = log }
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
                                
                                Button(action: {
                                    state.comparisonLog = log
                                }) {
                                    Label("作为对比曲线叠加", systemImage: "square.2.layers.3d")
                                }
                                
                                Button(action: {
                                    // 从本次烘焙提取为新方案
                                    var newP = state.selectedProfile
                                    newP.shortName = "\(log.title) (提取配方)"
                                    newP.roastProfilePoints = log.samples.enumerated().compactMap { (idx, s) in
                                        if idx % 15 == 0 || idx == log.samples.count - 1 {
                                            return ProfilePoint(x: s.time, y: s.beanTemp)
                                        }
                                        return nil
                                    }
                                    state.profiles.append(newP)
                                    state.selectProfile(newP)
                                }) {
                                    Label("提取实测为新方案 (Make Profile)", systemImage: "wand.and.stars")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    withAnimation {
                                        state.deleteLog(log)
                                    }
                                }) {
                                    Label("删除此记录", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            // 支持键盘快捷键 Delete 一键删除当前选中的记录或方案
            .onDeleteCommand {
                if let log = state.selectedLog {
                    withAnimation { state.deleteLog(log) }
                }
            }
            
            Divider()
            
            // 底部操作控制条（按照您的要求：把原先顶部的图案调整到侧边栏底部）
            HStack(spacing: 4) {
                // 新建按钮
                Button(action: {
                    let newP = RoastProfile(shortName: "未命名烘焙方案")
                    state.profiles.append(newP)
                    state.selectProfile(newP)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("新建烘焙方案")
                
                // 导入文件按钮
                Button(action: { isImporting = true }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("打开 / 导入烘焙文件 (.kpro, .klog)")
                
                // 删除按钮
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
                
                // 侧边栏底部统计说明
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
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                state.importFile(from: url)
            }
        }
        // 重命名弹窗
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
}
