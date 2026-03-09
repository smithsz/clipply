import SwiftUI

@main
struct ClipplyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    var clipboardManager: ClipboardManager?
    var hotkeyManager: HotkeyManager?
    var storageManager: StorageManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize managers
        storageManager = StorageManager.shared
        clipboardManager = ClipboardManager.shared
        hotkeyManager = HotkeyManager.shared
        menuBarManager = MenuBarManager.shared
        
        // Start clipboard monitoring
        clipboardManager?.startMonitoring()
        
        // Setup global hotkey
        hotkeyManager?.setupHotkey()
        
        // Check if first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            showOnboarding()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save history if needed
        if UserDefaults.standard.bool(forKey: "persistHistory") {
            storageManager?.saveHistory()
        } else if UserDefaults.standard.bool(forKey: "clearHistoryOnQuit") {
            storageManager?.clearHistory()
        }
    }
    
    private func showOnboarding() {
        let onboardingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        onboardingWindow.center()
        onboardingWindow.title = "Welcome to Clipply"
        onboardingWindow.contentView = NSHostingView(rootView: OnboardingView())
        onboardingWindow.makeKeyAndOrderFront(nil)
    }
}
