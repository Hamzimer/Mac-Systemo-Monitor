import Foundation

if CommandLine.arguments.contains("--sample") {
    let sensors = Sensors()
    _ = sensors.sample()
    for _ in 1...3 {
        Thread.sleep(forTimeInterval: 1)
        let data = sensors.sample()
        print("CPU \(data.cpu ?? -1)% | cores \(data.cores.map { Int($0.rounded()) }) | GPU \(data.gpu ?? -1)% | renderer \(data.renderer ?? -1)% | tiler \(data.tiler ?? -1)% | GPU cores \(data.gpuCores ?? -1) | RAM \(data.used ?? 0)/\(data.total) | swap \(data.swap ?? 0)")
    }
} else {
    MainActor.assumeIsolated { runMonitorApp() }
}
