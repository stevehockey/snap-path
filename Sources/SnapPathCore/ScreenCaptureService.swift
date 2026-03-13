import Foundation

public class ScreenCaptureService {
    public enum CaptureMode {
        case fullScreen
        case window
        case selection
    }

    public init() {}

    /// Performs a screenshot and returns the saved file path, or nil if cancelled/failed.
    public func capture(mode: CaptureMode, directory: String) -> String? {
        let filePath = generateFilePath(in: directory)

        // Ensure save directory exists
        let fm = FileManager.default
        if !fm.fileExists(atPath: directory) {
            try? fm.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = buildArguments(mode: mode, filePath: filePath)

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("SnapPath: Failed to run screencapture: \(error)")
            return nil
        }

        // File exists only if user completed the capture (not cancelled)
        if fm.fileExists(atPath: filePath) {
            return filePath
        }

        return nil
    }

    private func buildArguments(mode: CaptureMode, filePath: String) -> [String] {
        var args = ["-x"] // No capture sound
        switch mode {
        case .fullScreen:
            break
        case .window:
            args.append("-w")
        case .selection:
            args.append("-s")
        }
        args.append(filePath)
        return args
    }

    func generateFilePath(in directory: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        var filename = "Screenshot_\(timestamp).png"
        var fullPath = (directory as NSString).appendingPathComponent(filename)

        // Handle same-second collisions
        var counter = 2
        while FileManager.default.fileExists(atPath: fullPath) {
            filename = "Screenshot_\(timestamp)-\(counter).png"
            fullPath = (directory as NSString).appendingPathComponent(filename)
            counter += 1
        }

        return fullPath
    }
}
