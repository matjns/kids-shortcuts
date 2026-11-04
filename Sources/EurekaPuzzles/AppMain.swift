#if os(macOS)
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = GameModel()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        // NSApp is optional. Use NSApplication.shared instead.
        let app = NSApplication.shared
        _ = app.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let process = ProcessInfo.processInfo
        process.disableSuddenTermination()
        process.disableAutomaticTermination("Eureka Puzzles saves progress when you quit.")
        NSApplication.shared.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        model.persist()
        return .terminateNow
    }
}

@main
struct EurekaPuzzlesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Eureka Puzzles", id: "eureka-puzzles") {
            RootView(model: appDelegate.model)
        }
        .defaultSize(width: 1180, height: 820)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
#else
import Glibc

@main
enum EurekaPuzzlesMain {
    static func main() {
        let message = "Eureka Puzzles runs on macOS 14 or later. See README.md.\n"
        _ = message.withCString { fputs($0, stderr) }
        exit(1)
    }
}
#endif
