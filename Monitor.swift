import SwiftUI

enum Metric: Int, CaseIterable, Identifiable {
    case cpu, gpu, memory, renderer, tiler
    var id: Self { self }
    static let primary: [Self] = [.cpu, .gpu, .memory]
    var title: String {
        switch self {
        case .cpu: "CPU"
        case .gpu: "GPU"
        case .memory: "MEM"
        case .renderer: "描画"
        case .tiler: "タイル"
        }
    }
    var color: Color {
        switch self {
        case .cpu: .cyan
        case .gpu, .renderer: .purple
        case .memory, .tiler: .green
        }
    }
    func value(in data: Readings) -> Double? {
        switch self {
        case .cpu: data.cpu
        case .gpu: data.gpu
        case .memory: data.ram
        case .renderer: data.renderer
        case .tiler: data.tiler
        }
    }
}

@MainActor
final class Monitor: ObservableObject {
    @Published private(set) var data = Readings()
    @Published private(set) var history = Array(repeating: [Double?](), count: Metric.allCases.count)
    @Published var visible = true
    private let sensors = Sensors()

    init(data: Readings = Readings()) {
        self.data = data
    }

    func refresh() {
        data = sensors.sample()
        for metric in Metric.allCases {
            history[metric.rawValue].append(metric.value(in: data))
            if history[metric.rawValue].count > 60 {
                history[metric.rawValue].removeFirst()
            }
        }
    }
}

func percent(_ value: Double?) -> String {
    value.map { String(format: "%.0f%%", $0) } ?? "—"
}

func gigabytes(_ value: UInt64?) -> String {
    value.map { String(format: "%.1f GB", Double($0) / 1_073_741_824) } ?? "—"
}

func transferRate(_ value: Double?) -> String {
    guard let value else { return "—" }
    return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .decimal) + "/s"
}
