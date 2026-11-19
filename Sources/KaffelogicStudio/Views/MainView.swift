import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    
    public var body: some View {
        HSplitView {
            SidebarView(state: state)
                .frame(minWidth: 210, idealWidth: 260, maxWidth: 380)
                .layoutPriority(0)
            
            VStack(spacing: 0) {
                PhaseSummaryView(summary: state.cachedPhaseSummary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                
                chartControlBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                
                RoastChartView(state: state)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                LiveMonitorBar(state: state)
            }
            .frame(minWidth: 540, maxWidth: .infinity)
            .layoutPriority(1)
            
            if state.isInspectorPresented {
                InspectorView(state: state)
                    .frame(minWidth: 270, idealWidth: 300, maxWidth: 420)
                    .layoutPriority(0)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    DispatchQueue.main.async {
                        state.importFile(from: url)
                    }
                }
            }
            return true
        }
        .navigationTitle(state.selectedProfile.shortName)
        .navigationSubtitle(loc("subtitle"))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { state.undo() }) {
                    Label("撤销", systemImage: "arrow.uturn.backward")
                }
                .disabled(!state.canUndo)
                .keyboardShortcut("z", modifiers: .command)
                .help("撤销曲线修改 (⌘Z)")
                
                Button(action: { state.redo() }) {
                    Label("重做", systemImage: "arrow.uturn.forward")
                }
                .disabled(!state.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .help("重做曲线修改 (⇧⌘Z)")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.isInspectorPresented.toggle()
                    }
                }) {
                    Label(loc("inspector_title"), systemImage: "sidebar.right")
                }
                .help(loc("inspector_title"))
            }
        }
        .sheet(isPresented: $state.showAUCDialog) {
            AUCDialogView(state: state)
        }
        .sheet(isPresented: $state.showTimeCalculator) {
            TimeCalculatorView(state: state)
        }
        .sheet(isPresented: $state.showTransformDialog) {
            TransformDialogView(state: state)
        }
        .sheet(isPresented: $state.showViewRoaster) {
            RoasterStorageView(state: state)
        }
        .sheet(isPresented: $state.showGeneralOptions) {
            GeneralOptionsView(state: state)
        }
        .sheet(isPresented: $state.showCompareOptions) {
            CompareOptionsView(state: state)
        }
    }
    
    // MARK: - 图表上方专业控制条（编辑模式 + 图层显隐 + 缩放）
    private var chartControlBar: some View {
        HStack(spacing: 10) {
            Picker("", selection: $state.chartEditMode) {
                ForEach(ChartEditMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .onChange(of: state.chartEditMode) { _, _ in
                state.selectedPointIndex = nil
            }
            
            if state.chartEditMode != .view {
                Text("拖拽节点/手柄调曲线 · 双击加点")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                layerPill("目标", color: .orange, isOn: $state.showTargetCurve)
                layerPill("豆温", color: .red, isOn: $state.showBeanTempCurve)
                layerPill("RoR", color: .blue, isOn: $state.showRoRCurve)
                layerPill("风扇", color: .teal, isOn: $state.showFanCurve)
                layerPill("功率", color: .yellow, isOn: $state.showPowerCurve)
                layerPill("阶段", color: .brown, isOn: $state.showPhasesOverlay)
            }
            
            Divider().frame(height: 16)
            
            HStack(spacing: 2) {
                Button(action: {
                    state.chartZoomScale = max(1.0, state.chartZoomScale - 0.5)
                    if state.chartZoomScale == 1.0 { state.chartTimeOffset = 0 }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .disabled(state.chartZoomScale <= 1.0)
                
                Button(action: {
                    state.chartZoomScale = min(4.0, state.chartZoomScale + 0.5)
                }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .disabled(state.chartZoomScale >= 4.0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
    }
    
    private func layerPill(_ title: String, color: Color, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isOn.wrappedValue ? color : Color.gray.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 10.5, weight: isOn.wrappedValue ? .semibold : .regular))
                    .foregroundColor(isOn.wrappedValue ? .primary : .secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(isOn.wrappedValue ? color.opacity(0.14) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
