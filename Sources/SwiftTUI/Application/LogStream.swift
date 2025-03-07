#if canImport(OSLog)
import OSLog
import os.signpost

let osLog = OSLog(
    subsystem: "com.kovapps.swift-tui",
    category: .dynamicTracing
)
let logger = Logger()

let signpostID = OSSignpostID(
    log: osLog
)

#endif
