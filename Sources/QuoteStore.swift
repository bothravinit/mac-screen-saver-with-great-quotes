import Foundation
import os

@MainActor
final class QuoteStore: ObservableObject {
    @Published private(set) var currentQuote: Quote = fallbackQuotes[0]

    private var quotes: [Quote] = []
    private var shuffledIndices: [Int] = []
    private var currentIndex: Int = 0

    private let cacheURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("MotivationalScreenSaver")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("quotes.json")
    }()

    private let apiURL = URL(string: "https://zenquotes.io/api/quotes")!
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    private let logger = Logger(subsystem: "com.vinitbothra.MotivationalScreenSaver", category: "QuoteStore")

    func load() {
        if let cache = loadCache(), !isStale(cache) {
            setQuotes(cache.quotes)
        } else {
            // Use cache or fallback immediately; refresh in background
            if let cache = loadCache() {
                setQuotes(cache.quotes)
            } else {
                setQuotes(fallbackQuotes)
            }
            Task { await fetchAndCache() }
        }
    }

    func advance() {
        guard !quotes.isEmpty else { return }
        currentIndex += 1
        if currentIndex >= shuffledIndices.count {
            reshuffleIndices()
        }
        currentQuote = quotes[shuffledIndices[currentIndex]]
    }

    // MARK: - Private

    private func setQuotes(_ newQuotes: [Quote]) {
        quotes = newQuotes.isEmpty ? fallbackQuotes : newQuotes
        reshuffleIndices()
        currentQuote = quotes[shuffledIndices[0]]
    }

    private func reshuffleIndices() {
        shuffledIndices = Array(0..<quotes.count).shuffled()
        currentIndex = 0
    }

    private func loadCache() -> QuoteCache? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(QuoteCache.self, from: data)
    }

    private func isStale(_ cache: QuoteCache) -> Bool {
        Date().timeIntervalSince(cache.fetchedAt) > cacheTTL
    }

    private func fetchAndCache() async {
        do {
            let (data, response) = try await URLSession.shared.data(from: apiURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                logger.warning("ZenQuotes returned non-200 or rate limit; keeping existing quotes.")
                return
            }
            let fetched = try JSONDecoder().decode([Quote].self, from: data)
            guard !fetched.isEmpty else { return }
            let cache = QuoteCache(fetchedAt: Date(), quotes: fetched)
            let encoded = try JSONEncoder().encode(cache)
            try encoded.write(to: cacheURL, options: .atomic)
            logger.info("Fetched and cached \(fetched.count) quotes.")
        } catch {
            logger.error("Fetch/cache error: \(error.localizedDescription)")
        }
    }
}
