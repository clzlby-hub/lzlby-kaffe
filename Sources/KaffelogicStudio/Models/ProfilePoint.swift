import Foundation

public struct ProfilePoint: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var x: Double
    public var y: Double
    public var cx1: Double
    public var cy1: Double
    public var cx2: Double
    public var cy2: Double
    
    public init(x: Double, y: Double, cx1: Double = 0, cy1: Double = 0, cx2: Double = 0, cy2: Double = 0) {
        self.x = x
        self.y = y
        self.cx1 = cx1
        self.cy1 = cy1
        self.cx2 = cx2
        self.cy2 = cy2
    }
    
    enum CodingKeys: String, CodingKey {
        case x, y, cx1, cy1, cx2, cy2
    }
}
