import SwiftUI

public struct AUCDialogView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var baseTime: Double = 0.0
    @State private var endTime: Double = 500.0
    @State private var baseTemp: Double = 100.0
    @State private var fromCurveBaseline: Bool = true
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text(loc("auc_title"))
                    .font(.headline)
                Spacer()
            }
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text(loc("auc_base_time"))
                    TextField("", value: $baseTime, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("s").foregroundColor(.secondary)
                }
                GridRow {
                    Text(loc("auc_end_time"))
                    TextField("", value: $endTime, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("s").foregroundColor(.secondary)
                }
                GridRow {
                    Text(loc("auc_base_temp"))
                    TextField("", value: $baseTemp, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("°C").foregroundColor(.secondary)
                }
            }
            Toggle(loc("auc_from_curve"), isOn: $fromCurveBaseline)
                .onChange(of: fromCurveBaseline) { _, newVal in
                    if newVal {
                        baseTemp = 100.0
                        if let first = state.selectedProfile.roastProfilePoints.first {
                            baseTime = first.x
                        }
                        if let last = state.selectedProfile.roastProfilePoints.last {
                            endTime = last.x
                        }
                    }
                }
            
            let aucValue = calculateAUC()
            VStack(spacing: 4) {
                Text(loc("auc_result"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", aucValue))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("°C·min")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            
            HStack {
                Spacer()
                Button(loc("close")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if let last = state.selectedProfile.roastProfilePoints.last {
                endTime = last.x
            }
        }
    }
    
    private func calculateAUC() -> Double {
        let curve = BezierMath.evaluateCurve(points: state.selectedProfile.roastProfilePoints, samplesPerSegment: 40)
        guard curve.count >= 2 else { return 0 }
        let filtered = curve.filter { $0.time >= baseTime && $0.time <= endTime }
        guard filtered.count >= 2 else { return 0 }
        var totalAreaSeconds: Double = 0
        for i in 0..<(filtered.count - 1) {
            let p0 = filtered[i]
            let p1 = filtered[i+1]
            let dt = p1.time - p0.time
            let avgT = ((p0.value + p1.value) / 2.0) - baseTemp
            if avgT > 0 {
                totalAreaSeconds += avgT * dt
            }
        }
        return totalAreaSeconds / 60.0
    }
}
