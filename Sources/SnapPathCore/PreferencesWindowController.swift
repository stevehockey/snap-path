import AppKit

/// Window controller for the General Preferences panel.
/// Built programmatically (no XIBs). Presents a single-page layout
/// that will be promoted to a tabbed interface when additional panes
/// (e.g., Shortcuts) are added.
public class PreferencesWindowController: NSWindowController {
    private let preferences: PreferencesManager

    public init(preferences: PreferencesManager) {
        self.preferences = preferences
        let vc = PreferencesViewController(preferences: preferences)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnapPath Preferences"
        window.contentViewController = vc
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }
}

// MARK: - PreferencesViewController

private class PreferencesViewController: NSViewController {
    private let preferences: PreferencesManager

    init(preferences: PreferencesManager) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 280))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    // MARK: - UI Construction

    private func buildUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        // --- Path Format (#6) ---
        stack.addArrangedSubview(sectionLabel("Clipboard"))
        let formatRow = NSStackView()
        formatRow.orientation = .horizontal
        formatRow.spacing = 8
        let formatLabel = NSTextField(labelWithString: "Path format:")
        let seg = NSSegmentedControl(
            labels: PathFormat.allCases.map { $0.displayName },
            trackingMode: .selectOne,
            target: self,
            action: #selector(pathFormatChanged(_:))
        )
        seg.selectedSegment = PathFormat.allCases.firstIndex(of: preferences.pathFormat) ?? 0
        formatRow.addArrangedSubview(formatLabel)
        formatRow.addArrangedSubview(seg)
        stack.addArrangedSubview(formatRow)

        // --- Filename Prefix (#7) ---
        stack.addArrangedSubview(sectionLabel("Files"))
        let prefixRow = NSStackView()
        prefixRow.orientation = .horizontal
        prefixRow.spacing = 8
        let prefixLabel = NSTextField(labelWithString: "Filename prefix:")
        let prefixField = NSTextField()
        prefixField.stringValue = preferences.filenamePrefix
        prefixField.placeholderString = "Screenshot_"
        prefixField.widthAnchor.constraint(equalToConstant: 160).isActive = true
        prefixField.target = self
        prefixField.action = #selector(prefixChanged(_:))
        prefixRow.addArrangedSubview(prefixLabel)
        prefixRow.addArrangedSubview(prefixField)
        stack.addArrangedSubview(prefixRow)

        // --- Capture Sound (#9) ---
        stack.addArrangedSubview(sectionLabel("Capture"))
        let soundCheck = NSButton(
            checkboxWithTitle: "Play capture sound",
            target: self,
            action: #selector(soundToggled(_:))
        )
        soundCheck.state = preferences.playSound ? .on : .off
        stack.addArrangedSubview(soundCheck)

        // --- Auto-open File Picker (#8) ---
        stack.addArrangedSubview(sectionLabel("Workflow"))
        let autoOpenCheck = NSButton(
            checkboxWithTitle: "Auto-open file picker after capture",
            target: self,
            action: #selector(autoOpenToggled(_:))
        )
        autoOpenCheck.state = preferences.autoOpenPicker ? .on : .off
        stack.addArrangedSubview(autoOpenCheck)
    }

    /// Creates a styled section header label.
    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text.uppercased())
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }

    // MARK: - Actions

    @objc private func pathFormatChanged(_ sender: NSSegmentedControl) {
        let format = PathFormat.allCases[sender.selectedSegment]
        preferences.pathFormat = format
    }

    @objc private func prefixChanged(_ sender: NSTextField) {
        preferences.filenamePrefix = sender.stringValue
    }

    @objc private func soundToggled(_ sender: NSButton) {
        preferences.playSound = sender.state == .on
    }

    @objc private func autoOpenToggled(_ sender: NSButton) {
        preferences.autoOpenPicker = sender.state == .on
    }
}
