import Foundation

public struct BuiltinProfiles {
    public static var classic: RoastProfile {
        var p = RoastProfile(
            shortName: "经典全能方案 (Classic)",
            designer: "C J Hilder",
            description: "Kaffelogic Nano 7 官方经典内置烘焙曲线",
            schemaVersion: "1.8",
            recommendedLevel: 3.3,
            expectFirstCrack: 209.0,
            referenceLoadSize: 120.0,
            preheatPower: 1050.0,
            preheatNominalTemp: 240.0,
            roastRequiredPower: 1200.0,
            pidKp: 0.717,
            pidKi: 0.0,
            pidKd: 3.55
        )
        p.roastProfilePoints = [
            ProfilePoint(x: 0.0, y: 20.0, cx1: 0, cy1: 0.0, cx2: 18.046, cy2: 47.3),
            ProfilePoint(x: 67.32, y: 106.0, cx1: 42.56, cy1: 84.5, cx2: 96.70, cy2: 131.5),
            ProfilePoint(x: 179.69, y: 170.6, cx1: 143.50, cy1: 156.4, cx2: 218.68, cy2: 185.9),
            ProfilePoint(x: 315.75, y: 202.1, cx1: 274.32, cy1: 195.9, cx2: 436.33, cy2: 220.3),
            ProfilePoint(x: 721.18, y: 231.1, cx1: 599.33, cy1: 226.4, cx2: 0, cy2: 0.0)
        ]
        p.fanProfilePoints = [
            ProfilePoint(x: 0.0, y: 14700.0, cx1: 0, cy1: 0.0, cx2: 20.47, cy2: 14700.1),
            ProfilePoint(x: 68.23, y: 14700.2, cx1: 39.63, cy1: 14705.7, cx2: 158.54, cy2: 14682.8),
            ProfilePoint(x: 331.70, y: 14003.7, cx1: 245.67, cy1: 14529.8, cx2: 395.05, cy2: 13616.3),
            ProfilePoint(x: 540.0, y: 13200.0, cx1: 465.75, cy1: 13189.7, cx2: 564.60, cy2: 13203.4),
            ProfilePoint(x: 600.0, y: 13200.0, cx1: 576.47, cy1: 13199.7, cx2: 0, cy2: 0.0)
        ]
        return p
    }
    
    public static var explorer: RoastProfile {
        var p = RoastProfile(
            shortName: "高海拔探索方案 (Explorer)",
            designer: "Kaffelogic 实验室",
            description: "专为高海拔精品咖啡设计的浅至中度烘焙曲线",
            schemaVersion: "1.8",
            recommendedLevel: 2.8,
            expectFirstCrack: 206.0,
            referenceLoadSize: 120.0,
            preheatPower: 1100.0,
            preheatNominalTemp: 245.0,
            roastRequiredPower: 1250.0,
            pidKp: 0.75,
            pidKi: 0.01,
            pidKd: 3.8
        )
        p.roastProfilePoints = [
            ProfilePoint(x: 0.0, y: 22.0, cx1: 0, cy1: 0.0, cx2: 15.0, cy2: 52.0),
            ProfilePoint(x: 60.0, y: 115.0, cx1: 38.0, cy1: 90.0, cx2: 88.0, cy2: 140.0),
            ProfilePoint(x: 165.0, y: 175.0, cx1: 130.0, cy1: 162.0, cx2: 200.0, cy2: 190.0),
            ProfilePoint(x: 290.0, y: 205.0, cx1: 250.0, cy1: 198.0, cx2: 380.0, cy2: 218.0),
            ProfilePoint(x: 580.0, y: 224.0, cx1: 480.0, cy1: 220.0, cx2: 0, cy2: 0.0)
        ]
        p.fanProfilePoints = [
            ProfilePoint(x: 0.0, y: 15200.0, cx1: 0, cy1: 0.0, cx2: 30.0, cy2: 15200.0),
            ProfilePoint(x: 120.0, y: 14800.0, cx1: 80.0, cy1: 15000.0, cx2: 200.0, cy2: 14200.0),
            ProfilePoint(x: 350.0, y: 13500.0, cx1: 280.0, cy1: 13800.0, cx2: 450.0, cy2: 13100.0),
            ProfilePoint(x: 580.0, y: 13000.0, cx1: 520.0, cy1: 13000.0, cx2: 0, cy2: 0.0)
        ]
        return p
    }
    
    public static func sampleLog(for profile: RoastProfile) -> RoastLog {
        let evaluated = BezierMath.evaluateCurve(points: profile.roastProfilePoints, samplesPerSegment: 30)
        var samples: [LogSamplePoint] = []
        let rorPoints = ROREngine.calculateRoR(samples: evaluated.map { ($0.time, $0.value) })
        for (i, p) in evaluated.enumerated() {
            let noise = sin(Double(i) * 0.5) * 0.35
            let actualTemp = p.value + noise
            let ror = rorPoints.first(where: { abs($0.time - p.time) < 3.0 })?.value ?? 12.0
            let fan = BezierMath.valueAt(time: p.time, points: profile.fanProfilePoints) ?? 14000
            let power = max(0.2, min(1.4, (220.0 - actualTemp) * 0.015))
            samples.append(LogSamplePoint(
                time: p.time,
                beanTemp: actualTemp,
                chamberTemp: actualTemp + 12.0 + cos(Double(i) * 0.3) * 0.8,
                targetTemp: p.value,
                actualRoR: ror + (sin(Double(i)) * 0.4),
                desiredRoR: ror,
                heaterPower: power,
                fanSpeed: fan
            ))
        }
        var log = RoastLog(
            title: "埃塞俄比亚 耶加雪菲 G1 - 实测记录",
            date: Date(),
            profileUsed: profile.shortName,
            samples: samples
        )
        log.firstCrackTime = 320.0
        log.firstCrackTemp = 208.5
        log.dryEndTime = 145.0
        log.dryEndTemp = 150.0
        log.dropTime = evaluated.last?.time ?? 550.0
        log.dropTemp = evaluated.last?.value ?? 222.0
        return log
    }
}
