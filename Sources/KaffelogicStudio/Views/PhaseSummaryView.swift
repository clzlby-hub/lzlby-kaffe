import SwiftUI

public struct PhaseSummaryView: View {
    public let summary: RoastPhaseSummary
    
    public var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 3) {
                ForEach(summary.segments) { seg in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Circle()
                                .fill(seg.type.color)
                                .frame(width: 8, height: 8)
                            Text(seg.type.localizedName)
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Text(seg.durationFormatted)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(seg.type.color.gradient)
                            .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Material.regular)
            .cornerRadius(10)
            
            VStack(spacing: 2) {
                Text(loc("phase_ratio"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", summary.dtrPercentage))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(PhaseType.development.color)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(PhaseType.development.color.opacity(0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(PhaseType.development.color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
