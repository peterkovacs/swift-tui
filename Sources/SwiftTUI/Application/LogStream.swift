#if canImport(OSLog)
import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "swift-tui",
    category: String(describing: #file)
)
#endif
