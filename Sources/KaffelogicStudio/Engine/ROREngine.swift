import Foundation

public class ROREngine {
    public static func calculateRoR(samples: [(time: Double, temp: Double)], windowSeconds: Double = 30.0) -> [EvaluatedCurvePoint] {
        guard samples.count >= 2 else { return [] }
        var rorPoints: [EvaluatedCurvePoint] = []
        let halfWindow = windowSeconds / 2.0
        for i in 0..<samples.count {
            let current = samples[i]
            let t = current.time
            let pastSamples = samples.filter { $0.time >= (t - halfWindow) && $0.time <= t }
            let futureSamples = samples.filter { $0.time >= t && $0.time <= (t + halfWindow) }
            if let first = pastSamples.first, let last = futureSamples.last, last.time > first.time {
                let dt = last.time - first.time
                let dTemp = last.temp - first.temp
                let rorPerMin = (dTemp / dt) * 60.0
                rorPoints.append(EvaluatedCurvePoint(time: t, value: max(-10, min(50, rorPerMin))))
            }
        }
        return rorPoints
    }
    
    public static func computePhases(curve: [EvaluatedCurvePoint], expectFC: Double = 208.0) -> RoastPhaseSummary {
        guard let first = curve.first, let last = curve.last, last.time > first.time else {
            return RoastPhaseSummary()
        }
        let dryEndTemp = 150.0
        let fcTemp = expectFC
        let dryEndTime = curve.first(where: { $0.value >= dryEndTemp })?.time ?? (last.time * 0.45)
        let fcTime = curve.first(where: { $0.value >= fcTemp })?.time ?? (last.time * 0.80)
        var segments: [PhaseSegment] = []
        segments.append(PhaseSegment(type: .drying, startTime: first.time, endTime: dryEndTime, startTemp: first.value, endTemp: dryEndTemp))
        segments.append(PhaseSegment(type: .maillard, startTime: dryEndTime, endTime: fcTime, startTemp: dryEndTemp, endTemp: fcTemp))
        segments.append(PhaseSegment(type: .development, startTime: fcTime, endTime: last.time, startTemp: fcTemp, endTemp: last.value))
        return RoastPhaseSummary(segments: segments, totalDuration: last.time, firstCrackTime: fcTime, firstCrackTemp: fcTemp)
    }
}
