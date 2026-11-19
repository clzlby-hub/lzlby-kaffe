import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(state: state)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            VStack(spacing: 0) {
                PhaseSummaryView(summary: state.cachedPhaseSummary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                
                legendStrip
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                
                RoastChartView(state: state)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                LiveMonitorBar(state: state)
            }
            .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(state.selectedProfile.shortName)
            .navigationSubtitle(loc("subtitle"))
        }
        .inspector(isPresented: $state.isInspectorPresented) {
            InspectorView(state: state)
                .inspectorColumnWidth(min: 270, ideal: 300, max: 400)
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
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Picker("编辑模式", selection: $state.chartEditMode) {
                    ForEach(ChartEditMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
                .onChange(of: state.chartEditMode) { _, _ in
                    state.selectedPointIndex = nil
                }
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { state.undo() }) {
                    Label("撤销", systemImage: "arrow.uturn.backward")
                }
                .disabled(!state.canUndo)
                .help("撤销曲线修改 (⌘Z)")
                
                Button(action: { state.redo() }) {
                    Label("重做", systemImage: "arrow.uturn.forward")
                }
                .disabled(!state.canRedo)
                .help("重做曲线修改 (⇧⌘Z)")
                
                Button(action: {
                    state.chartZoomScale = max(1.0, state.chartZoomScale - 0.5)
                    if state.chartZoomScale == 1.0 { state.chartTimeOffset = 0 }
                }) {
                    Label("缩小", systemImage: "minus.magnifyingglass")
                }
                .disabled(state.chartZoomScale <= 1.0)
                .help("缩小时间轴")
                
                Button(action: {
                    state.chartZoomScale = min(4.0, state.chartZoomScale + 0.5)
                }) {
                    Label("放大", systemImage: "plus.magnifyingglass")
                }
                .disabled(state.chartZoomScale >= 4.0)
                .help("放大时间轴")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    state.isInspectorPresented.toggle()
                }) {
                    Label(loc("inspector_title"), systemImage: "sidebar.right")
                }
                .help("显示/隐藏检查器 (⌥⌘I)")
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
    
    // MARK: - 极简图例切换条
    private var legendStrip: some View {
        HStack(spacing: 6) {
            layerPill("目标温", color: .orange, isOn: $state.showTargetCurve)
            layerPill("实测温", color: .red, isOn: $state.showBeanTempCurve)
            layerPill("RoR", color: .blue, isOn: $state.showRoRCurve)
            layerPill("风扇", color: .teal, isOn: $state.showFanCurve)
            layerPill("功率", color: .yellow, isOn: $state.showPowerCurve)
            layerPill("阶段", color: .brown, isOn: $state.showPhasesOverlay)
            
            Spacer()
            
            if state.chartEditMode != .view {
                Text("拖拽节点/手柄 · 双击加点 · ⌫删点")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private func layerPill(_ title: String, color: Color, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isOn.wrappedValue ? color : Color.gray.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(size: 11, weight: isOn.wrappedValue ? .semibold : .regular))
                    .foregroundStyle(isOn.wrappedValue ? .primary : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isOn.wrappedValue ? color.opacity(0.14) : Color.primary.opacity(0.04))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
