import Foundation

public class KaffelogicParser {
    public static func parse(content: String) -> (profile: RoastProfile, log: RoastLog?) {
        let (profilePart, logPart) = splitProfileFromLog(content)
        let profile = parseProfile(profilePart)
        var log: RoastLog? = nil
        if !logPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            log = parseLog(logPart, profileUsed: profile.shortName)
        }
        return (profile, log)
    }
    
    public static func splitProfileFromLog(_ content: String) -> (String, String) {
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
                                .replacingOccurrences(of: "\r", with: "\n")
        let sections = normalized.components(separatedBy: "\n\n")
        if sections.count <= 1 {
            return (normalized, "")
        }
        let profilePart = sections[0]
        let remaining = sections.dropFirst().joined(separator: "\n\n")
        var logLines: [String] = []
        var extraProfile = ""
        for line in remaining.components(separatedBy: "\n") {
            if line.hasPrefix("!") {
                extraProfile += "\n" + line.dropFirst()
            } else {
                logLines.append(line)
            }
        }
        return (profilePart + extraProfile, logLines.joined(separator: "\n"))
    }
    
    public static func parseProfile(_ content: String) -> RoastProfile {
        var profile = RoastProfile()
        let lines = content.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            profile.rawProperties[key] = value
            switch key {
            case "profile_short_name": profile.shortName = value
            case "profile_designer": profile.designer = value
            case "profile_description": profile.description = value
            case "profile_schema_version": profile.schemaVersion = value
            case "recommended_level": profile.recommendedLevel = Double(value) ?? 3.5
            case "expect_fc": profile.expectFirstCrack = Double(value) ?? 208.0
            case "reference_load_size": profile.referenceLoadSize = Double(value) ?? 120.0
            case "preheat_power": profile.preheatPower = Double(value) ?? 1000.0
            case "preheat_nominal_temperature": profile.preheatNominalTemp = Double(value) ?? 240.0
            case "roast_required_power": profile.roastRequiredPower = Double(value) ?? 1200.0
            case "roast_PID_Kp": profile.pidKp = Double(value) ?? 0.717
            case "roast_PID_Ki": profile.pidKi = Double(value) ?? 0.0
            case "roast_PID_Kd": profile.pidKd = Double(value) ?? 3.55
            case "roast_profile": profile.roastProfilePoints = parseBezierNumbers(value)
            case "fan_profile": profile.fanProfilePoints = parseBezierNumbers(value)
            default: break
            }
        }
        return profile
    }
    
    private static func parseBezierNumbers(_ value: String) -> [ProfilePoint] {
        let tokens = value.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0.0 }
        var points: [ProfilePoint] = []
        var i = 0
        while i + 5 < tokens.count {
            points.append(ProfilePoint(x: tokens[i], y: tokens[i+1], cx1: tokens[i+2], cy1: tokens[i+3], cx2: tokens[i+4], cy2: tokens[i+5]))
            i += 6
        }
        return points
    }
    
    public static func parseLog(_ content: String, profileUsed: String) -> RoastLog {
        var log = RoastLog(title: "Roast Log", date: Date(), profileUsed: profileUsed)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return log }
        let headerLine = lines[0]
        let headers = headerLine.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        var timeIdx = 0
        var beanTempIdx: Int? = nil
        var chamberTempIdx: Int? = nil
        var targetTempIdx: Int? = nil
        var actualRoRIdx: Int? = nil
        var desiredRoRIdx: Int? = nil
        var powerIdx: Int? = nil
        var fanIdx: Int? = nil
        for (idx, rawH) in headers.enumerated() {
            let h = rawH.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "@", with: "").replacingOccurrences(of: "&", with: "").replacingOccurrences(of: "^", with: "")
            if h == "time" || idx == 0 { timeIdx = idx }
            else if h == "temp" || h == "spot_temp" { beanTempIdx = idx }
            else if h == "mean_temp" || h == "chamber_temp" { chamberTempIdx = idx }
            else if h == "profile" { targetTempIdx = idx }
            else if h == "actual_ROR" { actualRoRIdx = idx }
            else if h == "desired_ROR" { desiredRoRIdx = idx }
            else if h.contains("power") { powerIdx = idx }
            else if h.contains("fan") { fanIdx = idx }
        }
        var samples: [LogSamplePoint] = []
        for line in lines.dropFirst() {
            let cols = line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            guard cols.count > 1, let t = Double(cols[timeIdx]) else { continue }
            let beanT = (beanTempIdx != nil && beanTempIdx! < cols.count) ? (Double(cols[beanTempIdx!]) ?? 0) : 0
            let chamT = (chamberTempIdx != nil && chamberTempIdx! < cols.count) ? (Double(cols[chamberTempIdx!]) ?? 0) : 0
            let targT = (targetTempIdx != nil && targetTempIdx! < cols.count) ? (Double(cols[targetTempIdx!]) ?? 0) : 0
            let ror = (actualRoRIdx != nil && actualRoRIdx! < cols.count) ? (Double(cols[actualRoRIdx!]) ?? 0) : 0
            let desRor = (desiredRoRIdx != nil && desiredRoRIdx! < cols.count) ? (Double(cols[desiredRoRIdx!]) ?? 0) : 0
            let power = (powerIdx != nil && powerIdx! < cols.count) ? (Double(cols[powerIdx!]) ?? 0) : 0
            let fan = (fanIdx != nil && fanIdx! < cols.count) ? (Double(cols[fanIdx!]) ?? 0) : 0
            samples.append(LogSamplePoint(time: t, beanTemp: beanT, chamberTemp: chamT, targetTemp: targT, actualRoR: ror, desiredRoR: desRor, heaterPower: power, fanSpeed: fan))
        }
        log.samples = samples
        return log
    }
    
    public static func exportKPro(_ profile: RoastProfile) -> String {
        var lines: [String] = []
        lines.append("profile_short_name:\(profile.shortName)")
        lines.append("profile_designer:\(profile.designer)")
        lines.append("profile_description:\(profile.description)")
        lines.append("profile_schema_version:\(profile.schemaVersion)")
        lines.append("recommended_level:\(String(format: "%.1f", profile.recommendedLevel))")
        lines.append("expect_fc:\(String(format: "%.1f", profile.expectFirstCrack))")
        lines.append("reference_load_size:\(Int(profile.referenceLoadSize))")
        lines.append("preheat_power:\(String(format: "%.1f", profile.preheatPower))")
        lines.append("preheat_nominal_temperature:\(String(format: "%.1f", profile.preheatNominalTemp))")
        lines.append("roast_required_power:\(String(format: "%.1f", profile.roastRequiredPower))")
        lines.append("roast_PID_Kp:\(profile.pidKp)")
        lines.append("roast_PID_Ki:\(profile.pidKi)")
        lines.append("roast_PID_Kd:\(profile.pidKd)")
        var roastNums: [String] = []
        for p in profile.roastProfilePoints {
            roastNums.append(contentsOf: [String(format: "%.4f", p.x), String(format: "%.4f", p.y), String(format: "%.4f", p.cx1), String(format: "%.4f", p.cy1), String(format: "%.4f", p.cx2), String(format: "%.4f", p.cy2)])
        }
        lines.append("roast_profile:\(roastNums.joined(separator: ","))")
        var fanNums: [String] = []
        for p in profile.fanProfilePoints {
            fanNums.append(contentsOf: [String(format: "%.4f", p.x), String(format: "%.4f", p.y), String(format: "%.4f", p.cx1), String(format: "%.4f", p.cy1), String(format: "%.4f", p.cx2), String(format: "%.4f", p.cy2)])
        }
        lines.append("fan_profile:\(fanNums.joined(separator: ","))")
        return lines.joined(separator: "\r\n") + "\r\n"
    }
}
