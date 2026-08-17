import Darwin
import Foundation

enum HostMetricsScanner {
  static func snapshot() async -> HostMetrics {
    await Task.detached(priority: .utility) {
      collect()
    }.value
  }

  private static func collect() -> HostMetrics {
    let memory = memorySnapshot()
    let tasks = taskCounts()

    return HostMetrics(
      processorName: processorName(),
      coreCount: sysctlInt("hw.physicalcpu") ?? ProcessInfo.processInfo.processorCount,
      memoryBytes: memory.total,
      usedMemoryBytes: memory.used,
      processCount: tasks.processes,
      threadCount: tasks.threads
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

  private static func memorySnapshot() -> (total: UInt64, used: UInt64) {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
    )
    let result = withUnsafeMutablePointer(to: &stats) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
        host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
      }
    }

    let total = ProcessInfo.processInfo.physicalMemory
    guard result == KERN_SUCCESS else {
      return (total, 0)
    }

    var pageSize: vm_size_t = 0
    guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS, pageSize > 0 else {
      return (total, 0)
    }

    let usedPages = UInt64(stats.active_count)
      + UInt64(stats.wire_count)
      + UInt64(stats.compressor_page_count)
    let usedBytes = min(usedPages * UInt64(pageSize), total)
    return (total, usedBytes)
  }

  private static func taskCounts() -> (processes: Int, threads: Int) {
    let requiredBytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
    guard requiredBytes > 0 else { return (0, 0) }

    var pids = [pid_t](repeating: 0, count: Int(requiredBytes) / MemoryLayout<pid_t>.stride)
    let writtenBytes = pids.withUnsafeMutableBytes { buffer in
      proc_listpids(UInt32(PROC_ALL_PIDS), 0, buffer.baseAddress, Int32(buffer.count))
    }
    guard writtenBytes > 0 else { return (0, 0) }

    let count = min(Int(writtenBytes) / MemoryLayout<pid_t>.stride, pids.count)
    var processes = 0
    var threads = 0
    let infoSize = MemoryLayout<proc_taskinfo>.stride

    for pid in pids.prefix(count) where pid > 0 {
      var info = proc_taskinfo()
      let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: CChar.self, capacity: infoSize) { rebound in
          proc_pidinfo(pid, PROC_PIDTASKINFO, 0, rebound, Int32(infoSize))
        }
      }
      guard result == infoSize else { continue }
      processes += 1
      threads += Int(info.pti_threadnum)
    }

    return (processes, threads)
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
