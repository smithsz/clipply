import Foundation
import AppKit
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let menuBarManager = MenuBarManager.shared
    
    private init() {}
    
    func setupHotkey() {
        // Check for accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility permissions not granted. Please enable in System Preferences.")
            return
        }
        
        // Get hotkey configuration from UserDefaults
        let keyCode = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        let modifiers = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
        
        // Use defaults if not set: Shift+Cmd+V
        let finalKeyCode = keyCode > 0 ? UInt32(keyCode) : UInt32(kVK_ANSI_V)
        let finalModifiers = modifiers > 0 ? UInt32(modifiers) : UInt32(shiftKey | cmdKey)
        
        registerHotkey(keyCode: finalKeyCode, modifiers: finalModifiers)
    }
    
    private func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        // Unregister existing hotkey if any
        unregisterHotkey()
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, _) -> OSStatus in
            HotkeyManager.shared.handleHotkeyPress()
            return noErr
        }, 1, &eventType, nil, &eventHandler)
        
        // Register hotkey
        var hotKeyID = EventHotKeyID(signature: OSType(0x4B455920), id: 1) // 'KEY '
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey. Status: \(status)")
        }
    }
    
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func handleHotkeyPress() {
        DispatchQueue.main.async {
            self.menuBarManager.showPopover()
        }
    }
    
    func updateHotkey(keyCode: Int, modifiers: Int) {
        UserDefaults.standard.set(keyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(modifiers, forKey: "hotkeyModifiers")
        
        registerHotkey(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
    }
    
    deinit {
        unregisterHotkey()
    }
}

// Key code constants for common keys
extension HotkeyManager {
    static let keyCodes: [String: Int] = [
        "A": kVK_ANSI_A,
        "B": kVK_ANSI_B,
        "C": kVK_ANSI_C,
        "D": kVK_ANSI_D,
        "E": kVK_ANSI_E,
        "F": kVK_ANSI_F,
        "G": kVK_ANSI_G,
        "H": kVK_ANSI_H,
        "I": kVK_ANSI_I,
        "J": kVK_ANSI_J,
        "K": kVK_ANSI_K,
        "L": kVK_ANSI_L,
        "M": kVK_ANSI_M,
        "N": kVK_ANSI_N,
        "O": kVK_ANSI_O,
        "P": kVK_ANSI_P,
        "Q": kVK_ANSI_Q,
        "R": kVK_ANSI_R,
        "S": kVK_ANSI_S,
        "T": kVK_ANSI_T,
        "U": kVK_ANSI_U,
        "V": kVK_ANSI_V,
        "W": kVK_ANSI_W,
        "X": kVK_ANSI_X,
        "Y": kVK_ANSI_Y,
        "Z": kVK_ANSI_Z
    ]
}
