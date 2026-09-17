//
//  NotificationScheduler.swift
//  Osacha
//
//  Hands order updates to iOS so the phone announces them — ready for
//  pickup, out for delivery, delivered — even when the app is closed.
//  Also shows them as banners while the app is open, and opens the
//  Notifications screen when one is tapped.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationScheduler()

    /// Set at launch so a tapped banner can open the Notifications screen.
    weak var navigator: NavigationCoordinator?

    private let center = UNUserNotificationCenter.current()

    /// Becomes the notification delegate. Call once at launch.
    func start(navigator: NavigationCoordinator) {
        self.navigator = navigator
        center.delegate = self
    }

    /// Schedules a banner for each update at the time it happens. The first
    /// call asks the customer for permission; after that iOS remembers their
    /// answer, and nothing is scheduled if they said no.
    func schedule(_ updates: [AppNotification]) {
        guard !updates.isEmpty else { return }
        Task {
            guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true else { return }
            for update in updates {
                let delay = update.date.timeIntervalSinceNow
                guard delay > 0 else { continue }

                let content = UNMutableNotificationContent()
                content.title = update.kind.title
                content.body = update.message
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
                let request = UNNotificationRequest(identifier: update.id.uuidString, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show the banner even when the app is in front — otherwise iOS drops it.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            navigator?.openNotifications()
        }
    }
}
