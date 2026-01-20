import Foundation

/// Log levels for categorizing log messages
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

/// Simple console-based logger for DeskModes
/// Outputs formatted log messages to stdout with timestamps and log levels
final class Logger {

    /// Shared singleton instance
    static let shared = Logger()

    /// Date formatter for timestamps
    private let dateFormatter: DateFormatter

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    /// Logs a message with the specified log level
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level (default: .info)
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] \(message)")
    }

    /// Logs a debug message
    /// - Parameter message: The debug message to log
    func debug(_ message: String) {
        log(message, level: .debug)
    }

    /// Logs an info message
    /// - Parameter message: The info message to log
    func info(_ message: String) {
        log(message, level: .info)
    }

    /// Logs a warning message
    /// - Parameter message: The warning message to log
    func warning(_ message: String) {
        log(message, level: .warning)
    }

    /// Logs an error message
    /// - Parameter message: The error message to log
    func error(_ message: String) {
        log(message, level: .error)
    }
}
