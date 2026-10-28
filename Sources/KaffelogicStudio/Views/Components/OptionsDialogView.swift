import SwiftUI

public struct GeneralOptionsView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        Form {
            Section("通用外观与单位") {
                Picker("温度单位", selection: $state.tempUnit) {
                    Text("摄氏度 (°C)").tag(TemperatureUnit.celsius)
                    Text("华氏度 (°F)").tag(TemperatureUnit.fahrenheit)
                }
                Picker("显示语言 (Language)", selection: $l10n.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }
            Section("烘焙默认预设") {
                Picker("难度级别 (Difficulty)", selection: $state.difficulty) {
                    ForEach(DifficultyLevel.allCases) { diff in
                        Text(diff.localizedName).tag(diff)
                    }
                }
                HStack {
                    Text("默认批次豆量")
                    Spacer()
                    Text("120 g").foregroundColor(.secondary)
                }
                HStack {
                    Text("适配固件版本")
                    Spacer()
                    Text("v7.21.6 (RP2040)").foregroundColor(.secondary)
                }
            }
            Section {
                Button("完成") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420, height: 350)
    }
}

public struct CompareOptionsView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var alignMode: Int = 0
    
    public var body: some View {
        Form {
            Section("对比曲线对齐方式") {
                Picker("基准时间对齐", selection: $alignMode) {
                    Text("按烘焙起始时间对齐 (Start Time 0s)").tag(0)
                    Text("按第一爆时间对齐 (Align by First Crack)").tag(1)
                    Text("按脱水结束点对齐 (Align by Dry End)").tag(2)
                }
                .pickerStyle(.radioGroup)
            }
            Section {
                Button("确定") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 400, height: 240)
    }
}
