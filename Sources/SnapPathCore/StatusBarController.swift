import AppKit

public class StatusBarController {
    private let statusItem: NSStatusItem
    private let captureService = ScreenCaptureService()
    private let preferences = PreferencesManager()
    private let clipboard = ClipboardService()

    public init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setupButton()
        setupMenu()
    }

    private func setupButton() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "SnapPath Screenshot"
            )
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        let fullScreen = NSMenuItem(
            title: "Capture Full Screen",
            action: #selector(captureFullScreen),
            keyEquivalent: "1"
        )
        fullScreen.target = self
        menu.addItem(fullScreen)

        let window = NSMenuItem(
            title: "Capture Window",
            action: #selector(captureWindow),
            keyEquivalent: "2"
        )
        window.target = self
        menu.addItem(window)

        let selection = NSMenuItem(
            title: "Capture Selection",
            action: #selector(captureSelection),
            keyEquivalent: "3"
        )
        selection.target = self
        menu.addItem(selection)

        menu.addItem(NSMenuItem.separator())

        let dirDisplay = NSMenuItem(
            title: "Save to: \(preferences.saveDirectoryDisplay)",
            action: nil,
            keyEquivalent: ""
        )
        dirDisplay.isEnabled = false
        menu.addItem(dirDisplay)

        let changeDir = NSMenuItem(
            title: "Change Save Directory\u{2026}",
            action: #selector(changeSaveDirectory),
            keyEquivalent: ","
        )
        changeDir.target = self
        menu.addItem(changeDir)

        let openFolder = NSMenuItem(
            title: "Open Save Folder",
            action: #selector(openSaveFolder),
            keyEquivalent: "f"
        )
        openFolder.target = self
        menu.addItem(openFolder)

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: "Quit SnapPath",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func captureFullScreen() {
        performCapture(mode: .fullScreen)
    }

    @objc private func captureWindow() {
        performCapture(mode: .window)
    }

    @objc private func captureSelection() {
        performCapture(mode: .selection)
    }

    private func performCapture(mode: ScreenCaptureService.CaptureMode) {
        let saveDir = preferences.saveDirectory

        // Run capture on background thread to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let filePath = self?.captureService.capture(mode: mode, directory: saveDir)

            DispatchQueue.main.async {
                guard let self = self, let path = filePath else { return }
                self.clipboard.copyToClipboard(path)
                self.showNotification(path: path)
            }
        }
    }

    private func showNotification(path: String) {
        let filename = (path as NSString).lastPathComponent
        NSLog("SnapPath: Saved \(filename) — path copied to clipboard")
    }

    /// Opens the configured save directory in Finder via NSWorkspace.
    @objc private func openSaveFolder() {
        let url = URL(fileURLWithPath: preferences.saveDirectory)
        NSWorkspace.shared.open(url)
    }

    @objc private func changeSaveDirectory() {
        preferences.promptForSaveDirectory { [weak self] in
            self?.setupMenu()
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
