import AppKit

public class MenuLocalizer {
    private static let translations: [String: String] = [
        "About Kaffelogic Studio": "关于 Kaffelogic Studio",
        "Services": "服务",
        "Hide Kaffelogic Studio": "隐藏 Kaffelogic Studio",
        "Hide Others": "隐藏其他",
        "Show All": "全部显示",
        "Quit Kaffelogic Studio": "退出 Kaffelogic Studio",
        "File": "文件",
        "New": "新建",
        "Open...": "打开...",
        "Close": "关闭窗口",
        "Save...": "保存...",
        "Edit": "编辑",
        "Undo": "撤销",
        "Redo": "重做",
        "Cut": "剪切",
        "Copy": "复制",
        "Paste": "粘贴",
        "Select All": "全选",
        "View": "显示",
        "Window": "窗口",
        "Minimize": "最小化",
        "Zoom": "缩放",
        "Bring All to Front": "前置全部窗口",
        "Help": "帮助",
        "Preferences...": "设置...",
        "Settings...": "设置..."
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
                for (en, zh) in translations {
                    if title.contains(en) {
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
