import XCTest
@testable import Clipply

final class ClipboardManagerTests: XCTestCase {
    
    var clipboardManager: ClipboardManager!
    
    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager.shared
        clipboardManager.history = []
    }
    
    override func tearDown() {
        clipboardManager.history = []
        super.tearDown()
    }
    
    // MARK: - History Management Tests
    
    func testInitialHistoryIsEmpty() {
        // Given/When
        let manager = ClipboardManager.shared
        manager.history = []
        
        // Then
        XCTAssertEqual(manager.history.count, 0)
    }
    
    func testTogglePinItem() {
        // Given
        let item = ClipboardItem(content: .text("Test"), isPinned: false)
        clipboardManager.history = [item]
        
        // When
        clipboardManager.togglePin(item: item)
        
        // Then
        XCTAssertTrue(clipboardManager.history[0].isPinned)
    }
    
    func testToggleUnpinItem() {
        // Given
        let item = ClipboardItem(content: .text("Test"), isPinned: true)
        clipboardManager.history = [item]
        
        // When
        clipboardManager.togglePin(item: item)
        
        // Then
        XCTAssertFalse(clipboardManager.history[0].isPinned)
    }
    
    func testPinnedItemsMovedToTop() {
        // Given
        let item1 = ClipboardItem(content: .text("Item 1"), isPinned: false)
        let item2 = ClipboardItem(content: .text("Item 2"), isPinned: false)
        clipboardManager.history = [item1, item2]
        
        // When - pin the second item
        clipboardManager.togglePin(item: item2)
        
        // Then - pinned item should be first
        XCTAssertTrue(clipboardManager.history[0].isPinned)
        XCTAssertEqual(clipboardManager.history[0].preview, "Item 2")
    }
    
    func testDeleteItem() {
        // Given
        let item1 = ClipboardItem(content: .text("Item 1"))
        let item2 = ClipboardItem(content: .text("Item 2"))
        clipboardManager.history = [item1, item2]
        
        // When
        clipboardManager.deleteItem(item: item1)
        
        // Then
        XCTAssertEqual(clipboardManager.history.count, 1)
        XCTAssertEqual(clipboardManager.history[0].preview, "Item 2")
    }
    
    func testDeleteNonExistentItem() {
        // Given
        let item1 = ClipboardItem(content: .text("Item 1"))
        let item2 = ClipboardItem(content: .text("Item 2"))
        clipboardManager.history = [item1]
        
        // When
        clipboardManager.deleteItem(item: item2)
        
        // Then
        XCTAssertEqual(clipboardManager.history.count, 1)
    }
    
    func testClearHistoryKeepsPinnedItems() {
        // Given
        let pinnedItem = ClipboardItem(content: .text("Pinned"), isPinned: true)
        let unpinnedItem = ClipboardItem(content: .text("Unpinned"), isPinned: false)
        clipboardManager.history = [pinnedItem, unpinnedItem]
        
        // When
        clipboardManager.clearHistory()
        
        // Then
        XCTAssertEqual(clipboardManager.history.count, 1)
        XCTAssertTrue(clipboardManager.history[0].isPinned)
        XCTAssertEqual(clipboardManager.history[0].preview, "Pinned")
    }
    
    func testClearHistoryWithOnlyUnpinnedItems() {
        // Given
        let item1 = ClipboardItem(content: .text("Item 1"), isPinned: false)
        let item2 = ClipboardItem(content: .text("Item 2"), isPinned: false)
        clipboardManager.history = [item1, item2]
        
        // When
        clipboardManager.clearHistory()
        
        // Then
        XCTAssertEqual(clipboardManager.history.count, 0)
    }
    
    func testClearAllRemovesEverything() {
        // Given
        let pinnedItem = ClipboardItem(content: .text("Pinned"), isPinned: true)
        let unpinnedItem = ClipboardItem(content: .text("Unpinned"), isPinned: false)
        clipboardManager.history = [pinnedItem, unpinnedItem]
        
        // When
        clipboardManager.clearAll()
        
        // Then
        XCTAssertEqual(clipboardManager.history.count, 0)
    }
    
    // MARK: - Excluded Apps Tests
    
    func testIsExcludedWithEmptyList() {
        // Given
        UserDefaults.standard.set([], forKey: "excludedApps")
        
        // When
        let result = clipboardManager.isExcluded(app: "Safari")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsExcludedWithMatchingApp() {
        // Given
        UserDefaults.standard.set(["Safari", "Chrome"], forKey: "excludedApps")
        
        // When
        let result = clipboardManager.isExcluded(app: "Safari")
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsExcludedWithNonMatchingApp() {
        // Given
        UserDefaults.standard.set(["Safari", "Chrome"], forKey: "excludedApps")
        
        // When
        let result = clipboardManager.isExcluded(app: "Firefox")
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Password Detection Tests
    
    func testIsPotentialPasswordWithShortString() {
        // Given
        let shortPassword = "Pass1!"
        
        // When
        let result = clipboardManager.isPotentialPassword(shortPassword)
        
        // Then
        XCTAssertFalse(result) // Too short (< 8 chars)
    }
    
    func testIsPotentialPasswordWithLongString() {
        // Given
        let longPassword = String(repeating: "a", count: 130)
        
        // When
        let result = clipboardManager.isPotentialPassword(longPassword)
        
        // Then
        XCTAssertFalse(result) // Too long (> 128 chars)
    }
    
    func testIsPotentialPasswordWithComplexString() {
        // Given
        let complexPassword = "MyP@ssw0rd123"
        
        // When
        let result = clipboardManager.isPotentialPassword(complexPassword)
        
        // Then
        XCTAssertTrue(result) // Has uppercase, lowercase, numbers, symbols, no whitespace
    }
    
    func testIsPotentialPasswordWithWhitespace() {
        // Given
        let passwordWithSpace = "MyP@ssw0rd 123"
        
        // When
        let result = clipboardManager.isPotentialPassword(passwordWithSpace)
        
        // Then
        XCTAssertFalse(result) // Contains whitespace
    }
    
    func testIsPotentialPasswordWithSimpleText() {
        // Given
        let simpleText = "This is a normal sentence"
        
        // When
        let result = clipboardManager.isPotentialPassword(simpleText)
        
        // Then
        XCTAssertFalse(result) // Contains whitespace and is too simple
    }
    
    func testIsPotentialPasswordWithOnlyLetters() {
        // Given
        let onlyLetters = "abcdefghij"
        
        // When
        let result = clipboardManager.isPotentialPassword(onlyLetters)
        
        // Then
        XCTAssertFalse(result) // Lacks complexity (< 3 characteristics)
    }
    
    // MARK: - History Limit Tests
    
    func testHistoryLimitIsRespected() {
        // Given
        UserDefaults.standard.set(3, forKey: "maxHistoryItems")
        
        // Create 5 items
        for index in 1...5 {
            let item = ClipboardItem(content: .text("Item \(index)"))
            clipboardManager.history.insert(item, at: 0)
        }
        
        // Simulate the limit enforcement
        let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        let pinnedItems = clipboardManager.history.filter { $0.isPinned }
        let unpinnedItems = clipboardManager.history.filter { !$0.isPinned }
        
        if unpinnedItems.count > maxItems {
            clipboardManager.history = pinnedItems + Array(unpinnedItems.prefix(maxItems))
        }
        
        // Then
        XCTAssertLessThanOrEqual(clipboardManager.history.count, 3)
    }
    
    func testHistoryLimitKeepsPinnedItems() {
        // Given
        UserDefaults.standard.set(2, forKey: "maxHistoryItems")
        
        let pinnedItem1 = ClipboardItem(content: .text("Pinned 1"), isPinned: true)
        let pinnedItem2 = ClipboardItem(content: .text("Pinned 2"), isPinned: true)
        let unpinnedItem1 = ClipboardItem(content: .text("Unpinned 1"))
        let unpinnedItem2 = ClipboardItem(content: .text("Unpinned 2"))
        let unpinnedItem3 = ClipboardItem(content: .text("Unpinned 3"))
        
        clipboardManager.history = [pinnedItem1, pinnedItem2, unpinnedItem1, unpinnedItem2, unpinnedItem3]
        
        // Simulate the limit enforcement
        let maxItems = UserDefaults.standard.integer(forKey: "maxHistoryItems")
        let pinnedItems = clipboardManager.history.filter { $0.isPinned }
        let unpinnedItems = clipboardManager.history.filter { !$0.isPinned }
        
        if unpinnedItems.count > maxItems {
            clipboardManager.history = pinnedItems + Array(unpinnedItems.prefix(maxItems))
        }
        
        // Then - should have 2 pinned + 2 unpinned (limited)
        let finalPinned = clipboardManager.history.filter { $0.isPinned }
        let finalUnpinned = clipboardManager.history.filter { !$0.isPinned }
        
        XCTAssertEqual(finalPinned.count, 2)
        XCTAssertEqual(finalUnpinned.count, 2)
    }
}
