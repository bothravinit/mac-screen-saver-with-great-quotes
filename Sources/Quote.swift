import Foundation

struct Quote: Identifiable {
    let id: UUID
    let text: String
    let author: String
}

// Custom Codable to map ZenQuotes API fields ("q", "a") and generate UUID locally
extension Quote: Codable {
    enum CodingKeys: String, CodingKey {
        case text = "q"
        case author = "a"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.author = try container.decode(String.self, forKey: .author)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(author, forKey: .author)
    }
}

struct QuoteCache: Codable {
    let fetchedAt: Date
    let quotes: [Quote]
}
