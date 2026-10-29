import SwiftUI

public struct MetricBadge: View {
    public let title: String
    public let value: String
    public let unit: String
    public let icon: String
    public let tint: Color

    public init(title: String, value: String, unit: String = "", icon: String, tint: Color) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .fixedSize()

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize()

                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Material.thin)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // Both axes fixed so the card never squishes numbers
        .fixedSize(horizontal: true, vertical: true)
    }
}
