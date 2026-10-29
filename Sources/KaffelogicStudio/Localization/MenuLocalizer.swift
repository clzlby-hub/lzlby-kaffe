import AppKit

public class MenuLocalizer {
    // Full translation table — both exact titles and substrings
    private static let translations: [String: String] = [
        // App menu
        "About Kaffelogic Studio": "关于 Kaffelogic Studio",
        "Services": "服务",
        "Hide Kaffelogic Studio": "隐藏 Kaffelogic Studio",
        "Hide Others": "隐藏其他",
        "Show All": "全部显示",
        "Quit Kaffelogic Studio": "退出 Kaffelogic Studio",
        // Standard menus
        "File": "文件",
        "Edit": "编辑",
        "View": "视图",
        "Window": "窗口",
        "Help": "帮助",
        // File menu items
        "New": "新建",
        "Open...": "打开...",
        "Open Recent": "最近打开",
        "Close Window": "关闭窗口",
        "Close": "关闭",
        "Save": "存储",
        "Save...": "存储...",
        "Duplicate": "拷贝副本",
        "Rename...": "重命名...",
        "Move To...": "移至...",
        "Revert to Saved": "还原到已存储",
        "Export...": "导出...",
        "Print...": "打印...",
        // Edit menu items
        "Undo": "撤销",
        "Redo": "重做",
        "Cut": "剪切",
        "Copy": "拷贝",
        "Paste": "粘贴",
        "Paste and Match Style": "粘贴并匹配样式",
        "Delete": "删除",
        "Select All": "全选",
        "Find": "查找",
        "Spelling and Grammar": "拼写和语法",
        "Substitutions": "替换",
        "Transformations": "变换",
        "Speech": "朗读",
        // View menu items
        "Show Toolbar": "显示工具栏",
        "Customize Toolbar...": "自定工具栏...",
        "Show Sidebar": "显示侧边栏",
        "Enter Full Screen": "进入全屏幕",
        "Exit Full Screen": "退出全屏幕",
        // Window menu items
        "Minimize": "最小化",
        "Zoom": "缩放",
        "Bring All to Front": "前置所有窗口",
        "Move Window to Left Side of Screen": "将窗口移到屏幕左侧",
        "Move Window to Right Side of Screen": "将窗口移到屏幕右侧",
        // Preferences
        "Preferences...": "偏好设置...",
        "Settings...": "设置...",
    ]

    public static func localizeMainMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        localize(menu: mainMenu)
    }

    private static func localize(menu: NSMenu) {
        for item in menu.items {
            let title = item.title.trimmingCharacters(in: .whitespaces)
            if let localized = translations[title] {
                item.title = localized
            } else {
                // Try substring match for dynamic items
                for (en, zh) in translations {
                    if title == en || title.hasPrefix(en + " ") {
                        item.title = title.replacingOccurrences(of: en, with: zh)
                        break
                    }
                }
            }
            if let submenu = item.submenu {
                let subTitle = submenu.title.trimmingCharacters(in: .whitespaces)
                if let localizedSub = translations[subTitle] {
                    submenu.title = localizedSub
                }
                localize(menu: submenu)
            }
        }
    }
}
