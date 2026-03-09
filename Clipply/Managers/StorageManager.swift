import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private let historyKey = "clipboardHistory"
    private let fileManager = FileManager.default
    private var historyFileURL: URL {
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Unable to access application support directory")
        }
        let appDirectory = appSupport.appendingPathComponent("Clipply", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }
        
        return appDirectory.appendingPathComponent("history.json")
    }
    
    private init() {
        setupDefaultSettings()
    }
    
    private func setupDefaultSettings() {
        let defaults = UserDefaults.standard
        
        // Set default values if not already set
        if defaults.object(forKey: "maxHistoryItems") == nil {
            defaults.set(40, forKey: "maxHistoryItems")
        }
        if defaults.object(forKey: "persistHistory") == nil {
            defaults.set(true, forKey: "persistHistory")
        }
        if defaults.object(forKey: "clearHistoryOnQuit") == nil {
            defaults.set(false, forKey: "clearHistoryOnQuit")
        }
        if defaults.object(forKey: "preventDuplicates") == nil {
            defaults.set(true, forKey: "preventDuplicates")
        }
        if defaults.object(forKey: "ignorePasswords") == nil {
            defaults.set(true, forKey: "ignorePasswords")
        }
        if defaults.object(forKey: "maxCharacterLength") == nil {
            defaults.set(500, forKey: "maxCharacterLength")
        }
        if defaults.object(forKey: "soundEffects") == nil {
            defaults.set(false, forKey: "soundEffects")
        }
        if defaults.object(forKey: "launchAtLogin") == nil {
            defaults.set(false, forKey: "launchAtLogin")
        }
    }
    
    func saveHistory() {
        let history = ClipboardManager.shared.history
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            try data.write(to: historyFileURL)
        } catch {
            print("Failed to save history: \(error.localizedDescription)")
        }
    }
    
    func loadHistory() -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let history = try decoder.decode([ClipboardItem].self, from: data)
            return history
        } catch {
            print("Failed to load history: \(error.localizedDescription)")
            return []
        }
    }
    
    func clearHistory() {
        try? fileManager.removeItem(at: historyFileURL)
    }
    
    func exportHistory(to url: URL) throws {
        let history = ClipboardManager.shared.history
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(history)
        try data.write(to: url)
    }
    
    func importHistory(from url: URL) throws -> [ClipboardItem] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ClipboardItem].self, from: data)
    }
}
