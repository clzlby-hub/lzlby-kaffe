import SwiftUI

public struct RoastChartView: View {
    @ObservedObject var state: AppState
    
    @State private var hoverLocation: CGPoint? = nil
    @State private var hoverTime: Double? = nil
    
    private let maxTime: Double = 600.0
    private let minTemp: Double = 20.0
    private let maxTemp: Double = 240.0
    private let maxRoR: Double = 30.0
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padLeft: CGFloat = 50
            let padRight: CGFloat = 50
            let padTop: CGFloat = 20
            let padBottom: CGFloat = 40
            let plotW = max(10, w - padLeft - padRight)
            let plotH = max(10, h - padTop - padBottom)
            
            ZStack(alignment: .topLeading) {
                drawGrid(w: w, h: h, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                
                if state.showPhasesOverlay {
                    let evaluated = BezierMath.evaluateCurve(points: state.selectedProfile.roastProfilePoints)
                    let phases = ROREngine.computePhases(curve: evaluated, expectFC: state.selectedProfile.expectFirstCrack)
                    drawPhaseBands(phases: phases, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                }
                
                if state.comparisonProfile != nil || state.comparisonLog != nil {
                    HStack(spacing: 6) {
                        Circle().fill(Color.purple).frame(width: 8, height: 8)
                        Text("正在对比: \(state.comparisonProfile?.shortName ?? state.comparisonLog?.title ?? "对比项")")
                            .font(.system(size: 11, weight: .medium))
                        Button(action: { state.clearComparison() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Material.thick)
                    .cornerRadius(12)
                    .position(x: padLeft + 120, y: padTop + 20)
                }
                
                Canvas { context, size in
                    func mapPoint(time: Double, temp: Double) -> CGPoint {
                        let x = padLeft + CGFloat(time / maxTime) * plotW
                        let yRatio = (temp - minTemp) / (maxTemp - minTemp)
                        let y = padTop + plotH - CGFloat(yRatio) * plotH
                        return CGPoint(x: x, y: y)
                    }
                    
                    func mapRoR(time: Double, ror: Double) -> CGPoint {
                        let x = padLeft + CGFloat(time / maxTime) * plotW
                        let yRatio = max(0, min(1.0, ror / maxRoR))
                        let y = padTop + plotH - CGFloat(yRatio) * plotH
                        return CGPoint(x: x, y: y)
                    }
                    
                    if state.showTargetCurve {
                        let targetPoints = BezierMath.evaluateCurve(points: state.selectedProfile.roastProfilePoints, samplesPerSegment: 40)
                        if targetPoints.count >= 2 {
                            var path = Path()
                            path.move(to: mapPoint(time: targetPoints[0].time, temp: targetPoints[0].value))
                            for p in targetPoints.dropFirst() {
                                path.addLine(to: mapPoint(time: p.time, temp: p.value))
                            }
                            context.stroke(path, with: .color(Color.orange.opacity(0.3)), lineWidth: 5)
                            context.stroke(path, with: .color(Color.orange), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                    }
                    
                    if state.showBeanTempCurve, let log = state.selectedLog, log.samples.count >= 2 {
                        var path = Path()
                        path.move(to: mapPoint(time: log.samples[0].time, temp: log.samples[0].beanTemp))
                        for s in log.samples.dropFirst() {
                            path.addLine(to: mapPoint(time: s.time, temp: s.beanTemp))
                        }
                        context.stroke(path, with: .color(Color.red), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                    }
                    
                    if state.showRoRCurve, let log = state.selectedLog {
                        let rors = ROREngine.calculateRoR(samples: log.samples.map { ($0.time, $0.beanTemp) })
                        if rors.count >= 2 {
                            var path = Path()
                            path.move(to: mapRoR(time: rors[0].time, ror: rors[0].value))
                            for r in rors.dropFirst() {
                                path.addLine(to: mapRoR(time: r.time, ror: r.value))
                            }
                            context.stroke(path, with: .color(Color.blue), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [4, 2]))
                        }
                    }
                    
                    if let compP = state.comparisonProfile {
                        let compPoints = BezierMath.evaluateCurve(points: compP.roastProfilePoints, samplesPerSegment: 30)
                        if compPoints.count >= 2 {
                            var path = Path()
                            path.move(to: mapPoint(time: compPoints[0].time, temp: compPoints[0].value))
                            for p in compPoints.dropFirst() {
                                path.addLine(to: mapPoint(time: p.time, temp: p.value))
                            }
                            context.stroke(path, with: .color(Color.purple), style: StrokeStyle(lineWidth: 2.2, dash: [6, 3]))
                        }
                    }
                    if let compL = state.comparisonLog, compL.samples.count >= 2 {
                        var path = Path()
                        path.move(to: mapPoint(time: compL.samples[0].time, temp: compL.samples[0].beanTemp))
                        for s in compL.samples.dropFirst() {
                            path.addLine(to: mapPoint(time: s.time, temp: s.beanTemp))
                        }
                        context.stroke(path, with: .color(Color.green), style: StrokeStyle(lineWidth: 2.0, dash: [4, 2]))
                    }
                    
                    for p in state.selectedProfile.roastProfilePoints {
                        let pt = mapPoint(time: p.x, temp: p.y)
                        let circleRect = CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)
                        context.fill(Path(ellipseIn: circleRect), with: .color(.white))
                        context.stroke(Path(ellipseIn: circleRect), with: .color(.orange), lineWidth: 2)
                    }
                }
                
                if let loc = hoverLocation, let t = hoverTime, t >= 0 && t <= maxTime {
                    let crossX = min(padLeft + plotW, max(padLeft, loc.x))
                    Path { p in
                        p.move(to: CGPoint(x: crossX, y: padTop))
                        p.addLine(to: CGPoint(x: crossX, y: padTop + plotH))
                    }
                    .stroke(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    
                    tooltipView(time: t)
                        .position(x: min(w - 110, max(110, crossX)), y: padTop + 50)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    self.hoverLocation = location
                    let relX = location.x - padLeft
                    let time = (Double(relX) / Double(plotW)) * maxTime
                    self.hoverTime = max(0, min(maxTime, time))
                case .ended:
                    self.hoverLocation = nil
                    self.hoverTime = nil
                }
            }
        }
    }
    
    private func drawGrid(w: CGFloat, h: CGFloat, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .frame(width: plotW, height: plotH)
                .offset(x: padLeft, y: padTop)
            
            ForEach([50.0, 100.0, 150.0, 200.0], id: \.self) { temp in
                let yRatio = CGFloat((temp - minTemp) / (maxTemp - minTemp))
                let y = padTop + plotH - yRatio * plotH
                Path { p in
                    p.move(to: CGPoint(x: padLeft, y: y))
                    p.addLine(to: CGPoint(x: padLeft + plotW, y: y))
                }
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                
                Text("\(Int(temp))°C")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .position(x: padLeft - 22, y: y)
                
                let rorVal = (temp / maxTemp) * maxRoR
                Text("\(Int(rorVal))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.8))
                    .position(x: padLeft + plotW + 20, y: y)
            }
            
            ForEach(Array(stride(from: 60.0, through: maxTime, by: 60.0)), id: \.self) { t in
                let x = padLeft + CGFloat(t / maxTime) * plotW
                Path { p in
                    p.move(to: CGPoint(x: x, y: padTop))
                    p.addLine(to: CGPoint(x: x, y: padTop + plotH))
                }
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                Text(String(format: "%d:00", Int(t) / 60))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .position(x: x, y: padTop + plotH + 16)
            }
        }
    }
    
    private func drawPhaseBands(phases: RoastPhaseSummary, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(phases.segments) { seg in
                let duration = max(0, seg.endTime - seg.startTime)
                let width = (CGFloat(duration) / CGFloat(maxTime)) * plotW
                Rectangle()
                    .fill(seg.type.color.opacity(0.08))
                    .frame(width: max(0, width), height: plotH)
            }
            Spacer(minLength: 0)
        }
        .frame(width: plotW, height: plotH)
        .offset(x: padLeft, y: padTop)
    }
    
    private func tooltipView(time: Double) -> some View {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        let targetT = BezierMath.valueAt(time: time, points: state.selectedProfile.roastProfilePoints) ?? 0.0
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(format: "%d:%02d", mins, secs)).font(.system(size: 12, weight: .bold, design: .monospaced))
                Spacer()
            }
            Divider()
            HStack(spacing: 6) {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                Text(loc("chart_temperature")).font(.system(size: 10)).foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f°C", targetT)).font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            if let log = state.selectedLog, let sample = log.samples.min(by: { abs($0.time - time) < abs($1.time - time) }) {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text(loc("chart_actual_temp")).font(.system(size: 10)).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f°C", sample.beanTemp)).font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.blue).frame(width: 6, height: 6)
                    Text("RoR").font(.system(size: 10)).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f °C/m", sample.actualRoR)).font(.system(size: 11, weight: .semibold, design: .rounded))
                }
            }
        }
        .padding(10)
        .frame(width: 170)
        .background(Material.ultraThick)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
    }
}
