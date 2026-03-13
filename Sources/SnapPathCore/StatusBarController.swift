import AppKit

public class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let captureService = ScreenCaptureService()
    private let preferences = PreferencesManager()
    private let clipboard = ClipboardService()
    private var recentSubMenu: NSMenu?

    public override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
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

        let recentItem = NSMenuItem(title: "Recent", action: nil, keyEquivalent: "")
        let recentMenu = NSMenu()
        recentMenu.addItem(NSMenuItem(title: "No recent captures", action: nil, keyEquivalent: ""))
        recentMenu.item(at: 0)?.isEnabled = false
        recentItem.submenu = recentMenu
        recentSubMenu = recentMenu
        menu.addItem(recentItem)

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

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: "Quit SnapPath",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    public func menuWillOpen(_ menu: NSMenu) {
        refreshRecentCaptures()
    }

    private func refreshRecentCaptures() {
        guard let recentMenu = recentSubMenu else { return }
        recentMenu.removeAllItems()

        let directory = preferences.saveDirectory
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: .skipsHiddenFiles
        ) else {
            let empty = NSMenuItem(title: "No recent captures", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            recentMenu.addItem(empty)
            return
        }

        let images = contents
            .filter { ["png", "jpg", "jpeg", "tiff", "gif"].contains($0.pathExtension.lowercased()) }
            .compactMap { url -> (URL, Date)? in
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                return date.map { (url, $0) }
            }
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }

        guard !images.isEmpty else {
            let empty = NSMenuItem(title: "No recent captures", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            recentMenu.addItem(empty)
            return
        }

        for url in images {
            let item = NSMenuItem(
                title: url.lastPathComponent,
                action: #selector(copyRecentPath(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = url.path
            recentMenu.addItem(item)
        }
    }

    @objc private func copyRecentPath(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        clipboard.copyToClipboard(path)
        showNotification(path: path)
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

    @objc private func changeSaveDirectory() {
        preferences.promptForSaveDirectory { [weak self] in
            self?.setupMenu()
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
