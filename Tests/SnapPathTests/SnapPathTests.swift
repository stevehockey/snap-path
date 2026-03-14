import XCTest
@testable import SnapPathCore

final class SnapPathTests: XCTestCase {

    // MARK: - ScreenCaptureService

    func testFilePathContainsTimestamp() {
        let service = ScreenCaptureService()
        let path = service.generateFilePath(in: "/tmp")

        XCTAssertTrue(path.hasPrefix("/tmp/Screenshot_"))
        XCTAssertTrue(path.hasSuffix(".png"))
    }

    func testFilePathCollisionHandling() throws {
        let dir = NSTemporaryDirectory() + "snappath-test-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let service = ScreenCaptureService()
        let first = service.generateFilePath(in: dir)

        // Create the file so the next call detects a collision
        FileManager.default.createFile(atPath: first, contents: Data())

        let second = service.generateFilePath(in: dir)
        XCTAssertNotEqual(first, second)
        XCTAssertTrue(second.contains("-2.png"))
    }

    // MARK: - PreferencesManager

    func testDefaultSaveDirectoryIsPictures() {
        let prefs = PreferencesManager()
        let dir = prefs.saveDirectory
        XCTAssertTrue(dir.hasSuffix("/Pictures"), "Default should be ~/Pictures, got: \(dir)")
    }

    func testSaveDirectoryDisplayUsesTilde() {
        let prefs = PreferencesManager()
        let display = prefs.saveDirectoryDisplay
        XCTAssertTrue(display.hasPrefix("~"), "Display should start with ~, got: \(display)")
    }

    // MARK: - ClipboardService

    /// Helper: checks whether NSPasteboard is functional in this environment.
    /// Headless test runners (swift test without a GUI session) return nil for all reads.
    private func pasteboardIsAvailable() -> Bool {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("__probe__", forType: .string)
        let ok = pb.string(forType: .string) == "__probe__"
        pb.clearContents()
        return ok
    }

    func testCopyToClipboard() throws {
        try XCTSkipUnless(pasteboardIsAvailable(), "NSPasteboard unavailable in headless environment")
        let clipboard = ClipboardService()
        let testPath = "/tmp/Screenshot_test_\(UUID().uuidString).png"

        clipboard.copyToClipboard(testPath)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, testPath)
    }

    func testFormatPathReturnsPlainPath() {
        let clipboard = ClipboardService()
        let path = "/Users/test/Pictures/Screenshot_2026-03-13.png"
        XCTAssertEqual(clipboard.formatPath(path), path)
    }

    func testFormatPathQuoted() {
        let clipboard = ClipboardService()
        let path = "/Users/test/Pictures/Screenshot_2026-03-13.png"
        XCTAssertEqual(clipboard.formatPath(path, format: .quoted), "\"\(path)\"")
    }

    func testFormatPathMarkdown() {
        let clipboard = ClipboardService()
        let path = "/Users/test/Pictures/Screenshot_2026-03-13.png"
        let expected = "![Screenshot_2026-03-13](\(path))"
        XCTAssertEqual(clipboard.formatPath(path, format: .markdown), expected)
    }

    // MARK: - ScreenCaptureService (prefix)

    func testFilePathUsesCustomPrefix() {
        let service = ScreenCaptureService()
        let path = service.generateFilePath(in: "/tmp", prefix: "Snap_")
        XCTAssertTrue(path.hasPrefix("/tmp/Snap_"), "Expected custom prefix, got: \(path)")
        XCTAssertTrue(path.hasSuffix(".png"))
    }

    // MARK: - PreferencesManager (new properties)

    func testDefaultPathFormatIsPlain() {
        let prefs = PreferencesManager()
        // Reset to ensure default
        UserDefaults.standard.removeObject(forKey: "PathFormat")
        XCTAssertEqual(prefs.pathFormat, .plain)
    }

    func testDefaultFilenamePrefix() {
        let prefs = PreferencesManager()
        UserDefaults.standard.removeObject(forKey: "FilenamePrefix")
        XCTAssertEqual(prefs.filenamePrefix, "Screenshot_")
    }

    func testEmptyFilenamePrefixFallsBackToDefault() {
        let prefs = PreferencesManager()
        prefs.filenamePrefix = "   "
        XCTAssertEqual(prefs.filenamePrefix, "Screenshot_")
        // Clean up
        UserDefaults.standard.removeObject(forKey: "FilenamePrefix")
    }

    func testDefaultAutoOpenPickerIsFalse() {
        let prefs = PreferencesManager()
        UserDefaults.standard.removeObject(forKey: "AutoOpenPicker")
        XCTAssertFalse(prefs.autoOpenPicker)
    }

    func testDefaultPlaySoundIsFalse() {
        let prefs = PreferencesManager()
        UserDefaults.standard.removeObject(forKey: "PlayCaptureSound")
        XCTAssertFalse(prefs.playSound)
    }

    func testCopyPathsToClipboardSinglePath() throws {
        try XCTSkipUnless(pasteboardIsAvailable(), "NSPasteboard unavailable in headless environment")
        let clipboard = ClipboardService()
        let path = "/tmp/single_\(UUID().uuidString).png"

        clipboard.copyPathsToClipboard([path])

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, path)
    }

    func testCopyPathsToClipboardMultiplePaths() throws {
        try XCTSkipUnless(pasteboardIsAvailable(), "NSPasteboard unavailable in headless environment")
        let clipboard = ClipboardService()
        let paths = [
            "/tmp/a_\(UUID().uuidString).png",
            "/tmp/b_\(UUID().uuidString).png",
            "/tmp/c_\(UUID().uuidString).png"
        ]

        clipboard.copyPathsToClipboard(paths)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, paths.joined(separator: "\n"))
    }
}
