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

    func testCopyToClipboard() {
        let clipboard = ClipboardService()
        let testPath = "/tmp/Screenshot_test_\(UUID().uuidString).png"

        clipboard.copyToClipboard(testPath)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, testPath)
    }
}
