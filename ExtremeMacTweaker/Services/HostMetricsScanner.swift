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

    return HostMetrics(
      processorName: processorName(),
      coreCount: sysctlInt("hw.physicalcpu") ?? ProcessInfo.processInfo.processorCount,
      memoryBytes: memory.total,
      usedMemoryBytes: memory.occupied,
      processCount: processCount(),
      threadCount: machThreadCount() ?? 0
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

  private static func memorySnapshot() -> (total: UInt64, occupied: UInt64) {
    let host = mach_host_self()

    var basic = host_basic_info()
    var basicCount = mach_msg_type_number_t(
      MemoryLayout<host_basic_info_data_t>.stride / MemoryLayout<integer_t>.stride
    )
    let basicStatus = withUnsafeMutablePointer(to: &basic) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(basicCount)) { rebound in
        host_info(host, HOST_BASIC_INFO, rebound, &basicCount)
      }
    }
    let total = basicStatus == KERN_SUCCESS
      ? basic.max_mem
      : ProcessInfo.processInfo.physicalMemory

    var vm = vm_statistics64()
    var vmCount = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
    )
    let vmStatus = withUnsafeMutablePointer(to: &vm) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) { rebound in
        host_statistics64(host, HOST_VM_INFO64, rebound, &vmCount)
      }
    }

    var pageSize: vm_size_t = 0
    if host_page_size(host, &pageSize) != KERN_SUCCESS || pageSize == 0 {
      pageSize = vm_page_size
    }

    guard vmStatus == KERN_SUCCESS else {
      return (total, 0)
    }

    let freePages = vm.free_count >= vm.speculative_count
      ? UInt64(vm.free_count - vm.speculative_count)
      : 0
    let reallyFreeBytes = freePages * UInt64(pageSize)
    let occupied = total > reallyFreeBytes ? total - reallyFreeBytes : 0
    return (total, occupied)
  }

  private static func processCount() -> Int {
    livePIDs().count
  }

  private static func machThreadCount() -> Int? {
    var pset = processor_set_name_t(MACH_PORT_NULL)
    var info = processor_set_load_info()
    var count = mach_msg_type_number_t(
      MemoryLayout<processor_set_load_info>.stride / MemoryLayout<natural_t>.stride
    )

    var status = processor_set_default(mach_host_self(), &pset)
    if status == KERN_SUCCESS {
      status = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
          processor_set_statistics(pset, PROCESSOR_SET_LOAD_INFO, rebound, &count)
        }
      }
    }

    if pset != MACH_PORT_NULL {
      mach_port_deallocate(mach_task_self_, pset)
    }

    guard status == KERN_SUCCESS else { return nil }
    return Int(info.thread_count)
  }

  private static func livePIDs() -> [pid_t] {
    let bufferSize = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
    guard bufferSize > 0 else { return [] }

    var pids = [pid_t](repeating: 0, count: Int(bufferSize) / MemoryLayout<pid_t>.stride)
    let written = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, bufferSize)
    guard written > 0 else { return [] }

    return pids.prefix(Int(written) / MemoryLayout<pid_t>.stride).filter { $0 > 0 }
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
