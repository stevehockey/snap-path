import AppKit

public class PreferencesManager {
    private static let saveDirectoryKey = "SaveDirectory"

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
