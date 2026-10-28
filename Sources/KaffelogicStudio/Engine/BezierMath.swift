import Foundation
import CoreGraphics

public struct EvaluatedCurvePoint: Identifiable, Equatable {
    public var id = UUID()
    public var time: Double
    public var value: Double
    public init(time: Double, value: Double) {
        self.time = time
        self.value = value
    }
}

public class BezierMath {
    public static func evaluateCurve(points: [ProfilePoint], samplesPerSegment: Int = 40) -> [EvaluatedCurvePoint] {
        guard points.count >= 2 else {
            return points.map { EvaluatedCurvePoint(time: $0.x, value: $0.y) }
        }
        var result: [EvaluatedCurvePoint] = []
        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i+1]
            let c1x = (p0.cx2 != 0) ? p0.cx2 : (p0.x + (p1.x - p0.x) / 3.0)
            let c1y = (p0.cy2 != 0) ? p0.cy2 : (p0.y + (p1.y - p0.y) / 3.0)
            let c2x = (p1.cx1 != 0) ? p1.cx1 : (p0.x + 2.0 * (p1.x - p0.x) / 3.0)
            let c2y = (p1.cy1 != 0) ? p1.cy1 : (p0.y + 2.0 * (p1.y - p0.y) / 3.0)
            for s in 0..<samplesPerSegment {
                let t = Double(s) / Double(samplesPerSegment)
                let invT = 1.0 - t
                let curX = invT * invT * invT * p0.x + 3.0 * invT * invT * t * c1x + 3.0 * invT * t * t * c2x + t * t * t * p1.x
                let curY = invT * invT * invT * p0.y + 3.0 * invT * invT * t * c1y + 3.0 * invT * t * t * c2y + t * t * t * p1.y
                result.append(EvaluatedCurvePoint(time: curX, value: curY))
            }
        }
        if let last = points.last {
            result.append(EvaluatedCurvePoint(time: last.x, value: last.y))
        }
        return result
    }
    
    public static func valueAt(time: Double, points: [ProfilePoint]) -> Double? {
        guard let first = points.first, let last = points.last else { return nil }
        if time <= first.x { return first.y }
        if time >= last.x { return last.y }
        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i+1]
            if time >= p0.x && time <= p1.x {
                let factor = (time - p0.x) / max(0.001, (p1.x - p0.x))
                return p0.y + factor * (p1.y - p0.y)
            }
        }
        return last.y
    }
}
