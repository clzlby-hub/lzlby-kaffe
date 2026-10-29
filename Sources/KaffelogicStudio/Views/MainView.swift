import SwiftUI

public struct MainView: View {
    @ObservedObject var state: AppState
    @ObservedObject var l10n = L10n.shared
    
    public var body: some View {
        HSplitView {
            // 1. 左侧边栏 (可使用鼠标按住分割线随意左右拖动调节宽度！)
            SidebarView(state: state)
                .frame(minWidth: 190, idealWidth: 260, maxWidth: 480)
                .layoutPriority(0)
            
            // 2. 中间主图表与监控区域
            VStack(spacing: 0) {
                let evaluated = BezierMath.evaluateCurve(points: state.selectedProfile.roastProfilePoints)
                let phases = ROREngine.computePhases(curve: evaluated, expectFC: state.selectedProfile.expectFirstCrack)
                PhaseSummaryView(summary: phases)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                
                RoastChartView(state: state)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                LiveMonitorBar(state: state)
            }
            .frame(minWidth: 520, maxWidth: .infinity)
            .layoutPriority(1)
            
            // 3. 右侧烘焙参数检查器 (展开时同样支持鼠标拖动调整宽度)
            if state.isInspectorPresented {
                InspectorView(state: state)
                    .frame(minWidth: 260, idealWidth: 290, maxWidth: 420)
                    .layoutPriority(0)
            }
        }
        .navigationTitle(state.selectedProfile.shortName)
        .navigationSubtitle(loc("subtitle"))
        .toolbar {
            // 图层可见性切换（多选 Toggle，激活时有对应主题色）
            ToolbarItemGroup(placement: .automatic) {
                Toggle(isOn: $state.showTargetCurve) {
                    Label(loc("chart_temperature"), systemImage: "waveform.path")
                        .foregroundStyle(state.showTargetCurve ? Color.orange : Color.primary)
                }
                .help(loc("chart_temperature"))
                .tint(.orange)
                
                Toggle(isOn: $state.showBeanTempCurve) {
                    Label(loc("chart_actual_temp"), systemImage: "thermometer.medium")
                        .foregroundStyle(state.showBeanTempCurve ? Color.red : Color.primary)
                }
                .help(loc("chart_actual_temp"))
                .tint(.red)
                
                Toggle(isOn: $state.showRoRCurve) {
                    Label(loc("chart_ror"), systemImage: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(state.showRoRCurve ? Color.blue : Color.primary)
                }
                .help(loc("chart_ror"))
                .tint(.blue)
                
                Toggle(isOn: $state.showPhasesOverlay) {
                    Label(loc("phase_ratio"), systemImage: "square.3.layers.3d.down.right")
                        .foregroundStyle(state.showPhasesOverlay ? Color.brown : Color.primary)
                }
                .help(loc("phase_ratio"))
                .tint(.brown)
            }
            
            // 参数检查器开关（单独剥离到最右侧）
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
}
