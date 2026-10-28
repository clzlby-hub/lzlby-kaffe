import SwiftUI

public struct TimeCalculatorView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var totalMinutes: Double = 9.0
    @State private var totalSeconds: Double = 30.0
    @State private var dryingRatio: Double = 45.0
    @State private var maillardRatio: Double = 35.0
    @State private var devRatio: Double = 20.0
    
    private var totalTimeInSec: Double { totalMinutes * 60.0 + totalSeconds }
    private var dryingSec: Double { totalTimeInSec * (dryingRatio / 100.0) }
    private var maillardSec: Double { totalTimeInSec * (maillardRatio / 100.0) }
    private var devSec: Double { totalTimeInSec * (devRatio / 100.0) }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(loc("calc_title"))
                    .font(.headline)
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                Text(loc("calc_target_time")).font(.subheadline).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    HStack {
                        TextField("", value: $totalMinutes, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 60)
                        Text("分 (min)")
                    }
                    HStack {
                        TextField("", value: $totalSeconds, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 60)
                        Text("秒 (sec)")
                    }
                    Spacer()
                    Text(String(format: "总计: %d秒", Int(totalTimeInSec)))
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Divider()
            VStack(spacing: 10) {
                ratioSlider(title: loc("calc_dry_ratio"), value: $dryingRatio, color: PhaseType.drying.color)
                ratioSlider(title: loc("calc_maillard_ratio"), value: $maillardRatio, color: PhaseType.maillard.color)
                ratioSlider(title: loc("calc_dev_ratio"), value: $devRatio, color: PhaseType.development.color)
            }
            HStack(spacing: 8) {
                timeBadge(title: "脱水节点 (Dry End)", time: dryingSec, color: PhaseType.drying.color)
                timeBadge(title: "一爆节点 (FC Start)", time: dryingSec + maillardSec, color: PhaseType.maillard.color)
                timeBadge(title: "下豆节点 (Drop)", time: totalTimeInSec, color: PhaseType.development.color)
            }
            HStack {
                Button(loc("close")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(loc("calc_apply")) {
                    applyCalculatedTimes()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
    
    private func ratioSlider(title: String, value: Binding<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption)
                Spacer()
                Text(String(format: "%.1f%%", value.wrappedValue))
                    .font(.caption.bold()).foregroundColor(color)
            }
            Slider(value: value, in: 5...70, step: 0.5).tint(color)
        }
    }
    
    private func timeBadge(title: String, time: Double, color: Color) -> some View {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return VStack(spacing: 2) {
            Text(title).font(.system(size: 9)).foregroundColor(.secondary).lineLimit(1)
            Text(String(format: "%d:%02d", mins, secs))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
    
    private func applyCalculatedTimes() {
        guard let last = state.selectedProfile.roastProfilePoints.last, last.x > 0 else { return }
        let scale = totalTimeInSec / last.x
        for i in 0..<state.selectedProfile.roastProfilePoints.count {
            state.selectedProfile.roastProfilePoints[i].x *= scale
            state.selectedProfile.roastProfilePoints[i].cx1 *= scale
            state.selectedProfile.roastProfilePoints[i].cx2 *= scale
        }
    }
}
