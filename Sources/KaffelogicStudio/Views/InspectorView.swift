import SwiftUI

public struct InspectorView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    @State private var showingExportAlert = false
    @State private var exportedPath = ""
    
    public var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $state.inspectorTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            if state.inspectorTab == .profile {
                profileInspectorForm
            } else {
                logInspectorForm
            }
        }
        .navigationTitle(loc("inspector_title"))
        .alert(isPresented: $showingExportAlert) {
            Alert(
                title: Text(loc("save")),
                message: Text("已成功导出:\n\(exportedPath)"),
                dismissButton: .default(Text("好的"))
            )
        }
    }
    
    // MARK: - 方案参数表单（所有修改同步回写并自动保存）
    private var profileInspectorForm: some View {
        Form {
            if let selIdx = state.selectedPointIndex,
               state.chartEditMode != .view {
                selectedNodeSection(index: selIdx)
            }
            
            Section(loc("profile_info")) {
                TextField(loc("profile_name"), text: profileBinding(\.shortName))
                TextField(loc("designer"), text: profileBinding(\.designer))
                TextField(loc("description"), text: profileBinding(\.description), axis: .vertical)
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
                    Slider(value: profileBinding(\.recommendedLevel), in: 1.0...5.9, step: 0.1)
                        .tint(.orange)
                }
            }
            
            Section(loc("expect_fc")) {
                HStack {
                    Text(loc("expect_fc"))
                    Spacer()
                    TextField("", value: Binding(
                        get: { state.displayTemp(state.selectedProfile.expectFirstCrack) },
                        set: { newVal in
                            let c = state.celsiusFromDisplay(newVal)
                            state.updateSelectedProfile { $0.expectFirstCrack = c }
                        }
                    ), format: .number.precision(.fractionLength(1)))
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                    Text(state.tempUnit.rawValue).foregroundColor(.secondary)
                }
                HStack {
                    Text(loc("reference_load"))
                    Spacer()
                    TextField("", value: profileBinding(\.referenceLoadSize), format: .number)
                        .frame(width: 70)
                        .multilineTextAlignment(.trailing)
                    Text("g").foregroundColor(.secondary)
                }
            }
            
            if state.difficulty != .basic {
                Section(loc("preheat_settings")) {
                    HStack {
                        Text(loc("chart_power"))
                        Spacer()
                        TextField("", value: profileBinding(\.preheatPower), format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                        Text("W").foregroundColor(.secondary)
                    }
                    HStack {
                        Text(loc("temp_unit"))
                        Spacer()
                        TextField("", value: Binding(
                            get: { state.displayTemp(state.selectedProfile.preheatNominalTemp) },
                            set: { newVal in
                                let c = state.celsiusFromDisplay(newVal)
                                state.updateSelectedProfile { $0.preheatNominalTemp = c }
                            }
                        ), format: .number.precision(.fractionLength(1)))
                            .frame(width: 70).multilineTextAlignment(.trailing)
                        Text(state.tempUnit.rawValue).foregroundColor(.secondary)
                    }
                }
            }
            
            if state.difficulty == .expert || state.difficulty == .engineer {
                Section(loc("pid_settings")) {
                    HStack {
                        Text("比例增益 (Kp)")
                        Spacer()
                        TextField("", value: profileBinding(\.pidKp), format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("积分增益 (Ki)")
                        Spacer()
                        TextField("", value: profileBinding(\.pidKi), format: .number)
                            .frame(width: 70).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("微分增益 (Kd)")
                        Spacer()
                        TextField("", value: profileBinding(\.pidKd), format: .number)
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
    }
    
    // MARK: - 选中节点微调区
    @ViewBuilder
    private func selectedNodeSection(index: Int) -> some View {
        let isFan = state.chartEditMode == .editFanSpeed
        let arr = isFan ? state.selectedProfile.fanProfilePoints : state.selectedProfile.roastProfilePoints
        if index < arr.count {
            let pt = arr[index]
            Section("选中节点 #\(index + 1) (\(isFan ? "风扇" : "目标温"))") {
                HStack {
                    Text("时间 (秒)")
                    Spacer()
                    TextField("", value: Binding(
                        get: { pt.x },
                        set: { newX in
                            state.pushUndoSnapshot()
                            state.updateSelectedProfile { p in
                                var list = isFan ? p.fanProfilePoints : p.roastProfilePoints
                                guard index < list.count else { return }
                                let minX = index == 0 ? 0.0 : list[index - 1].x + 5.0
                                let maxX = index == list.count - 1 ? 900.0 : list[index + 1].x - 5.0
                                list[index].x = index == 0 ? 0.0 : max(minX, min(maxX, newX))
                                if isFan { p.fanProfilePoints = list } else { p.roastProfilePoints = list }
                            }
                        }
                    ), format: .number.precision(.fractionLength(0)))
                    .frame(width: 70)
                    .multilineTextAlignment(.trailing)
                    Text("s").foregroundColor(.secondary)
                }
                
                HStack {
                    Text(isFan ? "转速 (RPM)" : "温度 (\(state.tempUnit.rawValue))")
                    Spacer()
                    TextField("", value: Binding(
                        get: { isFan ? pt.y : state.displayTemp(pt.y) },
                        set: { newVal in
                            state.pushUndoSnapshot()
                            state.updateSelectedProfile { p in
                                var list = isFan ? p.fanProfilePoints : p.roastProfilePoints
                                guard index < list.count else { return }
                                list[index].y = isFan ? max(4000, min(18000, newVal)) : max(20, min(250, state.celsiusFromDisplay(newVal)))
                                if isFan { p.fanProfilePoints = list } else { p.roastProfilePoints = list }
                            }
                        }
                    ), format: .number.precision(.fractionLength(1)))
                    .frame(width: 70)
                    .multilineTextAlignment(.trailing)
                    Text(isFan ? "RPM" : state.tempUnit.rawValue).foregroundColor(.secondary)
                }
                
                if arr.count > 2 {
                    Button(role: .destructive) {
                        state.pushUndoSnapshot()
                        state.updateSelectedProfile { p in
                            if isFan, index < p.fanProfilePoints.count {
                                p.fanProfilePoints.remove(at: index)
                            } else if !isFan, index < p.roastProfilePoints.count {
                                p.roastProfilePoints.remove(at: index)
                            }
                        }
                        state.selectedPointIndex = nil
                    } label: {
                        Label("删除此节点", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - 烘焙记录与杯测表单
    private var logInspectorForm: some View {
        Group {
            if let log = state.selectedLog {
                Form {
                    Section("批次信息") {
                        TextField("记录标题", text: logBinding(\.title))
                        TextField("生豆产区 / 处理法", text: logBinding(\.beanOrigin))
                        HStack {
                            Text("使用方案")
                            Spacer()
                            Text(log.profileUsed).foregroundColor(.secondary)
                        }
                    }
                    
                    Section("豆重与失水率") {
                        HStack {
                            Text("生豆重量")
                            Spacer()
                            TextField("120", value: Binding(
                                get: { log.greenWeight ?? 0 },
                                set: { v in state.updateSelectedLog { $0.greenWeight = v > 0 ? v : nil } }
                            ), format: .number.precision(.fractionLength(1)))
                            .frame(width: 70).multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.secondary)
                        }
                        HStack {
                            Text("熟豆重量")
                            Spacer()
                            TextField("102", value: Binding(
                                get: { log.roastedWeight ?? 0 },
                                set: { v in state.updateSelectedLog { $0.roastedWeight = v > 0 ? v : nil } }
                            ), format: .number.precision(.fractionLength(1)))
                            .frame(width: 70).multilineTextAlignment(.trailing)
                            Text("g").foregroundColor(.secondary)
                        }
                        if let loss = log.weightLossPercent {
                            HStack {
                                Text("失水率")
                                Spacer()
                                Text(String(format: "%.2f%%", loss))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Section("关键事件") {
                        if let fcT = log.firstCrackTime {
                            HStack {
                                Text("一爆时间")
                                Spacer()
                                Text("\(Int(fcT)/60):\(String(format: "%02d", Int(fcT)%60))")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        if let fcTemp = log.firstCrackTemp {
                            HStack {
                                Text("一爆豆温")
                                Spacer()
                                Text(state.formatTemp(fcTemp))
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        if let dropT = log.dropTime {
                            HStack {
                                Text("下豆总时长")
                                Spacer()
                                Text("\(Int(dropT)/60):\(String(format: "%02d", Int(dropT)%60))")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    
                    Section("杯测与风味笔记") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("杯测评分")
                                Spacer()
                                Text(String(format: "%.1f 分", log.cuppingScore ?? 85.0))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                            Slider(value: Binding(
                                get: { log.cuppingScore ?? 85.0 },
                                set: { v in state.updateSelectedLog { $0.cuppingScore = v } }
                            ), in: 60...100, step: 0.5)
                            .tint(.orange)
                        }
                        TextField("风味笔记（花香、柑橘、焦糖甜感...）", text: logBinding(\.tastingNotes), axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section {
                        Button(action: { exportCurrentLog(log) }) {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text("导出记录 (.klog)")
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .formStyle(.grouped)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("请在左侧选择一条烘焙记录")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func profileBinding<V>(_ keyPath: WritableKeyPath<RoastProfile, V>) -> Binding<V> {
        Binding(
            get: { state.selectedProfile[keyPath: keyPath] },
            set: { newValue in
                state.updateSelectedProfile { $0[keyPath: keyPath] = newValue }
            }
        )
    }
    
    private func logBinding(_ keyPath: WritableKeyPath<RoastLog, String>) -> Binding<String> {
        Binding(
            get: { state.selectedLog?[keyPath: keyPath] ?? "" },
            set: { newValue in
                state.updateSelectedLog { $0[keyPath: keyPath] = newValue }
            }
        )
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
    
    private func exportCurrentLog(_ log: RoastLog) {
        let content = KaffelogicParser.exportKLog(log)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "klog")!]
        savePanel.nameFieldStringValue = "\(log.title).klog"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
            exportedPath = url.lastPathComponent
            showingExportAlert = true
        }
    }
}
