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
