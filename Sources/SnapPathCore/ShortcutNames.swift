import KeyboardShortcuts

/// Defines the configurable global keyboard shortcut names for each capture mode.
/// These names serve as identifiers for persisting shortcut bindings via
/// KeyboardShortcuts' built-in UserDefaults integration.
extension KeyboardShortcuts.Name {
    static let captureFullScreen = Self("captureFullScreen")
    static let captureWindow     = Self("captureWindow")
    static let captureSelection  = Self("captureSelection")
}
