import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
    }
}
