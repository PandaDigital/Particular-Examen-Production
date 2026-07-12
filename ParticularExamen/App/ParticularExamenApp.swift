import SwiftUI
import UIKit

@main
struct ParticularExamenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ExamenStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    guard url.host == "record" else { return }
                    store.recordFall()
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard shortcutItem.type == "com.philreichner.ParticularExamen.record" else {
            completionHandler(false)
            return
        }
        ExamenRepository.addFall()
        completionHandler(true)
    }
}
