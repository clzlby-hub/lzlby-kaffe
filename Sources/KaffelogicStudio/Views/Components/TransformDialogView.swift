import SwiftUI

public struct TransformDialogView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeMultiplier: Double = 1.0
    @State private var timeOffset: Double = 0.0
    @State private var tempMultiplier: Double = 1.0
    @State private var tempOffset: Double = 0.0
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "arrow.left.and.right.circle")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text(loc("trans_title")).font(.headline)
                Spacer()
            }
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    Text(loc("trans_time_factor"))
                    TextField("", value: $timeMultiplier, format: .number)
                        .textFieldStyle(.roundedBorder).frame(width: 80)
                    Text(loc("trans_time_offset"))
                    TextField("", value: $timeOffset, format: .number)
                        .textFieldStyle(.roundedBorder).frame(width: 80)
                    Text("s").foregroundColor(.secondary)
                }
                GridRow {
                    Text(loc("trans_temp_factor"))
                    TextField("", value: $tempMultiplier, format: .number)
                        .textFieldStyle(.roundedBorder).frame(width: 80)
                    Text(loc("trans_temp_offset"))
                    TextField("", value: $tempOffset, format: .number)
                        .textFieldStyle(.roundedBorder).frame(width: 80)
                    Text("°C").foregroundColor(.secondary)
                }
            }
            Text("变换公式: 新时间 = 时间 × 缩放 + 偏置；新温度 = 温度 × 缩放 + 偏置")
                .font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Button(loc("close")) { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button(loc("apply")) {
                    applyTransform()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
    
    private func applyTransform() {
        for i in 0..<state.selectedProfile.roastProfilePoints.count {
            state.selectedProfile.roastProfilePoints[i].x = state.selectedProfile.roastProfilePoints[i].x * timeMultiplier + timeOffset
            state.selectedProfile.roastProfilePoints[i].y = state.selectedProfile.roastProfilePoints[i].y * tempMultiplier + tempOffset
            state.selectedProfile.roastProfilePoints[i].cx1 = state.selectedProfile.roastProfilePoints[i].cx1 * timeMultiplier + timeOffset
            state.selectedProfile.roastProfilePoints[i].cy1 = state.selectedProfile.roastProfilePoints[i].cy1 * tempMultiplier + tempOffset
            state.selectedProfile.roastProfilePoints[i].cx2 = state.selectedProfile.roastProfilePoints[i].cx2 * timeMultiplier + timeOffset
            state.selectedProfile.roastProfilePoints[i].cy2 = state.selectedProfile.roastProfilePoints[i].cy2 * tempMultiplier + tempOffset
        }
    }
}
