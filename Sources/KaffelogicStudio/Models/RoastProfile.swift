import Foundation

public struct RoastProfile: Identifiable, Equatable {
    public var id = UUID()
    public var shortName: String
    public var designer: String
    public var description: String
    public var schemaVersion: String
    public var recommendedLevel: Double
    public var expectFirstCrack: Double
    public var referenceLoadSize: Double
    public var preheatPower: Double
    public var preheatNominalTemp: Double
    public var roastRequiredPower: Double
    public var pidKp: Double
    public var pidKi: Double
    public var pidKd: Double
    public var roastProfilePoints: [ProfilePoint]
    public var fanProfilePoints: [ProfilePoint]
    public var rawProperties: [String: String] = [:]
    
    public init(
        shortName: String = "My Roast Profile",
        designer: String = "Barista",
        description: String = "",
        schemaVersion: String = "1.8",
        recommendedLevel: Double = 3.5,
        expectFirstCrack: Double = 208.0,
        referenceLoadSize: Double = 120.0,
        preheatPower: Double = 1000.0,
        preheatNominalTemp: Double = 240.0,
        roastRequiredPower: Double = 1200.0,
        pidKp: Double = 0.717,
        pidKi: Double = 0.0,
        pidKd: Double = 3.55,
        roastProfilePoints: [ProfilePoint] = [],
        fanProfilePoints: [ProfilePoint] = []
    ) {
        self.shortName = shortName
        self.designer = designer
        self.description = description
        self.schemaVersion = schemaVersion
        self.recommendedLevel = recommendedLevel
        self.expectFirstCrack = expectFirstCrack
        self.referenceLoadSize = referenceLoadSize
        self.preheatPower = preheatPower
        self.preheatNominalTemp = preheatNominalTemp
        self.roastRequiredPower = roastRequiredPower
        self.pidKp = pidKp
        self.pidKi = pidKi
        self.pidKd = pidKd
        self.roastProfilePoints = roastProfilePoints
        self.fanProfilePoints = fanProfilePoints
    }
}
