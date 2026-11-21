import Darwin
import Foundation
import IOKit

struct Readings: Sendable {
    var cores: [Double] = []
    var cpu: Double? { cores.isEmpty ? nil : cores.reduce(0, +) / Double(cores.count) }
    var gpu: Double?
    var renderer: Double?
    var tiler: Double?
    var gpuCores: Int?
    var applications: UInt64?
    var wired: UInt64?
    var compressed: UInt64?
    var cached: UInt64?
    var used: UInt64?
    var total = ProcessInfo.processInfo.physicalMemory
    var swap: UInt64?
    var diskTotal: UInt64?
    var diskUsed: UInt64?
    var download: Double?
    var upload: Double?
    var ram: Double? { used.map { min(100, Double($0) / Double(total) * 100) } }
}

final class Sensors {
    private var previousTicks: [UInt32] = []
    private let host = mach_host_self()
    private var lastNetwork: (Date, UInt64, UInt64)?
    private lazy var gpuCores: Int? = {
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        guard root != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(root) }
        let options = IOOptionBits(kIORegistryIterateRecursively)
        return (IORegistryEntrySearchCFProperty(root, kIOServicePlane, "gpu-core-count" as CFString, kCFAllocatorDefault, options) as? NSNumber)?.intValue
    }()

    deinit { mach_port_deallocate(mach_task_self_, host) }

    func sample() -> Readings {
        var result = Readings()
        result.cores = cpuCores()
        result.gpuCores = gpuCores
        if let gpu = gpuStatistics() {
            result.gpu = percentage(gpu["Device Utilization %"])
            result.renderer = percentage(gpu["Renderer Utilization %"])
            result.tiler = percentage(gpu["Tiler Utilization %"])
        }

        var vm = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &vm) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        if status == KERN_SUCCESS {
            let occupied = UInt64(vm.internal_page_count) + UInt64(vm.wire_count) + UInt64(vm.compressor_page_count)
            let purgeable = min(UInt64(vm.internal_page_count), UInt64(vm.purgeable_count))
            let page = UInt64(vm_kernel_page_size)
            result.used = (occupied - purgeable) * page
            result.applications = (UInt64(vm.internal_page_count) - min(UInt64(vm.internal_page_count), purgeable)) * page
            result.wired = UInt64(vm.wire_count) * page
            result.compressed = UInt64(vm.compressor_page_count) * page
            result.cached = min(UInt64(vm.external_page_count) * page, result.total - min(result.total, result.used ?? 0))
        }
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        if sysctlbyname("vm.swapusage", &swap, &size, nil, 0) == 0 {
            result.swap = swap.xsu_used
        }
        if let storage = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = storage[.systemSize] as? NSNumber,
           let free = storage[.systemFreeSize] as? NSNumber {
            result.diskTotal = total.uint64Value
            result.diskUsed = total.uint64Value - min(total.uint64Value, free.uint64Value)
        }
        let now = Date()
        if let counters = networkCounters() {
            if let previous = lastNetwork {
                let elapsed = now.timeIntervalSince(previous.0)
                if elapsed > 0, counters.0 >= previous.1, counters.1 >= previous.2 {
                    result.download = Double(counters.0 - previous.1) / elapsed
                    result.upload = Double(counters.1 - previous.2) / elapsed
                }
            }
            lastNetwork = (now, counters.0, counters.1)
        } else {
            lastNetwork = nil
        }
        return result
    }

    private func networkCounters() -> (UInt64, UInt64)? {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0 else { return nil }
        defer { freeifaddrs(addresses) }
        var current = addresses
        var received: UInt64 = 0
        var sent: UInt64 = 0
        while let entry = current {
            let interface = entry.pointee
            if interface.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               interface.ifa_flags & UInt32(IFF_LOOPBACK) == 0,
               interface.ifa_flags & UInt32(IFF_UP) != 0,
               let bytes = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                received += UInt64(bytes.pointee.ifi_ibytes)
                sent += UInt64(bytes.pointee.ifi_obytes)
            }
            current = interface.ifa_next
        }
        return (received, sent)
    }

    private func cpuCores() -> [Double] {
        var coreCount: natural_t = 0
        var infoCount: mach_msg_type_number_t = 0
        var info: processor_info_array_t?
        guard host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &coreCount, &info, &infoCount) == KERN_SUCCESS,
              let info else { previousTicks = []; return [] }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
        }
        let ticks = UnsafeBufferPointer(start: info, count: Int(infoCount)).map { UInt32(bitPattern: $0) }
        let previous = previousTicks
        previousTicks = ticks
        let stride = Int(CPU_STATE_MAX)
        guard ticks.count == previous.count, ticks.count >= Int(coreCount) * stride else { return [] }
        return (0..<Int(coreCount)).map { core in
            let offset = core * stride
            let delta = (0..<stride).map { Double(ticks[offset + $0] &- previous[offset + $0]) }
            let total = delta.reduce(0, +)
            return total > 0 ? 100 * (1 - delta[Int(CPU_STATE_IDLE)] / total) : 0
        }
    }

    private func gpuStatistics() -> [String: NSNumber]? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            defer { IOObjectRelease(device) }
            if let value = IORegistryEntryCreateCFProperty(device, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0),
               let stats = value.takeRetainedValue() as? [String: NSNumber],
               ["Device Utilization %", "Renderer Utilization %", "Tiler Utilization %"].contains(where: { percentage(stats[$0]) != nil }) {
                return stats
            }
        }
        return nil
    }

    private func percentage(_ value: NSNumber?) -> Double? {
        guard let value = value?.doubleValue, (0...100).contains(value) else { return nil }
        return value
    }
}
