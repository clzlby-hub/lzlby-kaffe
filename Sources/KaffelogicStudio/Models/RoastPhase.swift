import SwiftUI

public enum PhaseType: String, CaseIterable, Identifiable {
    case drying = "Drying"
    case maillard = "Maillard"
    case development = "Development"
    public var id: String { rawValue }
    
    public var localizedName: String {
        switch self {
        case .drying: return loc("phase_drying")
        case .maillard: return loc("phase_maillard")
        case .development: return loc("phase_development")
        }
    }
    
    public var color: Color {
        switch self {
        case .drying: return Color(red: 0.95, green: 0.82, blue: 0.40)
        case .maillard: return Color(red: 0.85, green: 0.55, blue: 0.28)
        case .development: return Color(red: 0.65, green: 0.30, blue: 0.18)
        }
    }
}

public struct PhaseSegment: Identifiable {
    public var id = UUID()
    public var type: PhaseType
    public var startTime: Double
    public var endTime: Double
    public var startTemp: Double
    public var endTemp: Double
    
    public var duration: Double {
        max(0, endTime - startTime)
    }
    
    public var durationFormatted: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

public struct RoastPhaseSummary {
    public var segments: [PhaseSegment] = []
    public var totalDuration: Double = 0
    public var firstCrackTime: Double? = nil
    public var firstCrackTemp: Double? = nil
    
    public var dtrPercentage: Double {
        guard let dev = segments.first(where: { $0.type == .development }), totalDuration > 0 else {
            return 0
        }
        return (dev.duration / totalDuration) * 100.0
    }
}
