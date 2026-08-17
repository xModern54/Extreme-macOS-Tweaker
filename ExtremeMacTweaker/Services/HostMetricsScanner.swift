import Darwin
import Foundation

enum HostMetricsScanner {
  static func snapshot() async -> HostMetrics {
    await Task.detached(priority: .utility) {
      collect()
    }.value
  }

  private static func collect() -> HostMetrics {
    let activity = processAndThreadCounts()

    return HostMetrics(
      processorName: processorName(),
      coreCount: sysctlInt("hw.physicalcpu") ?? ProcessInfo.processInfo.processorCount,
      memoryBytes: ProcessInfo.processInfo.physicalMemory,
      usedMemoryBytes: usedMemoryBytes(),
      processCount: activity.processes,
      threadCount: activity.threads
    )
  }

  private static func processorName() -> String {
    if let brand = sysctlString("machdep.cpu.brand_string") {
      let cleaned = cleanedProcessorName(brand)
      if !cleaned.isEmpty {
        return cleaned
      }
    }

    #if arch(arm64)
    return "Apple Silicon"
    #else
    return "Intel"
    #endif
  }

  private static func cleanedProcessorName(_ brand: String) -> String {
    var name = brand
      .replacingOccurrences(of: "(R)", with: "")
      .replacingOccurrences(of: "(TM)", with: "")
      .replacingOccurrences(of: " CPU", with: "")

    if let clock = name.range(of: " @") {
      name = String(name[..<clock.lowerBound])
    }

    return name
      .split(separator: " ", omittingEmptySubsequences: true)
      .joined(separator: " ")
  }

  private static func usedMemoryBytes() -> UInt64 {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
    )
    let status = withUnsafeMutablePointer(to: &stats) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
        host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
      }
    }

    guard status == KERN_SUCCESS else { return 0 }

    let pageSize = UInt64(vm_page_size)
    let usedPages = UInt64(stats.internal_page_count)
      + UInt64(stats.wire_count)
      + UInt64(stats.compressor_page_count)
    return usedPages * pageSize
  }

  private static func processAndThreadCounts() -> (processes: Int, threads: Int) {
    let bufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
    guard bufferSize > 0 else { return (0, 0) }

    var pids = [pid_t](repeating: 0, count: Int(bufferSize) / MemoryLayout<pid_t>.stride)
    let written = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, bufferSize)
    guard written > 0 else { return (0, 0) }

    let livePIDs = pids.prefix(Int(written) / MemoryLayout<pid_t>.stride).filter { $0 > 0 }
    let infoSize = Int32(MemoryLayout<proc_taskinfo>.stride)
    var threads = 0

    for pid in livePIDs {
      var info = proc_taskinfo()
      let result = withUnsafeMutablePointer(to: &info) { pointer in
        proc_pidinfo(pid, PROC_PIDTASKINFO, 0, pointer, infoSize)
      }
      if result == infoSize {
        threads += Int(info.pti_threadnum)
      }
    }

    return (livePIDs.count, threads)
  }

  private static func sysctlString(_ name: String) -> String? {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }

    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }

    let value = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }

  private static func sysctlInt(_ name: String) -> Int? {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
    return Int(value)
  }
}
