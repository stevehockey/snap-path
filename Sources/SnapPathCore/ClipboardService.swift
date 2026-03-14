import AppKit

public class ClipboardService {
    public init() {}

    public func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    /// Formats a single file path for clipboard output according to the given format.
    public func formatPath(_ path: String, format: PathFormat = .plain) -> String {
        switch format {
        case .plain:
            return path
        case .quoted:
            return "\"\(path)\""
        case .markdown:
            let name = (path as NSString).lastPathComponent
            let nameWithoutExt = (name as NSString).deletingPathExtension
            return "![\(nameWithoutExt)](\(path))"
        }
    }

    /// Copies multiple file paths to the clipboard, one per line,
    /// each formatted via `formatPath(_:format:)`.
    public func copyPathsToClipboard(_ paths: [String], format: PathFormat = .plain) {
        let formatted = paths.map { formatPath($0, format: format) }.joined(separator: "\n")
        copyToClipboard(formatted)
    }
}
