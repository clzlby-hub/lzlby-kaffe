import SwiftUI

public struct InspectorView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    @State private var showingExportAlert = false
    @State private var exportedPath = ""
    
    public var body: some View {
        Form {
            Section(loc("profile_info")) {
                TextField(loc("profile_name"), text: $state.selectedProfile.shortName)
                TextField(loc("designer"), text: $state.selectedProfile.designer)
                TextField(loc("description"), text: $state.selectedProfile.description, axis: .vertical)
                    .lineLimit(2...4)
            }
            
            Section(loc("roast_level")) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(format: "%.1f 级", state.selectedProfile.recommendedLevel))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Spacer()
                        Text(levelDescription(state.selectedProfile.recommendedLevel))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $state.selectedProfile.recommendedLevel, in: 1.0...5.9, step: 0.1)
                        .tint(.orange)
                }
            }
            
            Section(loc("expect_fc")) {
                HStack {
                    Text(loc("expect_fc"))
                    Spacer()
                    TextField("", value: $state.selectedProfile.expectFirstCrack, format: .number)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                    Text("°C").foregroundColor(.secondary)
                }
                HStack {
                    Text(loc("reference_load"))
                    Spacer()
                    TextField("", value: $state.selectedProfile.referenceLoadSize, format: .number)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                    Text("克 (g)").foregroundColor(.secondary)
                }
            }
            
            if state.difficulty != .basic {
                Section(loc("preheat_settings")) {
                    HStack {
                        Text(loc("chart_power"))
                        Spacer()
                        TextField("", value: $state.selectedProfile.preheatPower, format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                        Text("瓦 (W)").foregroundColor(.secondary)
                    }
                    HStack {
                        Text(loc("temp_unit"))
                        Spacer()
                        TextField("", value: $state.selectedProfile.preheatNominalTemp, format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                        Text("°C").foregroundColor(.secondary)
                    }
                }
            }
            
            if state.difficulty == .expert || state.difficulty == .engineer {
                Section(loc("pid_settings")) {
                    HStack {
                        Text("比例增益 (Kp)")
                        Spacer()
                        TextField("", value: $state.selectedProfile.pidKp, format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("积分增益 (Ki)")
                        Spacer()
                        TextField("", value: $state.selectedProfile.pidKi, format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("微分增益 (Kd)")
                        Spacer()
                        TextField("", value: $state.selectedProfile.pidKd, format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                    }
                }
            }
            
            Section {
                Button(action: exportCurrentProfile) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                        Text(loc("export_file")).fontWeight(.medium)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(loc("inspector_title"))
        .alert(isPresented: $showingExportAlert) {
            Alert(title: Text(loc("save")), message: Text("已成功导出为 Kaffelogic 格式:\n\(exportedPath)"), dismissButton: .default(Text("好的")))
        }
    }
    
    private func levelDescription(_ l: Double) -> String {
        if l < 2.5 { return "极浅烘焙 (浅肉桂色)" }
        if l < 3.2 { return "浅中度烘焙 (城市烘焙)" }
        if l < 4.0 { return "中度烘焙 (深城市烘焙)" }
        if l < 4.8 { return "中深度烘焙 (维也纳/意式)" }
        return "深度烘焙 (法式烘焙)"
    }
    
    private func exportCurrentProfile() {
        let content = KaffelogicParser.exportKPro(state.selectedProfile)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "kpro")!]
        savePanel.nameFieldStringValue = "\(state.selectedProfile.shortName).kpro"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
            exportedPath = url.lastPathComponent
            showingExportAlert = true
        }
    }
}
