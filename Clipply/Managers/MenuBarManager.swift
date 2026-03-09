import SwiftUI
import AppKit

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let clipboardManager = ClipboardManager.shared
    
    private override init() {
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set icon
            if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipply") {
                image.isTemplate = true
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: HistoryView())
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Activate the popover window
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    func showPopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover, !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func hidePopover() {
        popover?.performClose(nil)
    }
}
