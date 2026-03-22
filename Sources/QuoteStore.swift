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

    func load() async {
        let cachedResult = await loadCacheFromDisk()

        if let cache = cachedResult, !isStale(cache) {
            // Fresh cache: use it immediately
            setQuotes(cache.quotes)
        } else if let cache = cachedResult {
            // Stale cache: use it immediately, refresh in background (takes effect next activation)
            setQuotes(cache.quotes)
            Task { await fetchAndCache(applyToSession: false) }
        } else {
            // No cache: show fallback immediately, fetch and apply to current session
            setQuotes(fallbackQuotes)
            Task { await fetchAndCache(applyToSession: true) }
        }
    }

    func advance() {
        guard !quotes.isEmpty, !shuffledIndices.isEmpty else { return }
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

    private func loadCacheFromDisk() async -> QuoteCache? {
        let url = cacheURL
        return await Task.detached {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(QuoteCache.self, from: data)
        }.value
    }

    private func isStale(_ cache: QuoteCache) -> Bool {
        Date().timeIntervalSince(cache.fetchedAt) > cacheTTL
    }

    private func fetchAndCache(applyToSession: Bool) async {
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
            if applyToSession {
                setQuotes(fetched)
            }
        } catch {
            logger.error("Fetch/cache error: \(String(describing: error))")
        }
    }
}
