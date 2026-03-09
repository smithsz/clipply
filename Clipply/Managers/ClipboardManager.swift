import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var history: [ClipboardItem] = []
    private var pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var timer: Timer?
    private let storageManager = StorageManager.shared
    
    private init() {
        self.changeCount = pasteboard.changeCount
        loadHistory()
    }
    
    func startMonitoring() {
        // Poll clipboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount
        
        // Get the active application
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
        
        // Check if app is excluded
        if let sourceApp = sourceApp, isExcluded(app: sourceApp) {
            return
        }
        
        // Try to get clipboard content
        if let content = getClipboardContent() {
            addToHistory(content: content, sourceApp: sourceApp)
        }
    }
    
    private func getClipboardContent() -> ClipboardContent? {
        // Check for text
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            // Check if it's a password (heuristic)
            if UserDefaults.standard.bool(forKey: "ignorePasswords") && isPotentialPassword(string) {
                return nil
            }
            return .text(string)
        }
        
        // Check for image
        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            return .image(pngData)
        }
        
        // Check for file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            return .file(url)
        }
        
        return nil
    }
    
    private func addToHistory(content: ClipboardContent, sourceApp: String?) {
        let newItem = ClipboardItem(content: content, sourceApp: sourceApp)
        
        // Check for duplicates if enabled
        if UserDefaults.standard.bool(forKey: "preventDuplicates") {
            if let lastItem = history.first, lastItem == newItem {
                return
            }
        }
        
        // Add to history
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.history.insert(newItem, at: 0)
            
            // Maintain history limit
            let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
            let limit = maxItems > 0 ? maxItems : 40
            
            // Keep pinned items and trim unpinned items
            let pinnedItems = self.history.filter { $0.isPinned }
            let unpinnedItems = self.history.filter { !$0.isPinned }
            
            if unpinnedItems.count > limit {
                self.history = pinnedItems + Array(unpinnedItems.prefix(limit))
            }
            
            // Save to storage if persistence is enabled
            if UserDefaults.standard.bool(forKey: "persistHistory") {
                self.storageManager.saveHistory()
            }
        }
    }
    
    func copyToClipboard(item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let data):
            if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        case .file(let url):
            pasteboard.writeObjects([url as NSURL])
        }
        
        // Update change count to prevent re-adding
        changeCount = pasteboard.changeCount
    }
    
    func togglePin(item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isPinned.toggle()
            
            // Move pinned items to top
            history.sort { item1, item2 in
                if item1.isPinned != item2.isPinned {
                    return item1.isPinned
                }
                return item1.timestamp > item2.timestamp
            }
            
            if UserDefaults.standard.bool(forKey: "persistHistory") {
                storageManager.saveHistory()
            }
        }
    }
    
    func deleteItem(item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        
        if UserDefaults.standard.bool(forKey: "persistHistory") {
            storageManager.saveHistory()
        }
    }
    
    func clearHistory() {
        history.removeAll { !$0.isPinned }
        
        if UserDefaults.standard.bool(forKey: "persistHistory") {
            storageManager.saveHistory()
        }
    }
    
    func clearAll() {
        history.removeAll()
        
        if UserDefaults.standard.bool(forKey: "persistHistory") {
            storageManager.saveHistory()
        }
    }
    
    private func loadHistory() {
        if UserDefaults.standard.bool(forKey: "persistHistory") {
            history = storageManager.loadHistory()
        }
    }
    
    func isExcluded(app: String) -> Bool {
        let excludedList = UserDefaults.standard.stringArray(forKey: "excludedApps") ?? []
        return excludedList.contains(app)
    }
    
    func isPotentialPassword(_ text: String) -> Bool {
        // Simple heuristic: short strings with mixed case, numbers, and symbols
        guard text.count >= 8 && text.count <= 128 else { return false }
        
        let hasUppercase = text.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = text.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSymbols = text.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
        
        // If it has 3 or more of these characteristics and no whitespace, likely a password
        let characteristics = [hasUppercase, hasLowercase, hasNumbers, hasSymbols].filter { $0 }.count
        let hasWhitespace = text.rangeOfCharacter(from: .whitespaces) != nil
        
        return characteristics >= 3 && !hasWhitespace
    }
}
