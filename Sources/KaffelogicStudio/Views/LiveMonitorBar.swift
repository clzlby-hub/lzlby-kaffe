import SwiftUI

public struct LiveMonitorBar: View {
    @ObservedObject var state: AppState
    @ObservedObject var device = DeviceManager.shared
    
    private var elapsedFormatted: String {
        let total = Int(device.elapsedTime)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if device.isRoasting {
                        MetricBadge(
                            title: loc("time_sec"),
                            value: elapsedFormatted,
                            unit: "",
                            icon: "timer",
                            tint: .purple
                        )
                    }
                    
                    MetricBadge(
                        title: loc("chart_actual_temp"),
                        value: String(format: "%.1f", state.displayTemp(device.currentBeanTemp)),
                        unit: state.tempUnit.rawValue,
                        icon: "thermometer.medium",
                        tint: .red
                    )
                    
                    MetricBadge(
                        title: loc("chart_ror"),
                        value: String(format: "%.1f", state.tempUnit == .celsius ? device.currentRoR : device.currentRoR * 9.0 / 5.0),
                        unit: "\(state.tempUnit.rawValue)/分",
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
                    Button(action: { device.markFirstCrack() }) {
                        if let fc = device.firstCrackTime {
                            Label("一爆 \(Int(fc)/60):\(String(format: "%02d", Int(fc)%60))", systemImage: "flag.checkered")
                        } else {
                            Label(loc("btn_mark_fc"), systemImage: "flag.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(device.firstCrackTime != nil)
                    .fixedSize()
                    
                    Button(action: { device.stop(saveLog: true) }) {
                        Label(loc("btn_stop_simulate"), systemImage: "stop.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
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
