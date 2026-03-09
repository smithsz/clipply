import XCTest
@testable import Clipply

final class ClipboardItemTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testTextItemInitialization() {
        // Given
        let text = "Test clipboard text"
        let content = ClipboardContent.text(text)
        
        // When
        let item = ClipboardItem(content: content)
        
        // Then
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.preview, text)
        XCTAssertEqual(item.contentType, "Text")
        XCTAssertFalse(item.isPinned)
        XCTAssertNil(item.sourceApp)
    }
    
    func testImageItemInitialization() {
        // Given
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        let content = ClipboardContent.image(imageData)
        
        // When
        let item = ClipboardItem(content: content)
        
        // Then
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.preview, "📷 Image")
        XCTAssertEqual(item.contentType, "Image")
        XCTAssertFalse(item.isPinned)
    }
    
    func testFileItemInitialization() {
        // Given
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        let content = ClipboardContent.file(fileURL)
        
        // When
        let item = ClipboardItem(content: content)
        
        // Then
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.preview, "📄 test.txt")
        XCTAssertEqual(item.contentType, "File")
        XCTAssertFalse(item.isPinned)
    }
    
    func testItemWithSourceApp() {
        // Given
        let text = "Test text"
        let content = ClipboardContent.text(text)
        let sourceApp = "Safari"
        
        // When
        let item = ClipboardItem(content: content, sourceApp: sourceApp)
        
        // Then
        XCTAssertEqual(item.sourceApp, sourceApp)
    }
    
    func testPinnedItemInitialization() {
        // Given
        let text = "Pinned text"
        let content = ClipboardContent.text(text)
        
        // When
        let item = ClipboardItem(content: content, isPinned: true)
        
        // Then
        XCTAssertTrue(item.isPinned)
    }
    
    // MARK: - Preview Tests
    
    func testLongTextPreviewTruncation() {
        // Given
        let longText = String(repeating: "a", count: 1000)
        let content = ClipboardContent.text(longText)
        
        // When
        let item = ClipboardItem(content: content)
        
        // Then
        XCTAssertLessThanOrEqual(item.preview.count, 500)
    }
    
    // MARK: - Search Tests
    
    func testMatchesSearchText() {
        // Given
        let text = "Hello World"
        let content = ClipboardContent.text(text)
        let item = ClipboardItem(content: content)
        
        // When/Then
        XCTAssertTrue(item.matches(searchText: "hello"))
        XCTAssertTrue(item.matches(searchText: "world"))
        XCTAssertTrue(item.matches(searchText: "HELLO"))
        XCTAssertFalse(item.matches(searchText: "goodbye"))
    }
    
    func testMatchesEmptySearchText() {
        // Given
        let text = "Test"
        let content = ClipboardContent.text(text)
        let item = ClipboardItem(content: content)
        
        // When/Then
        XCTAssertTrue(item.matches(searchText: ""))
    }
    
    func testMatchesContentType() {
        // Given
        let text = "Test"
        let content = ClipboardContent.text(text)
        let item = ClipboardItem(content: content)
        
        // When/Then
        XCTAssertTrue(item.matches(searchText: "text"))
        XCTAssertTrue(item.matches(searchText: "TEXT"))
    }
    
    // MARK: - Equality Tests
    
    func testTextItemsEquality() {
        // Given
        let text = "Same text"
        let content1 = ClipboardContent.text(text)
        let content2 = ClipboardContent.text(text)
        let item1 = ClipboardItem(content: content1)
        let item2 = ClipboardItem(content: content2)
        
        // When/Then
        XCTAssertEqual(item1, item2)
    }
    
    func testTextItemsInequality() {
        // Given
        let content1 = ClipboardContent.text("Text 1")
        let content2 = ClipboardContent.text("Text 2")
        let item1 = ClipboardItem(content: content1)
        let item2 = ClipboardItem(content: content2)
        
        // When/Then
        XCTAssertNotEqual(item1, item2)
    }
    
    func testImageItemsEquality() {
        // Given
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let content1 = ClipboardContent.image(imageData)
        let content2 = ClipboardContent.image(imageData)
        let item1 = ClipboardItem(content: content1)
        let item2 = ClipboardItem(content: content2)
        
        // When/Then
        XCTAssertEqual(item1, item2)
    }
    
    func testFileItemsEquality() {
        // Given
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        let content1 = ClipboardContent.file(fileURL)
        let content2 = ClipboardContent.file(fileURL)
        let item1 = ClipboardItem(content: content1)
        let item2 = ClipboardItem(content: content2)
        
        // When/Then
        XCTAssertEqual(item1, item2)
    }
    
    func testDifferentContentTypesInequality() {
        // Given
        let textContent = ClipboardContent.text("Test")
        let imageContent = ClipboardContent.image(Data([0x89, 0x50, 0x4E, 0x47]))
        let item1 = ClipboardItem(content: textContent)
        let item2 = ClipboardItem(content: imageContent)
        
        // When/Then
        XCTAssertNotEqual(item1, item2)
    }
    
    // MARK: - Codable Tests
    
    func testTextItemCodable() throws {
        // Given
        let text = "Test text"
        let content = ClipboardContent.text(text)
        let item = ClipboardItem(content: content, sourceApp: "TestApp")
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(ClipboardItem.self, from: data)
        
        // Then
        XCTAssertEqual(item.id, decodedItem.id)
        XCTAssertEqual(item.preview, decodedItem.preview)
        XCTAssertEqual(item.contentType, decodedItem.contentType)
        XCTAssertEqual(item.isPinned, decodedItem.isPinned)
        XCTAssertEqual(item.sourceApp, decodedItem.sourceApp)
    }
    
    func testImageItemCodable() throws {
        // Given
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let content = ClipboardContent.image(imageData)
        let item = ClipboardItem(content: content)
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(ClipboardItem.self, from: data)
        
        // Then
        XCTAssertEqual(item.id, decodedItem.id)
        XCTAssertEqual(item.contentType, decodedItem.contentType)
    }
    
    func testFileItemCodable() throws {
        // Given
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        let content = ClipboardContent.file(fileURL)
        let item = ClipboardItem(content: content)
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(ClipboardItem.self, from: data)
        
        // Then
        XCTAssertEqual(item.id, decodedItem.id)
        XCTAssertEqual(item.contentType, decodedItem.contentType)
    }
}
