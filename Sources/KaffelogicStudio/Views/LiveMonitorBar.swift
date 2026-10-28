import SwiftUI

public struct LiveMonitorBar: View {
    @ObservedObject var state: AppState
    @ObservedObject var device = DeviceManager.shared
    
    public var body: some View {
        HStack(spacing: 12) {
            // 左侧监控指标（支持横向自适应排布，防止挤压折行）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    MetricBadge(
                        title: loc("chart_actual_temp"),
                        value: String(format: "%.1f", device.currentBeanTemp),
                        unit: state.tempUnit.rawValue,
                        icon: "thermometer.medium",
                        tint: .red
                    )
                    
                    MetricBadge(
                        title: loc("chart_ror"),
                        value: String(format: "%.1f", device.currentRoR),
                        unit: "°C/分",
                        icon: "chart.line.uptrend.xyaxis",
                        tint: .blue
                    )
                    
                    MetricBadge(
                        title: loc("chart_power"),
                        value: String(format: "%.2f", device.currentPower),
                        unit: "kW",
                        icon: "bolt.fill",
                        tint: .orange
                    )
                    
                    MetricBadge(
                        title: loc("chart_fan"),
                        value: String(format: "%d", Int(device.currentFanRPM)),
                        unit: "RPM",
                        icon: "fanblades.fill",
                        tint: .teal
                    )
                }
                .padding(.vertical, 2)
            }
            
            Spacer(minLength: 8)
            
            // 右侧操作控制按钮组（防止文字被截断为“启...”）
            HStack(spacing: 8) {
                if !device.isRoasting {
                    Button(action: { device.startSimulation(with: state.selectedProfile) }) {
                        Label(loc("btn_simulate"), systemImage: "play.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .fixedSize()
                } else {
                    Button(action: { device.stop() }) {
                        Label(loc("btn_stop_simulate"), systemImage: "stop.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .fixedSize()
                    
                    Button(action: {}) {
                        Label(loc("btn_mark_fc"), systemImage: "flag.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .fixedSize()
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Material.bar)
        .overlay(Divider(), alignment: .top)
    }
}
