import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MenuLocalizer.localizeMainMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            MenuLocalizer.localizeMainMenu()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            MenuLocalizer.localizeMainMenu()
        }
    }
}

@main
struct KaffelogicStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var appState = AppState()
    @StateObject private var l10n = L10n.shared
    
    var body: some Scene {
        WindowGroup {
            MainView(state: appState)
                .frame(minWidth: 900, minHeight: 600)
                .environmentObject(appState)
                .environmentObject(l10n)
                .onAppear {
                    MenuLocalizer.localizeMainMenu()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // MARK: - 【文件】菜单
            CommandGroup(replacing: .newItem) {
                Button("新建烘焙方案") {
                    let newP = RoastProfile(shortName: "未命名烘焙方案")
                    appState.profiles.append(newP)
                    appState.selectProfile(newP)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("打开烘焙文件...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.item]
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.importFile(from: url)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("导出当前方案...") {
                    let content = KaffelogicParser.exportKPro(appState.selectedProfile)
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.init(filenameExtension: "kpro")!]
                    savePanel.nameFieldStringValue = "\(appState.selectedProfile.shortName).kpro"
                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        try? content.write(to: url, atomically: true, encoding: .utf8)
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Divider()
                
                Button("删除选中项") {
                    if let log = appState.selectedLog {
                        appState.deleteLog(log)
                    } else {
                        appState.deleteProfile(appState.selectedProfile)
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
            
            // MARK: - 【显示】菜单
            CommandMenu("显示") {
                Toggle("目标温度曲线", isOn: $appState.showTargetCurve)
                    .keyboardShortcut("1", modifiers: .command)
                Toggle("实测豆温曲线", isOn: $appState.showBeanTempCurve)
                    .keyboardShortcut("2", modifiers: .command)
                Toggle("升温速率曲线 (RoR)", isOn: $appState.showRoRCurve)
                    .keyboardShortcut("3", modifiers: .command)
                Toggle("烘焙阶段色块划分", isOn: $appState.showPhasesOverlay)
                    .keyboardShortcut("4", modifiers: .command)
                
                Divider()
                
                Button(appState.isInspectorPresented ? "隐藏参数检查器" : "显示参数检查器") {
                    appState.isInspectorPresented.toggle()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
            
            // MARK: - 【工具】菜单
            CommandMenu(loc("menu_tools")) {
                Button(action: { appState.toggleCompareDefault() }) {
                    HStack {
                        Text(loc("compare_default"))
                        if appState.isComparingDefault {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(loc("compare_files")) {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.item]
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.compareWithFile(url: url)
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button(loc("clear_compare")) {
                    appState.clearComparison()
                }
                .disabled(appState.comparisonProfile == nil && appState.comparisonLog == nil)
                
                Divider()
                
                Button(loc("transform_profile")) {
                    appState.showTransformDialog = true
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button(loc("merge_profile")) {
                    if let log = appState.selectedLog, log.samples.count > 10 {
                        var newP = appState.selectedProfile
                        newP.shortName = "\(log.title) (提取自实测)"
                        newP.roastProfilePoints = log.samples.enumerated().compactMap { (idx, s) in
                            if idx % 15 == 0 || idx == log.samples.count - 1 {
                                return ProfilePoint(x: s.time, y: s.beanTemp)
                            }
                            return nil
                        }
                        appState.profiles.append(newP)
                        appState.selectProfile(newP)
                    }
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Divider()
                
                Button(loc("area_under_curve")) {
                    appState.showAUCDialog = true
                }
                .keyboardShortcut("u", modifiers: .command)
                
                Button(loc("time_calculator")) {
                    appState.showTimeCalculator = true
                }
                .keyboardShortcut("u", modifiers: [.command, .option])
                
                Divider()
                
                Button(loc("capture_image")) {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.png]
                    savePanel.nameFieldStringValue = "烘焙图表_\(appState.selectedProfile.shortName).png"
                    if savePanel.runModal() == .OK, let _ = savePanel.url {}
                }
                
                Divider()
                
                Button(loc("view_roaster")) {
                    appState.showViewRoaster = true
                }
                
                Button(loc("view_memorystick")) {
                    appState.showViewRoaster = true
                }
                
                Divider()
                
                Button(loc("open_sync_folder")) {
                    appState.openSyncFolder()
                }
                
                Button(loc("open_backup_folder")) {
                    appState.openBackupFolder()
                }
                
                Menu(loc("connection_tools")) {
                    Button("自动检测并连接 USB 烘焙机...") {
                        DeviceManager.shared.scanManually()
                    }
                    Button("扫描局域网 WiFi 烘焙机...") {
                        DeviceManager.shared.state = .connectedWiFi(ip: "192.168.1.108")
                    }
                }
            }
            
            // MARK: - 【选项】菜单
            CommandMenu(loc("menu_options")) {
                Menu(loc("difficulty")) {
                    ForEach(DifficultyLevel.allCases) { diff in
                        Button(action: { appState.difficulty = diff }) {
                            HStack {
                                Text(diff.localizedName)
                                if appState.difficulty == diff {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Button(loc("general_options")) {
                    appState.showGeneralOptions = true
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button(loc("compare_options")) {
                    appState.showCompareOptions = true
                }
                
                Divider()
                
                Menu(loc("language_choice")) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button(action: { l10n.language = lang }) {
                            HStack {
                                Text(lang.displayName)
                                if l10n.language == lang {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            
            // MARK: - 【帮助】菜单
            CommandGroup(replacing: .help) {
                Button(loc("tips")) {
                    appState.showAUCDialog = true
                }
                
                Button(loc("user_manual")) {
                    if let url = URL(string: "https://kaffelogic.com/manuals") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button(loc("community_forum")) {
                    if let url = URL(string: "https://kaffelogic.com/community") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Divider()
                
                Button(loc("about_studio")) {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
        }
    }
}
