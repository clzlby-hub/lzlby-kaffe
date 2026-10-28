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
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.16))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Material.thin)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // 核心修复：强制卡片水平方向按内容包裹，绝不允许窗口缩小时将数字压断折行！
        .fixedSize(horizontal: true, vertical: false)
    }
}
