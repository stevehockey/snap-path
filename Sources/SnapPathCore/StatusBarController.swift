import AppKit
import KeyboardShortcuts
import UniformTypeIdentifiers
import UserNotifications

public class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let captureService = ScreenCaptureService()
    private let preferences = PreferencesManager()
    private let clipboard = ClipboardService()
    private var recentSubMenu: NSMenu?
    private var lastCapturedPath: String?
    private weak var showLastCaptureItem: NSMenuItem?
    private var preferencesWindowController: PreferencesWindowController?

    public override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        setupButton()
        setupMenu()
        registerGlobalShortcuts()
    }

    /// Registers global keyboard shortcut handlers for each capture mode.
    /// Shortcuts use Carbon RegisterEventHotKey internally — no Accessibility
    /// permission required. Bindings are configured by the user in Preferences.
    private func registerGlobalShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .captureFullScreen) { [weak self] in
            self?.performCapture(mode: .fullScreen)
        }
        KeyboardShortcuts.onKeyUp(for: .captureWindow) { [weak self] in
            self?.performCapture(mode: .window)
        }
        KeyboardShortcuts.onKeyUp(for: .captureSelection) { [weak self] in
            self?.performCapture(mode: .selection)
        }
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

        let copyPaths = NSMenuItem(
            title: "Copy Paths\u{2026}",
            action: #selector(copyPaths),
            keyEquivalent: "o"
        )
        copyPaths.target = self
        menu.addItem(copyPaths)

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
            keyEquivalent: ""
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

        let showLast = NSMenuItem(
            title: "Show Last Capture in Finder",
            action: #selector(showLastCaptureInFinder),
            keyEquivalent: "r"
        )
        showLast.target = self
        showLast.isEnabled = lastCapturedPath != nil
        menu.addItem(showLast)
        showLastCaptureItem = showLast

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

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
        let formatted = clipboard.formatPath(path, format: preferences.pathFormat)
        clipboard.copyToClipboard(formatted)
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
        let prefix = preferences.filenamePrefix
        let muted = !preferences.playSound
        let format = preferences.pathFormat
        let shouldAutoOpen = preferences.autoOpenPicker

        // Run capture on background thread to avoid blocking the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let filePath = self?.captureService.capture(
                mode: mode,
                directory: saveDir,
                prefix: prefix,
                muted: muted
            )

            DispatchQueue.main.async {
                guard let self = self, let path = filePath else { return }
                let formatted = self.clipboard.formatPath(path, format: format)
                self.clipboard.copyToClipboard(formatted)
                self.lastCapturedPath = path
                self.showLastCaptureItem?.isEnabled = true
                self.showNotification(path: path)

                if shouldAutoOpen {
                    self.copyPaths()
                }
            }
        }
    }

    /// Posts a capture-complete notification with the "Show in Finder" action.
    private func showNotification(path: String) {
        let filename = (path as NSString).lastPathComponent
        let content = UNMutableNotificationContent()
        content.title = "SnapPath"
        content.body = "Saved \(filename) — path copied to clipboard"
        content.sound = .default
        content.categoryIdentifier = "CAPTURE_COMPLETE"
        content.userInfo = ["filePath": path]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("SnapPath: Failed to deliver notification: \(error)")
            }
        }
    }

    /// Posts a general informational notification (no Finder action).
    private func showNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "SnapPath"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("SnapPath: Failed to deliver notification: \(error)")
            }
        }
    }

    /// Opens NSOpenPanel for multi-selecting image files, then copies
    /// all selected paths to the clipboard (one per line).
    @objc private func copyPaths() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .gif, .bmp]
        panel.message = "Select screenshots to copy paths"
        panel.prompt = "Copy Paths"
        panel.directoryURL = URL(fileURLWithPath: preferences.saveDirectory)

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            DispatchQueue.main.async {
                guard let self = self, response == .OK, !panel.urls.isEmpty else { return }
                let paths = panel.urls.map { $0.path }
                self.clipboard.copyPathsToClipboard(paths, format: self.preferences.pathFormat)
                let count = paths.count
                if count == 1 {
                    self.showNotification(path: paths[0])
                } else {
                    self.showNotification(message: "\(count) paths copied to clipboard")
                }
            }
        }
    }

    /// Opens the configured save directory in Finder via NSWorkspace.
    @objc private func openSaveFolder() {
        let url = URL(fileURLWithPath: preferences.saveDirectory)
        NSWorkspace.shared.open(url)
    }

    /// Reveals the most recently captured file in Finder.
    @objc private func showLastCaptureInFinder() {
        guard let path = lastCapturedPath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    @objc private func changeSaveDirectory() {
        preferences.promptForSaveDirectory { [weak self] in
            self?.setupMenu()
        }
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(preferences: preferences)
        }
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
