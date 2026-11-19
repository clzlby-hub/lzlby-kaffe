import Foundation

public struct LogSamplePoint: Identifiable, Equatable {
    public var id = UUID()
    public var time: Double
    public var beanTemp: Double
    public var chamberTemp: Double
    public var targetTemp: Double
    public var actualRoR: Double
    public var desiredRoR: Double
    public var heaterPower: Double
    public var fanSpeed: Double
    
    public init(
        time: Double,
        beanTemp: Double,
        chamberTemp: Double = 0,
        targetTemp: Double = 0,
        actualRoR: Double = 0,
        desiredRoR: Double = 0,
        heaterPower: Double = 0,
        fanSpeed: Double = 0
    ) {
        self.time = time
        self.beanTemp = beanTemp
        self.chamberTemp = chamberTemp
        self.targetTemp = targetTemp
        self.actualRoR = actualRoR
        self.desiredRoR = desiredRoR
        self.heaterPower = heaterPower
        self.fanSpeed = fanSpeed
    }
}

public struct RoastLog: Identifiable, Equatable {
    public var id = UUID()
    public var title: String
    public var date: Date
    public var profileUsed: String
    public var samples: [LogSamplePoint]
    public var turningPointTime: Double?
    public var turningPointTemp: Double?
    public var dryEndTime: Double?
    public var dryEndTemp: Double?
    public var firstCrackTime: Double?
    public var firstCrackTemp: Double?
    public var dropTime: Double?
    public var dropTemp: Double?
    public var beanOrigin: String = ""
    public var greenWeight: Double?
    public var roastedWeight: Double?
    public var cuppingScore: Double?
    public var tastingNotes: String = ""
    public var fileName: String?

    public var weightLossPercent: Double? {
        guard let g = greenWeight, let r = roastedWeight, g > 0, r >= 0, r <= g else { return nil }
        return ((g - r) / g) * 100.0
    }
    
    public init(
        title: String,
        date: Date = Date(),
        profileUsed: String = "",
        samples: [LogSamplePoint] = []
    ) {
        self.title = title
        self.date = date
        self.profileUsed = profileUsed
        self.samples = samples
    }
}
