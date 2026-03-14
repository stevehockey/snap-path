import AppKit
import UserNotifications

public class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusBarController: StatusBarController?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Register the "Show in Finder" action on capture notifications.
        let showAction = UNNotificationAction(
            identifier: "SHOW_IN_FINDER",
            title: "Show in Finder",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "CAPTURE_COMPLETE",
            actions: [showAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        statusBarController = StatusBarController()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handles the user tapping the "Show in Finder" notification action.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "SHOW_IN_FINDER",
           let filePath = response.notification.request.content.userInfo["filePath"] as? String {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: filePath)])
        }
        completionHandler()
    }

    /// Allow notification banners to appear even while the app is in the foreground.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
