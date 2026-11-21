import AppKit
import SwiftUI

enum MonitorStyle: String, CaseIterable, Identifiable {
    case pureGlass, aluminum, liquid, darkPro, hudNeon, monochrome
    case aurora, ultraMinimal, frosted, depthGlass, classicInstrument, spaceBlack
    var id: Self { self }
    var name: String {
        switch self {
        case .pureGlass: "Pure Glass"
        case .aluminum: "Brushed Aluminum"
        case .liquid: "Liquid Dynamic"
        case .darkPro: "Dark Pro"
        case .hudNeon: "HUD Neon"
        case .monochrome: "Monochrome Elegance"
        case .aurora: "Aurora"
        case .ultraMinimal: "Ultra Minimal"
        case .frosted: "Frosted Blur"
        case .depthGlass: "Depth Glass"
        case .classicInstrument: "Classic Instrument"
        case .spaceBlack: "Space Black"
        }
    }
    var light: Bool { self == .ultraMinimal }
    var metallic: Bool { [.aluminum, .monochrome, .classicInstrument].contains(self) }
    var fluid: Bool { [.liquid, .aurora, .depthGlass].contains(self) }
    var ink: Color { light ? Color(white: 0.12) : .white }
    var glow: CGFloat { [.pureGlass, .liquid, .hudNeon, .aurora, .depthGlass].contains(self) ? 9 : 2 }
    var background: Color {
        switch self {
        case .ultraMinimal: Color(white: 0.94)
        case .aluminum, .monochrome, .classicInstrument: Color(white: 0.22)
        case .darkPro, .spaceBlack, .hudNeon: Color(red: 0.025, green: 0.035, blue: 0.055)
        default: Color(red: 0.22, green: 0.29, blue: 0.45)
        }
    }
    func tint(_ metric: Metric) -> Color {
        if self == .monochrome || self == .classicInstrument { return Color(white: 0.95) }
        let gpu: Color = self == .aluminum || self == .darkPro || self == .ultraMinimal ? .orange : .purple
        return [.cpu: Color.cyan, .gpu: gpu, .memory: Color.green][metric] ?? .white
    }
    static func migrateSelection(in defaults: UserDefaults = .standard) {
        guard let old = defaults.string(forKey: "monitorStyle"), Self(rawValue: old) == nil else { return }
        let migration = [
            "titanium": "aluminum", "graphite": "darkPro", "porcelain": "ultraMinimal",
            "glass": "pureGlass", "classic": "classicInstrument", "terminal": "monochrome",
            "blueprint": "hudNeon", "neon": "hudNeon", "racing": "classicInstrument",
            "orbit": "spaceBlack", "comic": "aurora", "amber": "classicInstrument",
            "paper": "ultraMinimal", "spectrum": "liquid"
        ]
        defaults.set(migration[old] ?? Self.pureGlass.rawValue, forKey: "monitorStyle")
    }
}

struct MonitorView: View {
    let monitor: Monitor
    @AppStorage("monitorStyle") private var style = MonitorStyle.pureGlass

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 840, geometry.size.height / 300)
            ConnectedMeters(monitor: monitor, style: style)
                .frame(width: 840, height: 300).scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .preferredColorScheme(style.light ? .light : .dark)
        .accessibilityHint("ドラッグで移動。右下のハンドルをドラッグしてサイズ変更。右クリックでスタイル、最小化を操作できます。")
    }
}

struct ConnectedMeters: View {
    let monitor: Monitor
    let style: MonitorStyle

    var body: some View {
        ZStack {
            if [.pureGlass, .liquid, .aurora, .frosted, .depthGlass].contains(style) {
                Ellipse().fill(.blue.opacity(0.65)).frame(width: 500, height: 210)
                    .blur(radius: 48).offset(x: -150, y: -25)
                Ellipse().fill(.purple.opacity(0.5)).frame(width: 420, height: 180)
                    .blur(radius: 42).offset(x: 150, y: 40)
            }
            frame
            HStack(spacing: 4) {
                ForEach(Metric.primary) { metric in
                    Meter(monitor: monitor, metric: metric, style: style)
                }
            }.padding(.horizontal, 24)
            if style == .classicInstrument {
                ForEach(0..<4) { index in
                    Circle().fill(LinearGradient(colors: [.white, .gray, .black], startPoint: .top, endPoint: .bottom))
                        .frame(width: 8, height: 8)
                        .overlay(Rectangle().fill(.black.opacity(0.7)).frame(width: 5, height: 1).rotationEffect(.degrees(35)))
                        .position(x: index % 2 == 0 ? 17 : 823, y: index < 2 ? 29 : 271)
                }
            }
        }
        .frame(width: 840, height: 300)
        .clipShape(ConnectedOutline(rectangular: style == .classicInstrument, angular: style == .hudNeon).inset(by: 8))
    }

    private var frame: some View {
        let outline = ConnectedOutline(rectangular: style == .classicInstrument, angular: style == .hudNeon)
        return ZStack {
            if style == .frosted || style == .pureGlass {
                outline.fill(.ultraThinMaterial)
                outline.fill(.white.opacity(style == .pureGlass ? 0.14 : 0.22))
            } else {
                outline.fill(LinearGradient(colors: frameColors, startPoint: .top, endPoint: .bottom))
            }
            outline.strokeBorder(LinearGradient(
                colors: style.metallic ? [.white, Color(white: 0.3), .black, .white] : [.white.opacity(0.8), .cyan.opacity(0.5), .white.opacity(0.25)],
                startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: style.metallic ? 5 : 2)
            outline.inset(by: 7).stroke(style.metallic ? .white.opacity(0.3) : .white.opacity(0.18), lineWidth: 1)
            if style == .aluminum || style == .classicInstrument {
                Canvas { context, size in
                    var lines = Path()
                    for y in stride(from: 0.0, to: size.height, by: 2) {
                        lines.move(to: CGPoint(x: 0, y: y))
                        lines.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(lines, with: .color(.white.opacity(0.055)), lineWidth: 0.5)
                }.clipShape(outline)
            }
        }
        .shadow(color: style == .hudNeon ? .cyan.opacity(0.7) : .black.opacity(0.4),
                radius: style.glow + 3, y: 9)
        .padding(8)
    }

    private var frameColors: [Color] {
        switch style {
        case .aluminum, .classicInstrument:
            [Color(white: 0.75), Color(white: 0.36), Color(white: 0.6), Color(white: 0.22)]
        case .monochrome: [Color(white: 0.08), Color(white: 0.3), .black]
        case .ultraMinimal: [.white, Color(white: 0.92), .white]
        case .darkPro, .spaceBlack: [Color(white: 0.12), .black, Color(white: 0.06)]
        case .hudNeon: [Color(red: 0.02, green: 0.12, blue: 0.17), .black]
        case .liquid: [.cyan.opacity(0.6), .blue.opacity(0.4), .cyan.opacity(0.3)]
        case .aurora: [.blue.opacity(0.8), .purple.opacity(0.6), .cyan.opacity(0.5)]
        case .depthGlass: [.white.opacity(0.4), .black.opacity(0.5), .white.opacity(0.25)]
        default: [.cyan.opacity(0.18), .purple.opacity(0.14), .white.opacity(0.15)]
        }
    }
}

private struct Meter: View {
    @ObservedObject var monitor: Monitor
    let metric: Metric
    let style: MonitorStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var value: Double? { metric.value(in: monitor.data) }
    private var tint: Color { style.tint(metric) }
    private var history: [Double?] { monitor.history[metric.rawValue] }

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: faceColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(9)
            if style == .depthGlass {
                ForEach(0..<3) { index in
                    Circle().strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.65), tint.opacity(0.4), .clear, .white.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        .padding(CGFloat(index) * 5 + 1)
                        .shadow(color: tint.opacity(0.45), radius: 4)
                }
            }
            if style != .frosted {
                Circle().strokeBorder(AngularGradient(
                    colors: style.metallic ? [.white, .gray, .black, .white, .gray, .white] :
                        [.white.opacity(0.7), tint.opacity(0.25), .white.opacity(style == .pureGlass ? 0.4 : 0.05), .white.opacity(0.5)],
                    center: .center), lineWidth: style.metallic ? 5 : 2).padding(6)
            }
            Circle().strokeBorder(tint.opacity(style == .spaceBlack ? 0.5 : 0.22), lineWidth: 1).padding(14)
            GaugeScale(value: value, classic: style == .classicInstrument, segmented: style == .hudNeon, tint: tint)
                .padding(17).shadow(color: tint.opacity(0.8), radius: style.glow)
            if style.fluid {
                TimelineView(.animation(minimumInterval: 1.0 / 24,
                                        paused: reduceMotion || !monitor.visible)) { timeline in
                    LiquidWaves(phase: reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate,
                                level: value, tint: tint)
                }
                .frame(width: 200, height: 65).offset(y: 58)
                .frame(width: 261, height: 261).clipShape(Circle().inset(by: 14))
                .allowsHitTesting(false)
            }
            if style == .classicInstrument {
                VStack(spacing: 0) {
                    Text(metric.title).font(.system(size: 17, weight: .medium))
                    Spacer().frame(height: 94)
                    Text(percent(value)).font(.system(size: 29, weight: .medium, design: .rounded)).monospacedDigit()
                }.offset(y: 10)
            } else {
                VStack(spacing: 3) {
                    Text(metric.title).font(.system(size: 17, weight: .medium))
                    Text(percent(value)).font(.system(size: 39, weight: .semibold, design: .rounded))
                        .monospacedDigit().contentTransition(.numericText())
                        .shadow(color: tint.opacity(style.glow > 2 ? 0.6 : 0), radius: 7)
                    if style == .spaceBlack {
                        Spacer().frame(height: 31)
                    } else if !style.fluid {
                        HistoryChart(values: history, tint: tint, bars: style == .aluminum || style == .darkPro || style == .ultraMinimal)
                            .frame(height: 25).padding(.top, 6)
                    } else {
                        Spacer().frame(height: 31)
                    }
                    if style == .spaceBlack {
                        Spacer().frame(height: 12)
                    } else if metric == .cpu {
                        HistoryChart(values: monitor.data.cores.map(Optional.some), tint: tint, bars: true).frame(height: 12)
                            .help("CPUコア別の現在の使用率")
                    } else {
                        HistoryChart(values: Array(history.suffix(16)), tint: tint, bars: true).frame(height: 12)
                            .help(metric == .gpu ? "GPU全体の直近16サンプル" : "メモリ使用率の直近16サンプル")
                    }
                }
                .frame(width: 157).offset(y: 2)
            }
        }
        .frame(width: 261, height: 261)
        .foregroundStyle(style.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.title)使用率 \(percent(value))")
        .help(metric == .gpu ? "GPU全体の実測値。物理コア別の使用率はこのMacでは取得できません。" : metric.title)
    }

    private var faceColors: [Color] {
        if style.light { return [.white, Color(white: 0.93)] }
        if style == .frosted { return [tint.opacity(0.13), .white.opacity(0.06)] }
        if style == .liquid { return [tint.opacity(0.4), Color(red: 0.03, green: 0.09, blue: 0.24)] }
        if style == .aurora { return [.blue.opacity(0.35), tint.opacity(0.35), .black.opacity(0.8)] }
        if style == .pureGlass { return [tint.opacity(0.2), Color(red: 0.08, green: 0.13, blue: 0.24).opacity(0.8)] }
        return [Color(white: 0.065), Color(white: 0.015), tint.opacity(style == .spaceBlack ? 0.03 : 0.10)]
    }
}

private struct GaugeScale: View, Animatable {
    var progress: Double
    let available: Bool
    let classic: Bool
    let segmented: Bool
    let tint: Color
    init(value: Double?, classic: Bool, segmented: Bool, tint: Color) {
        progress = (value ?? 0) / 100
        available = value != nil
        self.classic = classic
        self.segmented = segmented
        self.tint = tint
    }
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 - 5
            let start = 150.0
            let sweep = 240.0
            func point(_ fraction: Double, _ distance: CGFloat) -> CGPoint {
                let angle = (start + sweep * fraction) * .pi / 180
                return CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            }
            func arc(_ from: Double, _ to: Double) -> Path {
                Path { path in
                    path.addArc(center: center, radius: radius, startAngle: .degrees(start + sweep * from),
                                endAngle: .degrees(start + sweep * to), clockwise: false)
                }
            }
            context.stroke(arc(0, 1), with: .color(tint.opacity(0.10)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            if segmented {
                for index in 0..<50 {
                    let fraction = Double(index) / 50
                    context.stroke(arc(fraction, fraction + 0.014),
                                   with: .color(tint.opacity(fraction < progress ? 1 : 0.12)), lineWidth: 10)
                }
            } else if !classic && progress > 0 {
                context.stroke(arc(0, progress), with: .linearGradient(
                    Gradient(colors: [tint, .white.opacity(0.9), tint]),
                    startPoint: CGPoint(x: 0, y: size.height), endPoint: CGPoint(x: size.width, y: 0)),
                               style: StrokeStyle(lineWidth: 7, lineCap: .round))
            }
            if classic || segmented {
                for index in 0...50 {
                    let fraction = Double(index) / 50
                    var tick = Path()
                    tick.move(to: point(fraction, radius - 11))
                    tick.addLine(to: point(fraction, radius - (index % 5 == 0 ? 20 : 15)))
                    context.stroke(tick, with: .color(tint.opacity(0.8)), lineWidth: 1)
                }
            }
            if classic && available {
                var needle = Path()
                needle.move(to: point(progress, radius - 24))
                needle.addLine(to: point(progress, -13))
                context.stroke(needle, with: .color(.orange), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)),
                             with: .color(.gray))
            }
        }.accessibilityHidden(true)
    }
}

struct HistoryChart: View {
    let values: [Double?]
    let tint: Color
    var bars = false
    var body: some View {
        Canvas { context, size in
            var line = Path()
            var drawing = false
            let count = max(2, values.count)
            for (index, value) in values.enumerated() {
                guard let value else { drawing = false; continue }
                let height = max(0.6, (size.height - 1) * min(100, max(0, value)) / 100)
                let x = CGFloat(index) * size.width / CGFloat(count)
                if bars {
                    let rect = CGRect(x: x, y: size.height - height, width: max(1, size.width / CGFloat(count) - 2), height: height)
                    context.fill(Path(rect), with: .color(tint))
                } else {
                    let point = CGPoint(x: x, y: size.height - height)
                    if drawing { line.addLine(to: point) } else { line.move(to: point); drawing = true }
                }
            }
            context.stroke(line, with: .color(tint), lineWidth: 1.4)
        }.accessibilityHidden(true)
    }
}

struct LiquidWaves: View {
    let phase: Double
    let level: Double?
    let tint: Color
    var body: some View {
        Canvas { context, size in
            guard let level else { return }
            for layer in 0..<3 {
                let baseline = size.height * (0.72 - min(100, max(0, level)) / 250)
                var wave = Path()
                wave.move(to: CGPoint(x: 0, y: baseline + sin(phase * 1.4 + Double(layer)) * 7))
                for x in stride(from: 0.0, through: size.width, by: 2) {
                    let y = baseline + sin(x / size.width * .pi * 3 + phase * 1.4 + Double(layer)) * 7
                    wave.addLine(to: CGPoint(x: x, y: y))
                }
                var fill = wave
                fill.addLine(to: CGPoint(x: size.width, y: size.height))
                fill.addLine(to: CGPoint(x: 0, y: size.height))
                fill.closeSubpath()
                context.fill(fill, with: .linearGradient(
                    Gradient(colors: [tint.opacity(0.6 - Double(layer) * 0.14), tint.opacity(0.02)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                context.stroke(wave, with: .color(tint.opacity(0.6)), lineWidth: 0.7)
            }
        }
    }
}

private struct ConnectedOutline: InsettableShape {
    var insetAmount: CGFloat = 0
    let rectangular: Bool
    let angular: Bool
    func path(in bounds: CGRect) -> Path {
        let rect = bounds.insetBy(dx: insetAmount, dy: insetAmount)
        if rectangular { return Path(roundedRect: rect, cornerRadius: 23) }
        if angular {
            return Path { path in
                let cut: CGFloat = 35
                path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
                path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
                path.closeSubpath()
            }
        }
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        return Path { path in
            path.move(to: p(0, 0.5))
            path.addCurve(to: p(0.167, 0), control1: p(0, 0.22), control2: p(0.055, 0))
            path.addCurve(to: p(0.333, 0.075), control1: p(0.255, 0), control2: p(0.27, 0.13))
            path.addCurve(to: p(0.5, 0), control1: p(0.4, 0.075), control2: p(0.412, 0))
            path.addCurve(to: p(0.667, 0.075), control1: p(0.588, 0), control2: p(0.6, 0.075))
            path.addCurve(to: p(0.833, 0), control1: p(0.73, 0.13), control2: p(0.745, 0))
            path.addCurve(to: p(1, 0.5), control1: p(0.945, 0), control2: p(1, 0.22))
            path.addCurve(to: p(0.833, 1), control1: p(1, 0.78), control2: p(0.945, 1))
            path.addCurve(to: p(0.667, 0.925), control1: p(0.745, 1), control2: p(0.73, 0.87))
            path.addCurve(to: p(0.5, 1), control1: p(0.6, 0.925), control2: p(0.588, 1))
            path.addCurve(to: p(0.333, 0.925), control1: p(0.412, 1), control2: p(0.4, 0.925))
            path.addCurve(to: p(0.167, 1), control1: p(0.27, 0.87), control2: p(0.255, 1))
            path.addCurve(to: p(0, 0.5), control1: p(0.055, 1), control2: p(0, 0.78))
            path.closeSubpath()
        }
    }
    func inset(by amount: CGFloat) -> Self {
        Self(insetAmount: insetAmount + amount, rectangular: rectangular, angular: angular)
    }
}

struct MonitorDetails: View {
    @ObservedObject var monitor: Monitor
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                Text("GPU描画 \(percent(monitor.data.renderer)) · タイル \(percent(monitor.data.tiler))")
                    .help("GPU物理コア別の使用率カウンターはこのMacでは取得できません。")
                Spacer()
                Text("メモリ \(gigabytes(monitor.data.used)) / \(gigabytes(monitor.data.total))")
            }
            Text("圧縮 \(gigabytes(monitor.data.compressed)) · 固定 \(gigabytes(monitor.data.wired)) · キャッシュ \(gigabytes(monitor.data.cached)) · スワップ \(gigabytes(monitor.data.swap))")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 75))], spacing: 6) {
                ForEach(Array(monitor.data.cores.enumerated()), id: \.offset) { index, value in
                    Text("C\(index + 1)  \(percent(value))").font(.system(size: 10, design: .monospaced))
                }
            }
            HStack {
                Text("SSD \(gigabytes(monitor.data.diskUsed)) / \(gigabytes(monitor.data.diskTotal))")
                Spacer()
                Text("↓ \(transferRate(monitor.data.download))  ↑ \(transferRate(monitor.data.upload))")
            }
        }.font(.system(size: 10)).opacity(0.85)
    }
}

