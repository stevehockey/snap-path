import AppKit

/// Describes how file paths are formatted when copied to the clipboard.
public enum PathFormat: String, CaseIterable {
    case plain    = "plain"
    case quoted   = "quoted"
    case markdown = "markdown"

    public var displayName: String {
        switch self {
        case .plain:    return "Plain"
        case .quoted:   return "Quoted"
        case .markdown: return "Markdown"
        }
    }
}

public class PreferencesManager {
    private static let saveDirectoryKey = "SaveDirectory"
    private static let pathFormatKey      = "PathFormat"
    private static let filenamePrefixKey  = "FilenamePrefix"
    private static let autoOpenPickerKey  = "AutoOpenPicker"
    private static let playSoundKey       = "PlayCaptureSound"

    private static let defaultDirectory: String = {
        NSSearchPathForDirectoriesInDomains(
            .picturesDirectory, .userDomainMask, true
        ).first ?? NSHomeDirectory() + "/Pictures"
    }()

    public init() {}

    public var saveDirectory: String {
        let dir = UserDefaults.standard.string(
            forKey: Self.saveDirectoryKey
        ) ?? Self.defaultDirectory
        return (dir as NSString).expandingTildeInPath
    }

    /// Shortened path for menu display (e.g., "~/Pictures")
    public var saveDirectoryDisplay: String {
        let full = saveDirectory
        let home = NSHomeDirectory()
        if full.hasPrefix(home) {
            return "~" + full.dropFirst(home.count)
        }
        return full
    }

    public var pathFormat: PathFormat {
        get {
            let raw = UserDefaults.standard.string(forKey: Self.pathFormatKey) ?? PathFormat.plain.rawValue
            return PathFormat(rawValue: raw) ?? .plain
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Self.pathFormatKey) }
    }

    public var filenamePrefix: String {
        get {
            let v = UserDefaults.standard.string(forKey: Self.filenamePrefixKey) ?? "Screenshot_"
            let trimmed = v.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Screenshot_" : trimmed
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespaces)
            UserDefaults.standard.set(trimmed.isEmpty ? "Screenshot_" : trimmed, forKey: Self.filenamePrefixKey)
        }
    }

    public var autoOpenPicker: Bool {
        get { UserDefaults.standard.bool(forKey: Self.autoOpenPickerKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.autoOpenPickerKey) }
    }

    public var playSound: Bool {
        get { UserDefaults.standard.bool(forKey: Self.playSoundKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.playSoundKey) }
    }

    public func promptForSaveDirectory(completion: @escaping () -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose where to save screenshots"
        panel.prompt = "Select"
        panel.directoryURL = URL(fileURLWithPath: saveDirectory)

        panel.begin { response in
            if response == .OK, let url = panel.url {
                UserDefaults.standard.set(
                    url.path,
                    forKey: Self.saveDirectoryKey
                )
            }
            completion()
        }
    }
}
