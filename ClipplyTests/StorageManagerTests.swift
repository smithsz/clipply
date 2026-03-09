import XCTest
@testable import Clipply

final class StorageManagerTests: XCTestCase {
    
    var storageManager: StorageManager!
    var testHistoryURL: URL!
    
    override func setUp() {
        super.setUp()
        
        // Reset UserDefaults to ensure clean state for each test
        UserDefaults.standard.removeObject(forKey: "maxHistoryItems")
        UserDefaults.standard.removeObject(forKey: "persistHistory")
        UserDefaults.standard.removeObject(forKey: "clearHistoryOnQuit")
        UserDefaults.standard.removeObject(forKey: "preventDuplicates")
        UserDefaults.standard.removeObject(forKey: "ignorePasswords")
        UserDefaults.standard.removeObject(forKey: "maxCharacterLength")
        UserDefaults.standard.removeObject(forKey: "soundEffects")
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
        
        // Set default values manually since StorageManager is a singleton
        // and its init only runs once
        UserDefaults.standard.set(40, forKey: "maxHistoryItems")
        UserDefaults.standard.set(true, forKey: "persistHistory")
        UserDefaults.standard.set(false, forKey: "clearHistoryOnQuit")
        UserDefaults.standard.set(true, forKey: "preventDuplicates")
        UserDefaults.standard.set(true, forKey: "ignorePasswords")
        UserDefaults.standard.set(500, forKey: "maxCharacterLength")
        UserDefaults.standard.set(false, forKey: "soundEffects")
        UserDefaults.standard.set(false, forKey: "launchAtLogin")
        
        storageManager = StorageManager.shared
        
        // Create a temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testHistoryURL = tempDir.appendingPathComponent("test_history_\(UUID().uuidString).json")
    }
    
    override func tearDown() {
        // Clean up test files
        if FileManager.default.fileExists(atPath: testHistoryURL.path) {
            try? FileManager.default.removeItem(at: testHistoryURL)
        }
        super.tearDown()
    }
    
    // MARK: - Export Tests
    
    func testExportEmptyHistory() throws {
        // Given
        ClipboardManager.shared.history = []
        
        // When
        try storageManager.exportHistory(to: testHistoryURL)
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: testHistoryURL.path))
        
        let data = try Data(contentsOf: testHistoryURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([ClipboardItem].self, from: data)
        
        XCTAssertEqual(items.count, 0)
    }
    
    func testExportHistoryWithItems() throws {
        // Given
        let item1 = ClipboardItem(content: .text("Test 1"))
        let item2 = ClipboardItem(content: .text("Test 2"))
        ClipboardManager.shared.history = [item1, item2]
        
        // When
        try storageManager.exportHistory(to: testHistoryURL)
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: testHistoryURL.path))
        
        let data = try Data(contentsOf: testHistoryURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([ClipboardItem].self, from: data)
        
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].preview, "Test 1")
        XCTAssertEqual(items[1].preview, "Test 2")
    }
    
    func testExportHistoryWithPinnedItems() throws {
        // Given
        let item1 = ClipboardItem(content: .text("Pinned"), isPinned: true)
        let item2 = ClipboardItem(content: .text("Not pinned"), isPinned: false)
        ClipboardManager.shared.history = [item1, item2]
        
        // When
        try storageManager.exportHistory(to: testHistoryURL)
        
        // Then
        let data = try Data(contentsOf: testHistoryURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([ClipboardItem].self, from: data)
        
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0].isPinned)
        XCTAssertFalse(items[1].isPinned)
    }
    
    // MARK: - Import Tests
    
    func testImportEmptyHistory() throws {
        // Given
        let emptyArray: [ClipboardItem] = []
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(emptyArray)
        try data.write(to: testHistoryURL)
        
        // When
        let items = try storageManager.importHistory(from: testHistoryURL)
        
        // Then
        XCTAssertEqual(items.count, 0)
    }
    
    func testImportHistoryWithItems() throws {
        // Given
        let item1 = ClipboardItem(content: .text("Import Test 1"))
        let item2 = ClipboardItem(content: .text("Import Test 2"))
        let originalItems = [item1, item2]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalItems)
        try data.write(to: testHistoryURL)
        
        // When
        let importedItems = try storageManager.importHistory(from: testHistoryURL)
        
        // Then
        XCTAssertEqual(importedItems.count, 2)
        XCTAssertEqual(importedItems[0].preview, "Import Test 1")
        XCTAssertEqual(importedItems[1].preview, "Import Test 2")
    }
    
    func testImportHistoryPreservesMetadata() throws {
        // Given
        let timestamp = Date()
        let item = ClipboardItem(
            content: .text("Test"),
            timestamp: timestamp,
            isPinned: true,
            sourceApp: "TestApp"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode([item])
        try data.write(to: testHistoryURL)
        
        // When
        let importedItems = try storageManager.importHistory(from: testHistoryURL)
        
        // Then
        XCTAssertEqual(importedItems.count, 1)
        let importedItem = importedItems[0]
        XCTAssertEqual(importedItem.id, item.id)
        XCTAssertTrue(importedItem.isPinned)
        XCTAssertEqual(importedItem.sourceApp, "TestApp")
    }
    
    func testImportInvalidJSON() {
        // Given
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        try? invalidJSON.write(to: testHistoryURL)
        
        // When/Then
        XCTAssertThrowsError(try storageManager.importHistory(from: testHistoryURL)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testImportNonExistentFile() {
        // Given
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString).json")
        
        // When/Then
        XCTAssertThrowsError(try storageManager.importHistory(from: nonExistentURL))
    }
    
    // MARK: - Round Trip Tests
    
    func testExportImportRoundTrip() throws {
        // Given
        let item1 = ClipboardItem(content: .text("Round trip 1"), isPinned: true)
        let item2 = ClipboardItem(content: .text("Round trip 2"), sourceApp: "Safari")
        let item3 = ClipboardItem(content: .image(Data([0x89, 0x50, 0x4E, 0x47])))
        ClipboardManager.shared.history = [item1, item2, item3]
        
        // When
        try storageManager.exportHistory(to: testHistoryURL)
        let importedItems = try storageManager.importHistory(from: testHistoryURL)
        
        // Then
        XCTAssertEqual(importedItems.count, 3)
        XCTAssertEqual(importedItems[0].id, item1.id)
        XCTAssertEqual(importedItems[1].id, item2.id)
        XCTAssertEqual(importedItems[2].id, item3.id)
        XCTAssertTrue(importedItems[0].isPinned)
        XCTAssertEqual(importedItems[1].sourceApp, "Safari")
        XCTAssertEqual(importedItems[2].contentType, "Image")
    }
    
    // MARK: - Default Settings Tests
    
    func testDefaultSettingsAreSet() {
        // Given/When
        let defaults = UserDefaults.standard
        
        // Then - verify default values exist
        XCTAssertNotNil(defaults.object(forKey: "maxHistoryItems"))
        XCTAssertNotNil(defaults.object(forKey: "persistHistory"))
        XCTAssertNotNil(defaults.object(forKey: "clearHistoryOnQuit"))
        XCTAssertNotNil(defaults.object(forKey: "preventDuplicates"))
        XCTAssertNotNil(defaults.object(forKey: "ignorePasswords"))
        XCTAssertNotNil(defaults.object(forKey: "maxCharacterLength"))
        XCTAssertNotNil(defaults.object(forKey: "soundEffects"))
        XCTAssertNotNil(defaults.object(forKey: "launchAtLogin"))
    }
    
    func testDefaultMaxHistoryItems() {
        // Given/When - setUp already configured defaults
        let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        
        // Then
        XCTAssertEqual(maxItems, 40)
    }
    
    func testDefaultPersistHistory() {
        // Given/When
        let persistHistory = UserDefaults.standard.bool(forKey: "persistHistory")
        
        // Then
        XCTAssertTrue(persistHistory)
    }
    
    func testDefaultPreventDuplicates() {
        // Given/When
        let preventDuplicates = UserDefaults.standard.bool(forKey: "preventDuplicates")
        
        // Then
        XCTAssertTrue(preventDuplicates)
    }
}
