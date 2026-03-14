import AppKit

public class ClipboardService {
    public init() {}

    public func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    /// Formats a single file path for clipboard output.
    /// Currently returns the plain path. Will be wired to PathFormat preference in issue #6.
    public func formatPath(_ path: String) -> String {
        return path
    }

    /// Copies multiple file paths to the clipboard, one per line,
    /// each formatted via `formatPath(_:)`.
    public func copyPathsToClipboard(_ paths: [String]) {
        let formatted = paths.map { formatPath($0) }.joined(separator: "\n")
        copyToClipboard(formatted)
    }
}
