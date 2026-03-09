import Foundation
import AppKit

enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
    case file(URL)
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .data)
            self = .text(text)
        case "image":
            let imageData = try container.decode(Data.self, forKey: .data)
            self = .image(imageData)
        case "file":
            let urlString = try container.decode(String.self, forKey: .data)
            if let url = URL(string: urlString) {
                self = .file(url)
            } else {
                throw DecodingError.dataCorruptedError(forKey: .data, in: container, debugDescription: "Invalid URL")
            }
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .data)
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .data)
        case .file(let url):
            try container.encode("file", forKey: .type)
            try container.encode(url.absoluteString, forKey: .data)
        }
    }
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ClipboardContent
    let timestamp: Date
    var isPinned: Bool
    let preview: String
    let sourceApp: String?
    
    init(
        id: UUID = UUID(),
        content: ClipboardContent,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceApp = sourceApp
        
        // Generate preview based on content type
        switch content {
        case .text(let text):
            let maxLength = UserDefaults.standard.integer(
                forKey: "maxCharacterLength"
            )
            let limit = maxLength > 0 ? maxLength : 500
            self.preview = String(text.prefix(limit))
        case .image:
            self.preview = "📷 Image"
        case .file(let url):
            self.preview = "📄 \(url.lastPathComponent)"
        }
    }
    
    var displayTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var contentType: String {
        switch content {
        case .text: return "Text"
        case .image: return "Image"
        case .file: return "File"
        }
    }
    
    func matches(searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        let lowercased = searchText.lowercased()
        return preview.lowercased().contains(lowercased) ||
               contentType.lowercased().contains(lowercased)
    }
}

extension ClipboardItem: Equatable {
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        switch (lhs.content, rhs.content) {
        case (.text(let lText), .text(let rText)):
            return lText == rText
        case (.image(let lData), .image(let rData)):
            return lData == rData
        case (.file(let lURL), .file(let rURL)):
            return lURL == rURL
        case (.text, _), (.image, _), (.file, _):
            return false
        default:
            return false
        }
    }
}
