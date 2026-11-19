import SwiftUI

public struct RoastChartView: View {
    @ObservedObject var state: AppState
    
    @State private var hoverLocation: CGPoint? = nil
    @State private var hoverTime: Double? = nil
    @State private var dragTarget: DragTarget? = nil
    @State private var didPushUndoForDrag = false
    
    private enum DragTarget: Equatable {
        case anchor(Int)
        case handleIn(Int)   // cx1, cy1
        case handleOut(Int)  // cx2, cy2
    }
    
    private let minTemp: Double = 20.0
    private let maxTemp: Double = 250.0
    private let maxRoR: Double = 30.0
    private let minFan: Double = 4000.0
    private let maxFan: Double = 18000.0
    
    private var baseMaxTime: Double {
        let pMax = state.selectedProfile.roastProfilePoints.last?.x ?? 540
        let fMax = state.selectedProfile.fanProfilePoints.last?.x ?? 540
        let lMax = state.selectedLog?.samples.last?.time ?? 540
        return max(600.0, ceil(max(pMax, max(fMax, lMax)) / 60.0) * 60.0)
    }
    
    private var visibleStartTime: Double {
        max(0, min(baseMaxTime - visibleDuration, state.chartTimeOffset))
    }
    
    private var visibleDuration: Double {
        baseMaxTime / max(1.0, state.chartZoomScale)
    }
    
    private var visibleEndTime: Double {
        visibleStartTime + visibleDuration
    }
    
    private var editablePoints: [ProfilePoint] {
        switch state.chartEditMode {
        case .view: return []
        case .editTargetTemp: return state.selectedProfile.roastProfilePoints
        case .editFanSpeed: return state.selectedProfile.fanProfilePoints
        }
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let padLeft: CGFloat = 54
            let padRight: CGFloat = 58
            let padTop: CGFloat = 24
            let padBottom: CGFloat = 38
            let plotW = max(10, w - padLeft - padRight)
            let plotH = max(10, h - padTop - padBottom)
            
            ZStack(alignment: .topLeading) {
                drawGrid(w: w, h: h, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                
                if state.showPhasesOverlay {
                    drawPhaseBands(phases: state.cachedPhaseSummary, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                }
                
                Canvas { context, _ in
                    func mapX(_ time: Double) -> CGFloat {
                        padLeft + CGFloat((time - visibleStartTime) / visibleDuration) * plotW
                    }
                    func mapTemp(_ temp: Double) -> CGPoint {
                        let ratio = (temp - minTemp) / (maxTemp - minTemp)
                        return CGPoint(x: mapX(0), y: padTop + plotH - CGFloat(ratio) * plotH)
                    }
                    func mapPoint(time: Double, temp: Double) -> CGPoint {
                        let ratio = (temp - minTemp) / (maxTemp - minTemp)
                        return CGPoint(x: mapX(time), y: padTop + plotH - CGFloat(ratio) * plotH)
                    }
                    func mapRoR(time: Double, ror: Double) -> CGPoint {
                        let ratio = max(0, min(1.0, ror / maxRoR))
                        return CGPoint(x: mapX(time), y: padTop + plotH - CGFloat(ratio) * plotH)
                    }
                    func mapFan(time: Double, rpm: Double) -> CGPoint {
                        let ratio = max(0, min(1.0, (rpm - minFan) / (maxFan - minFan)))
                        return CGPoint(x: mapX(time), y: padTop + plotH - CGFloat(ratio) * plotH)
                    }
                    func mapPower(time: Double, kw: Double) -> CGPoint {
                        let ratio = max(0, min(1.0, kw / 1.5))
                        return CGPoint(x: mapX(time), y: padTop + plotH - CGFloat(ratio) * plotH)
                    }
                    
                    let plotRect = CGRect(x: padLeft, y: padTop, width: plotW, height: plotH)
                    context.clip(to: Path(plotRect))
                    
                    // 1. 风扇曲线 (Teal)
                    if state.showFanCurve, state.cachedFanCurve.count >= 2 {
                        var path = Path()
                        path.move(to: mapFan(time: state.cachedFanCurve[0].time, rpm: state.cachedFanCurve[0].value))
                        for p in state.cachedFanCurve.dropFirst() {
                            path.addLine(to: mapFan(time: p.time, rpm: p.value))
                        }
                        context.stroke(path, with: .color(Color.teal.opacity(0.85)), style: StrokeStyle(lineWidth: 1.8, dash: [5, 3]))
                    }
                    
                    // 2. 功率曲线 (Yellow)
                    if state.showPowerCurve, let log = state.selectedLog, log.samples.count >= 2 {
                        var path = Path()
                        path.move(to: mapPower(time: log.samples[0].time, kw: log.samples[0].heaterPower))
                        for s in log.samples.dropFirst() {
                            path.addLine(to: mapPower(time: s.time, kw: s.heaterPower))
                        }
                        context.stroke(path, with: .color(Color.yellow.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5))
                    }
                    
                    // 3. 目标温度曲线 (Orange)
                    if state.showTargetCurve, state.cachedTargetCurve.count >= 2 {
                        var path = Path()
                        path.move(to: mapPoint(time: state.cachedTargetCurve[0].time, temp: state.cachedTargetCurve[0].value))
                        for p in state.cachedTargetCurve.dropFirst() {
                            path.addLine(to: mapPoint(time: p.time, temp: p.value))
                        }
                        context.stroke(path, with: .color(Color.orange.opacity(0.25)), lineWidth: 5)
                        context.stroke(path, with: .color(Color.orange), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }
                    
                    // 4. 实测豆温曲线 (Red)
                    if state.showBeanTempCurve, let log = state.selectedLog, log.samples.count >= 2 {
                        var path = Path()
                        path.move(to: mapPoint(time: log.samples[0].time, temp: log.samples[0].beanTemp))
                        for s in log.samples.dropFirst() {
                            path.addLine(to: mapPoint(time: s.time, temp: s.beanTemp))
                        }
                        context.stroke(path, with: .color(Color.red), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                    }
                    
                    // 5. RoR 曲线 (Blue)
                    if state.showRoRCurve, state.cachedRoRCurve.count >= 2 {
                        var path = Path()
                        path.move(to: mapRoR(time: state.cachedRoRCurve[0].time, ror: state.cachedRoRCurve[0].value))
                        for r in state.cachedRoRCurve.dropFirst() {
                            path.addLine(to: mapRoR(time: r.time, ror: r.value))
                        }
                        context.stroke(path, with: .color(Color.blue.opacity(0.9)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [4, 2]))
                    }
                    
                    // 6. 对比曲线
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
                    
                    // 7. 一爆 / 下豆事件标记线
                    if let log = state.selectedLog {
                        if let fcTime = log.firstCrackTime {
                            let x = mapX(fcTime)
                            var line = Path()
                            line.move(to: CGPoint(x: x, y: padTop))
                            line.addLine(to: CGPoint(x: x, y: padTop + plotH))
                            context.stroke(line, with: .color(Color.orange.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                        }
                        if let dropTime = log.dropTime {
                            let x = mapX(dropTime)
                            var line = Path()
                            line.move(to: CGPoint(x: x, y: padTop))
                            line.addLine(to: CGPoint(x: x, y: padTop + plotH))
                            context.stroke(line, with: .color(Color.red.opacity(0.6)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                        }
                    }
                    
                    // 8. 可编辑节点与贝塞尔控制柄
                    let pts = editablePoints
                    let accent: Color = state.chartEditMode == .editFanSpeed ? .teal : .orange
                    for (idx, p) in pts.enumerated() {
                        let anchor = state.chartEditMode == .editFanSpeed
                            ? mapFan(time: p.x, rpm: p.y)
                            : mapPoint(time: p.x, temp: p.y)
                        let isSelected = (state.selectedPointIndex == idx)
                        
                        if isSelected {
                            if idx > 0, p.cx1 != 0 || p.cy1 != 0 {
                                let hIn = state.chartEditMode == .editFanSpeed
                                    ? mapFan(time: p.cx1, rpm: p.cy1)
                                    : mapPoint(time: p.cx1, temp: p.cy1)
                                var tangent = Path()
                                tangent.move(to: anchor)
                                tangent.addLine(to: hIn)
                                context.stroke(tangent, with: .color(accent.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                let rect = CGRect(x: hIn.x - 4, y: hIn.y - 4, width: 8, height: 8)
                                context.fill(Path(rect), with: .color(accent))
                            }
                            if idx < pts.count - 1, p.cx2 != 0 || p.cy2 != 0 {
                                let hOut = state.chartEditMode == .editFanSpeed
                                    ? mapFan(time: p.cx2, rpm: p.cy2)
                                    : mapPoint(time: p.cx2, temp: p.cy2)
                                var tangent = Path()
                                tangent.move(to: anchor)
                                tangent.addLine(to: hOut)
                                context.stroke(tangent, with: .color(accent.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                                let rect = CGRect(x: hOut.x - 4, y: hOut.y - 4, width: 8, height: 8)
                                context.fill(Path(rect), with: .color(accent))
                            }
                        }
                        
                        let r: CGFloat = isSelected ? 6.5 : 5.0
                        let circleRect = CGRect(x: anchor.x - r, y: anchor.y - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: circleRect), with: .color(isSelected ? accent : .white))
                        context.stroke(Path(ellipseIn: circleRect), with: .color(isSelected ? .white : accent), lineWidth: 2)
                    }
                    let _ = mapTemp(minTemp)
                }
                
                // 左上角状态/对比悬浮条
                HStack(spacing: 8) {
                    if state.comparisonProfile != nil || state.comparisonLog != nil {
                        HStack(spacing: 6) {
                            Circle().fill(Color.purple).frame(width: 8, height: 8)
                            Text("对比: \(state.comparisonProfile?.shortName ?? state.comparisonLog?.title ?? "")")
                                .font(.system(size: 11, weight: .medium))
                            Button(action: { state.clearComparison() }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Material.thick)
                        .cornerRadius(12)
                    }
                    
                    if state.chartZoomScale > 1.01 {
                        Button(action: {
                            state.chartZoomScale = 1.0
                            state.chartTimeOffset = 0.0
                        }) {
                            Label("重置缩放 (\(String(format: "%.1fx", state.chartZoomScale)))", systemImage: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.leading, padLeft + 10)
                .padding(.top, padTop + 8)
                
                // 十字准星与 Tooltip
                if let loc = hoverLocation, let t = hoverTime, t >= visibleStartTime && t <= visibleEndTime, dragTarget == nil {
                    let crossX = min(padLeft + plotW, max(padLeft, loc.x))
                    Path { p in
                        p.move(to: CGPoint(x: crossX, y: padTop))
                        p.addLine(to: CGPoint(x: crossX, y: padTop + plotH))
                    }
                    .stroke(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    
                    tooltipView(time: t)
                        .position(x: min(w - 130, max(130, crossX)), y: padTop + 58)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    self.hoverLocation = location
                    let relX = location.x - padLeft
                    let time = visibleStartTime + (Double(relX) / Double(plotW)) * visibleDuration
                    self.hoverTime = max(visibleStartTime, min(visibleEndTime, time))
                case .ended:
                    self.hoverLocation = nil
                    self.hoverTime = nil
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(
                            location: value.location,
                            plotW: plotW,
                            plotH: plotH,
                            padLeft: padLeft,
                            padTop: padTop
                        )
                    }
                    .onEnded { _ in
                        dragTarget = nil
                        didPushUndoForDrag = false
                    }
            )
            .onTapGesture(count: 2) { location in
                insertNodeAt(
                    location: location,
                    plotW: plotW,
                    plotH: plotH,
                    padLeft: padLeft,
                    padTop: padTop
                )
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newScale = max(1.0, min(4.0, value.magnification))
                        state.chartZoomScale = newScale
                        if newScale <= 1.01 { state.chartTimeOffset = 0 }
                    }
            )
            .focusable()
            .onDeleteCommand {
                deleteSelectedNode()
            }
            .contextMenu {
                if state.chartEditMode != .view, let idx = state.selectedPointIndex {
                    Button(role: .destructive) {
                        deleteSelectedNode(at: idx)
                    } label: {
                        Label("删除选中节点 #\(idx + 1)", systemImage: "trash")
                    }
                    .disabled(editablePoints.count <= 2)
                }
                if state.chartZoomScale > 1.01 {
                    Button {
                        state.chartZoomScale = 1.0
                        state.chartTimeOffset = 0
                    } label: {
                        Label("重置缩放", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                }
                Menu("切换编辑模式") {
                    ForEach(ChartEditMode.allCases) { mode in
                        Button(mode.rawValue) {
                            state.chartEditMode = mode
                            state.selectedPointIndex = nil
                        }
                    }
                }
            }
        }
    }
    
    private func deleteSelectedNode(at explicitIndex: Int? = nil) {
        guard state.chartEditMode != .view else { return }
        let idx = explicitIndex ?? state.selectedPointIndex
        guard let idx else { return }
        let isFan = state.chartEditMode == .editFanSpeed
        let count = isFan ? state.selectedProfile.fanProfilePoints.count : state.selectedProfile.roastProfilePoints.count
        guard count > 2, idx < count else { return }
        state.pushUndoSnapshot()
        state.updateSelectedProfile { p in
            if isFan {
                p.fanProfilePoints.remove(at: idx)
            } else {
                p.roastProfilePoints.remove(at: idx)
            }
        }
        state.selectedPointIndex = nil
    }
    
    // MARK: - 交互编辑逻辑
    private func pointToScreen(_ p: ProfilePoint, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> CGPoint {
        let x = padLeft + CGFloat((p.x - visibleStartTime) / visibleDuration) * plotW
        let ratio: Double
        if state.chartEditMode == .editFanSpeed {
            ratio = (p.y - minFan) / (maxFan - minFan)
        } else {
            ratio = (p.y - minTemp) / (maxTemp - minTemp)
        }
        let y = padTop + plotH - CGFloat(ratio) * plotH
        return CGPoint(x: x, y: y)
    }
    
    private func handlePointToScreen(_ xVal: Double, _ yVal: Double, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> CGPoint {
        let x = padLeft + CGFloat((xVal - visibleStartTime) / visibleDuration) * plotW
        let ratio = state.chartEditMode == .editFanSpeed
            ? (yVal - minFan) / (maxFan - minFan)
            : (yVal - minTemp) / (maxTemp - minTemp)
        let y = padTop + plotH - CGFloat(ratio) * plotH
        return CGPoint(x: x, y: y)
    }
    
    private func screenToData(_ loc: CGPoint, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> (x: Double, y: Double) {
        let time = visibleStartTime + Double((loc.x - padLeft) / plotW) * visibleDuration
        let yRatio = 1.0 - Double((loc.y - padTop) / plotH)
        let val: Double
        if state.chartEditMode == .editFanSpeed {
            val = max(minFan, min(maxFan, minFan + yRatio * (maxFan - minFan)))
        } else {
            val = max(minTemp, min(maxTemp, minTemp + yRatio * (maxTemp - minTemp)))
        }
        return (max(0, min(baseMaxTime, time)), val)
    }
    
    private func handleDragChanged(location: CGPoint, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) {
        guard state.chartEditMode != .view else { return }
        let pts = editablePoints
        guard !pts.isEmpty else { return }
        
        if dragTarget == nil {
            let hitRadius: CGFloat = 14
            if let sel = state.selectedPointIndex, sel < pts.count {
                let p = pts[sel]
                if sel > 0, p.cx1 != 0 || p.cy1 != 0 {
                    let hIn = handlePointToScreen(p.cx1, p.cy1, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                    if hypot(location.x - hIn.x, location.y - hIn.y) <= hitRadius {
                        dragTarget = .handleIn(sel)
                    }
                }
                if dragTarget == nil, sel < pts.count - 1, p.cx2 != 0 || p.cy2 != 0 {
                    let hOut = handlePointToScreen(p.cx2, p.cy2, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                    if hypot(location.x - hOut.x, location.y - hOut.y) <= hitRadius {
                        dragTarget = .handleOut(sel)
                    }
                }
            }
            if dragTarget == nil {
                var bestIdx: Int? = nil
                var bestDist: CGFloat = hitRadius
                for (i, p) in pts.enumerated() {
                    let sp = pointToScreen(p, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
                    let d = hypot(location.x - sp.x, location.y - sp.y)
                    if d <= bestDist {
                        bestDist = d
                        bestIdx = i
                    }
                }
                if let bestIdx {
                    state.selectedPointIndex = bestIdx
                    dragTarget = .anchor(bestIdx)
                } else {
                    state.selectedPointIndex = nil
                    return
                }
            }
        }
        
        guard let target = dragTarget else { return }
        if !didPushUndoForDrag {
            state.pushUndoSnapshot()
            didPushUndoForDrag = true
        }
        let data = screenToData(location, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
        
        state.updateSelectedProfile { profile in
            var arr = state.chartEditMode == .editFanSpeed ? profile.fanProfilePoints : profile.roastProfilePoints
            switch target {
            case .anchor(let idx) where idx < arr.count:
                let minX = idx == 0 ? 0.0 : arr[idx - 1].x + 5.0
                let maxX = idx == arr.count - 1 ? baseMaxTime : arr[idx + 1].x - 5.0
                let clampedX = idx == 0 ? 0.0 : max(minX, min(maxX, data.x))
                let dx = clampedX - arr[idx].x
                let dy = data.y - arr[idx].y
                arr[idx].x = clampedX
                arr[idx].y = data.y
                if arr[idx].cx1 != 0 || arr[idx].cy1 != 0 {
                    arr[idx].cx1 += dx
                    arr[idx].cy1 += dy
                }
                if arr[idx].cx2 != 0 || arr[idx].cy2 != 0 {
                    arr[idx].cx2 += dx
                    arr[idx].cy2 += dy
                }
            case .handleIn(let idx) where idx < arr.count:
                arr[idx].cx1 = data.x
                arr[idx].cy1 = data.y
            case .handleOut(let idx) where idx < arr.count:
                arr[idx].cx2 = data.x
                arr[idx].cy2 = data.y
            default:
                break
            }
            if state.chartEditMode == .editFanSpeed {
                profile.fanProfilePoints = arr
            } else {
                profile.roastProfilePoints = arr
            }
        }
    }
    
    private func insertNodeAt(location: CGPoint, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) {
        guard state.chartEditMode != .view else { return }
        let data = screenToData(location, plotW: plotW, plotH: plotH, padLeft: padLeft, padTop: padTop)
        state.pushUndoSnapshot()
        state.updateSelectedProfile { profile in
            var arr = state.chartEditMode == .editFanSpeed ? profile.fanProfilePoints : profile.roastProfilePoints
            let newPt = ProfilePoint(x: data.x, y: data.y)
            arr.append(newPt)
            arr.sort { $0.x < $1.x }
            if let newIdx = arr.firstIndex(where: { $0.id == newPt.id }) {
                state.selectedPointIndex = newIdx
            }
            if state.chartEditMode == .editFanSpeed {
                profile.fanProfilePoints = arr
            } else {
                profile.roastProfilePoints = arr
            }
        }
    }
    
    // MARK: - 网格与坐标轴
    private func drawGrid(w: CGFloat, h: CGFloat, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            
            // 水平温度线
            ForEach([50.0, 100.0, 150.0, 200.0, 250.0], id: \.self) { temp in
                let ratio = (temp - minTemp) / (maxTemp - minTemp)
                let y = padTop + plotH - CGFloat(ratio) * plotH
                Path { p in
                    p.move(to: CGPoint(x: padLeft, y: y))
                    p.addLine(to: CGPoint(x: padLeft + plotW, y: y))
                }
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                
                Text("\(Int(round(state.displayTemp(temp))))\(state.tempUnit.rawValue)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .position(x: 26, y: y)
            }
            
            // 右侧副轴（风扇 RPM 或 RoR）
            if state.showFanCurve && state.chartEditMode == .editFanSpeed {
                ForEach([6000.0, 10000.0, 14000.0, 18000.0], id: \.self) { rpm in
                    let ratio = (rpm - minFan) / (maxFan - minFan)
                    let y = padTop + plotH - CGFloat(ratio) * plotH
                    Text("\(Int(rpm / 1000))k")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.teal)
                        .position(x: w - 26, y: y)
                }
            } else {
                ForEach([5.0, 10.0, 15.0, 20.0, 25.0, 30.0], id: \.self) { ror in
                    let ratio = ror / maxRoR
                    let y = padTop + plotH - CGFloat(ratio) * plotH
                    Text("\(Int(ror))°/m")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.blue.opacity(0.75))
                        .position(x: w - 26, y: y)
                }
            }
            
            // 垂直时间线
            let step: Double = visibleDuration <= 300 ? 30 : 60
            let firstTick = ceil(visibleStartTime / step) * step
            let tickCount = Int(floor((visibleEndTime - firstTick) / step)) + 1
            ForEach(0..<max(0, tickCount), id: \.self) { i in
                let t = firstTick + Double(i) * step
                let x = padLeft + CGFloat((t - visibleStartTime) / visibleDuration) * plotW
                Path { p in
                    p.move(to: CGPoint(x: x, y: padTop))
                    p.addLine(to: CGPoint(x: x, y: padTop + plotH))
                }
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                
                Text("\(Int(t) / 60):\(String(format: "%02d", Int(t) % 60))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .position(x: x, y: h - 18)
            }
        }
    }
    
    private func drawPhaseBands(phases: RoastPhaseSummary, plotW: CGFloat, plotH: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(phases.segments) { seg in
                let s = max(visibleStartTime, seg.startTime)
                let e = min(visibleEndTime, seg.endTime)
                if e > s {
                    let startX = padLeft + CGFloat((s - visibleStartTime) / visibleDuration) * plotW
                    let endX = padLeft + CGFloat((e - visibleStartTime) / visibleDuration) * plotW
                    Rectangle()
                        .fill(seg.type.color.opacity(0.08))
                        .frame(width: max(0, endX - startX), height: plotH)
                        .position(x: startX + (endX - startX) / 2, y: padTop + plotH / 2)
                }
            }
        }
    }
    
    private func tooltipView(time: Double) -> some View {
        let targetT = BezierMath.valueAt(time: time, points: state.selectedProfile.roastProfilePoints)
        let fanVal = BezierMath.valueAt(time: time, points: state.selectedProfile.fanProfilePoints)
        let logSample = state.selectedLog?.samples.min(by: { abs($0.time - time) < abs($1.time - time) })
        let rorSample = state.cachedRoRCurve.min(by: { abs($0.time - time) < abs($1.time - time) })
        
        return VStack(alignment: .leading, spacing: 4) {
            Text("时间 \(Int(time) / 60):\(String(format: "%02d", Int(time) % 60))")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            Divider()
            if let tT = targetT {
                HStack {
                    Circle().fill(Color.orange).frame(width: 6, height: 6)
                    Text("目标温:")
                    Spacer()
                    Text(state.formatTemp(tT)).bold()
                }
            }
            if let lS = logSample {
                HStack {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text("实测温:")
                    Spacer()
                    Text(state.formatTemp(lS.beanTemp)).bold()
                }
            }
            if let rS = rorSample {
                HStack {
                    Circle().fill(Color.blue).frame(width: 6, height: 6)
                    Text("RoR:")
                    Spacer()
                    Text(state.formatRoR(rS.value)).bold()
                }
            }
            if let fV = fanVal, state.showFanCurve {
                HStack {
                    Circle().fill(Color.teal).frame(width: 6, height: 6)
                    Text("风扇:")
                    Spacer()
                    Text("\(Int(fV)) RPM").bold()
                }
            }
        }
        .font(.system(size: 11))
        .padding(8)
        .frame(width: 165)
        .background(Material.ultraThick)
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}
