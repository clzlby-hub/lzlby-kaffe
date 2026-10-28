import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case zh = "zh"
    case en = "en"
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .zh: return "简体中文"
        case .en: return "English"
        }
    }
}

public class L10n: ObservableObject {
    public static let shared = L10n()
    
    @AppStorage("selected_app_language") public var currentLanguage: String = "zh" {
        willSet { objectWillChange.send() }
    }
    
    public var language: AppLanguage {
        get { AppLanguage(rawValue: currentLanguage) ?? .zh }
        set { currentLanguage = newValue.rawValue }
    }
    
    public func tr(_ key: String) -> String {
        let isZh = (language == .zh)
        if let dict = strings[key] {
            return isZh ? dict.zh : dict.en
        }
        return key
    }
    
    private struct LocPair {
        let zh: String
        let en: String
    }
    
    private let strings: [String: LocPair] = [
        "app_title": LocPair(zh: "Kaffelogic Studio", en: "Kaffelogic Studio"),
        "subtitle": LocPair(zh: "专业咖啡烘焙工作室", en: "Professional Coffee Roasting Studio"),
        "menu_tools": LocPair(zh: "工具", en: "Tools"),
        "menu_options": LocPair(zh: "选项", en: "Options"),
        "menu_view": LocPair(zh: "显示", en: "View"),
        "menu_help": LocPair(zh: "帮助", en: "Help"),
        
        // 工具菜单
        "compare_default": LocPair(zh: "对比默认曲线", en: "Compare Default"),
        "compare_files": LocPair(zh: "对比文件...", en: "Compare Files..."),
        "clear_compare": LocPair(zh: "清除对比", en: "Clear Comparison"),
        "transform_profile": LocPair(zh: "转换曲线配置...", en: "Transform Profile..."),
        "merge_profile": LocPair(zh: "合并曲线 (从烘焙提取)...", en: "Merge Profile..."),
        "area_under_curve": LocPair(zh: "曲线下面积 (AUC)...", en: "Area Under Curve..."),
        "time_calculator": LocPair(zh: "时间计算器...", en: "Time Calculator..."),
        "capture_image": LocPair(zh: "捕获并保存图像...", en: "Capture and Save Image..."),
        "view_roaster": LocPair(zh: "查看烘焙机...", en: "View Roaster..."),
        "view_memorystick": LocPair(zh: "查看记忆棒 (U盘)...", en: "View Memory Stick..."),
        "open_sync_folder": LocPair(zh: "打开烘焙机同步文件夹...", en: "Open Roaster Sync Folder..."),
        "open_backup_folder": LocPair(zh: "打开记忆棒备份文件夹...", en: "Open Memory Stick Backup Folder..."),
        "connection_tools": LocPair(zh: "连接工具", en: "Connection Tools"),
        
        // 选项菜单
        "difficulty": LocPair(zh: "难度等级", en: "Difficulty"),
        "diff_basic": LocPair(zh: "基础模式", en: "Basic"),
        "diff_advanced": LocPair(zh: "进阶模式", en: "Advanced"),
        "diff_expert": LocPair(zh: "专家模式", en: "Expert"),
        "diff_engineer": LocPair(zh: "工程师模式", en: "Engineer"),
        "general_options": LocPair(zh: "常规选项...", en: "General Options..."),
        "compare_options": LocPair(zh: "对比选项...", en: "Compare Options..."),
        "language_choice": LocPair(zh: "语言 (Language)...", en: "Language..."),
        
        // 帮助菜单
        "tips": LocPair(zh: "烘焙提示与技巧...", en: "Tips and Hints..."),
        "troubleshooters": LocPair(zh: "故障排除工具", en: "Troubleshooters"),
        "user_manual": LocPair(zh: "官方烘焙手册", en: "User Manual"),
        "community_forum": LocPair(zh: "用户社区论坛", en: "Community Forum"),
        "about_studio": LocPair(zh: "关于 Kaffelogic Studio", en: "About Kaffelogic Studio"),
        
        // AUC 对话框
        "auc_title": LocPair(zh: "曲线下面积 (AUC - 累积热能计算)", en: "Area Under Curve (AUC)"),
        "auc_base_time": LocPair(zh: "基准起始时间", en: "Base Time"),
        "auc_end_time": LocPair(zh: "结束时间", en: "End Time"),
        "auc_base_temp": LocPair(zh: "基准起始温度", en: "Base Temp"),
        "auc_result": LocPair(zh: "AUC 累积热能积分值", en: "AUC Value"),
        "auc_from_curve": LocPair(zh: "从曲线自动获取基准范围", en: "From Curve Baseline"),
        
        // 时间计算器
        "calc_title": LocPair(zh: "烘焙时间与阶段计算器", en: "Roast Time Calculator"),
        "calc_target_time": LocPair(zh: "目标总烘焙时长", en: "Target Roast Time"),
        "calc_dry_ratio": LocPair(zh: "脱水期占比", en: "Drying Ratio"),
        "calc_maillard_ratio": LocPair(zh: "梅纳德占比", en: "Maillard Ratio"),
        "calc_dev_ratio": LocPair(zh: "发展期占比 (DTR)", en: "Development Ratio (DTR)"),
        "calc_apply": LocPair(zh: "应用到当前方案", en: "Apply to Profile"),
        
        // 转换配置
        "trans_title": LocPair(zh: "曲线线性变换与拉伸", en: "Transform Curve"),
        "trans_time_factor": LocPair(zh: "时间缩放系数", en: "Time Multiplier"),
        "trans_time_offset": LocPair(zh: "时间平移偏置", en: "Time Offset"),
        "trans_temp_factor": LocPair(zh: "温度缩放系数", en: "Temp Multiplier"),
        "trans_temp_offset": LocPair(zh: "温度平移偏置", en: "Temp Offset"),
        "apply": LocPair(zh: "应用", en: "Apply"),
        "close": LocPair(zh: "关闭", en: "Close"),
        
        // 侧边栏
        "sidebar_profiles": LocPair(zh: "烘焙曲线方案", en: "Roast Profiles"),
        "sidebar_logs": LocPair(zh: "历史烘焙记录", en: "Roast Logs"),
        "sidebar_device": LocPair(zh: "设备连接状态", en: "Device Management"),
        "import_file": LocPair(zh: "打开文件...", en: "Open File..."),
        "export_file": LocPair(zh: "导出方案...", en: "Export Profile..."),
        "new_profile": LocPair(zh: "新建方案", en: "New Profile"),
        
        // 阶段
        "phase_drying": LocPair(zh: "脱水阶段", en: "Drying Phase"),
        "phase_maillard": LocPair(zh: "梅纳德反应", en: "Maillard Phase"),
        "phase_first_crack": LocPair(zh: "第一爆", en: "First Crack"),
        "phase_development": LocPair(zh: "发展阶段", en: "Development Phase"),
        "phase_ratio": LocPair(zh: "发展比率 (DTR)", en: "Development Ratio (DTR)"),
        
        // 图表指标
        "chart_temperature": LocPair(zh: "目标温度", en: "Target Temp"),
        "chart_actual_temp": LocPair(zh: "实测豆温", en: "Bean Temp"),
        "chart_chamber_temp": LocPair(zh: "风温内胆", en: "Chamber Temp"),
        "chart_ror": LocPair(zh: "升温速率", en: "Rate of Rise (RoR)"),
        "chart_fan": LocPair(zh: "风扇转速", en: "Fan Speed"),
        "chart_power": LocPair(zh: "加热功率", en: "Heater Power"),
        "time_sec": LocPair(zh: "时间", en: "Time"),
        "temp_unit": LocPair(zh: "温度", en: "Temperature"),
        
        // 检查器
        "inspector_title": LocPair(zh: "烘焙参数检查器", en: "Roast Inspector"),
        "profile_info": LocPair(zh: "方案基本信息", en: "Profile Details"),
        "profile_name": LocPair(zh: "曲线名称", en: "Profile Name"),
        "designer": LocPair(zh: "设计者", en: "Designer"),
        "description": LocPair(zh: "风味描述与备注", en: "Description"),
        "roast_level": LocPair(zh: "建议烘焙度", en: "Roast Level"),
        "expect_fc": LocPair(zh: "预估一爆温度", en: "Expected First Crack"),
        "reference_load": LocPair(zh: "标准烘焙豆量", en: "Reference Batch Size"),
        "pid_settings": LocPair(zh: "PID 调校参数", en: "PID Controller"),
        "preheat_settings": LocPair(zh: "预热与功率配置", en: "Preheat & Power"),
        
        // 设备状态
        "device_status": LocPair(zh: "设备状态", en: "Device Status"),
        "device_disconnected": LocPair(zh: "未连接机器", en: "Disconnected"),
        "device_connected_usb": LocPair(zh: "USB-C 串口已连接", en: "Connected via USB-C"),
        "device_connected_wifi": LocPair(zh: "局域网 WiFi 已连接", en: "Connected via WiFi"),
        "device_simulated": LocPair(zh: "烘焙模拟进行中", en: "Simulation Active"),
        "btn_start_roast": LocPair(zh: "开始烘焙", en: "Start Roast"),
        "btn_stop_roast": LocPair(zh: "下豆结束", en: "Finish & Drop"),
        "btn_mark_fc": LocPair(zh: "标记一爆", en: "Mark First Crack"),
        "btn_simulate": LocPair(zh: "模拟烘焙", en: "Simulate Roast"),
        "btn_stop_simulate": LocPair(zh: "停止模拟", en: "Stop Simulation"),
        
        // 通用
        "save": LocPair(zh: "保存", en: "Save"),
        "cancel": LocPair(zh: "取消", en: "Cancel"),
        "language_switch": LocPair(zh: "语言", en: "Language")
    ]
}

public func loc(_ key: String) -> String {
    L10n.shared.tr(key)
}
