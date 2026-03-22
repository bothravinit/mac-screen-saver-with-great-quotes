# Motivational macOS Screen Saver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS `.saver` bundle that displays motivational quotes on a beautiful animated gradient background, cycling quotes every 30 seconds with smooth fade transitions.

**Architecture:** A `ScreenSaverView` subclass hosts a SwiftUI view via `NSHostingView`. A `QuoteStore` class manages fetching, caching, and rotating 100 quotes from the ZenQuotes API, with a 10-quote hardcoded fallback. A `Timer` fires every 30 seconds to advance the quote index, driving SwiftUI re-renders.

**Tech Stack:** Swift 5.9+, SwiftUI, ScreenSaver.framework, URLSession, FileManager, JSONEncoder/JSONDecoder, macOS 12.0+

---

## File Map

| File | Responsibility |
|------|---------------|
| `Sources/Quote.swift` | `Quote` and `QuoteCache` Codable models |
| `Sources/FallbackQuotes.swift` | Hardcoded array of 10 `Quote` values |
| `Sources/QuoteStore.swift` | Fetch, cache, shuffle, and rotate quotes |
| `Sources/GradientView.swift` | `TimelineView`-driven animated linear gradient |
| `Sources/QuoteCardView.swift` | Frosted-glass card with quote text and author |
| `Sources/ContentView.swift` | Root SwiftUI view composing gradient + card |
| `Sources/ScreenSaverView.swift` | `ScreenSaverView` subclass; `NSHostingView` host; timer lifecycle |
| `Resources/Info.plist` | Screen saver bundle metadata (`NSPrincipalClass`) |
| `MotivationalScreenSaver.entitlements` | Network client entitlement |
| `MotivationalScreenSaver.xcodeproj` | Xcode project (macOS Screen Saver target) |

---

## Task 1: Create Xcode Project

**Files:**
- Create: `MotivationalScreenSaver.xcodeproj`
- Create: `MotivationalScreenSaver.entitlements`
- Create: `Resources/Info.plist`

- [ ] **Step 1: Create a new Xcode project**

  Open Xcode → File → New → Project → macOS → Screen Saver Extension.
  - Product Name: `MotivationalScreenSaver`
  - Bundle Identifier: `com.vinitbothra.MotivationalScreenSaver`
  - Language: Swift
  - Save to: `/Users/vinitbothra/mac_screen_saver_with_great_quotes/`

- [ ] **Step 2: Set deployment target**

  In the target's General settings, set "Minimum Deployments" to **macOS 12.0**.

- [ ] **Step 3: Add network entitlement**

  In the target's "Signing & Capabilities" tab, add "App Sandbox" capability, then enable **Outgoing Connections (Client)**. This adds `com.apple.security.network.client = true` to the `.entitlements` file.

- [ ] **Step 4: Delete Xcode-generated boilerplate**

  Remove any auto-generated `.swift` files from Xcode (we'll replace them with our own). Keep `Info.plist`.

- [ ] **Step 5: Verify Info.plist has NSPrincipalClass**

  Ensure `Info.plist` contains:
  ```xml
  <key>NSPrincipalClass</key>
  <string>MotivationalScreenSaver.ScreenSaverView</string>
  ```
  (Xcode usually sets this automatically for screen saver targets.)

- [ ] **Step 6: Commit**

  ```bash
  git init
  git add .
  git commit -m "feat: initial Xcode screen saver project scaffold"
  ```

---

## Task 2: Quote Model

**Files:**
- Create: `Sources/Quote.swift`

- [ ] **Step 1: Create `Quote.swift`**

  ```swift
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
  ```

- [ ] **Step 2: Add file to Xcode target**

  In Xcode, right-click the `Sources` group → Add Files → select `Quote.swift`. Ensure it's added to the screen saver target.

- [ ] **Step 3: Build to confirm no errors**

  Cmd+B in Xcode. Expected: Build Succeeded.

- [ ] **Step 4: Commit**

  ```bash
  git add Sources/Quote.swift
  git commit -m "feat: add Quote and QuoteCache models"
  ```

---

## Task 3: Fallback Quotes

**Files:**
- Create: `Sources/FallbackQuotes.swift`

- [ ] **Step 1: Create `FallbackQuotes.swift`**

  ```swift
  import Foundation

  let fallbackQuotes: [Quote] = [
      Quote(id: UUID(), text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
      Quote(id: UUID(), text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
      Quote(id: UUID(), text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein"),
      Quote(id: UUID(), text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
      Quote(id: UUID(), text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
      Quote(id: UUID(), text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"),
      Quote(id: UUID(), text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis"),
      Quote(id: UUID(), text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
      Quote(id: UUID(), text: "Act as if what you do makes a difference. It does.", author: "William James"),
      Quote(id: UUID(), text: "It always seems impossible until it's done.", author: "Nelson Mandela"),
  ]
  ```

- [ ] **Step 2: Add to Xcode target and build**

  Add file to target. Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add Sources/FallbackQuotes.swift
  git commit -m "feat: add hardcoded fallback quotes"
  ```

---

## Task 4: QuoteStore

**Files:**
- Create: `Sources/QuoteStore.swift`

- [ ] **Step 1: Create `QuoteStore.swift`**

  ```swift
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
  ```

- [ ] **Step 2: Add to Xcode target and build**

  Add file to target. Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add Sources/QuoteStore.swift
  git commit -m "feat: add QuoteStore with fetch, cache, shuffle, and rotation"
  ```

---

## Task 5: GradientView

**Files:**
- Create: `Sources/GradientView.swift`

- [ ] **Step 1: Create `GradientView.swift`**

  ```swift
  import SwiftUI

  struct GradientView: View {
      // Three color pairs cycling sequentially, ~6s each = ~18s full loop
      private let colorPairs: [(Color, Color)] = [
          (Color(hex: "#4A00E0"), Color(hex: "#8E2DE2")),  // deep purple → indigo
          (Color(hex: "#11998E"), Color(hex: "#0F2027")),  // teal → navy
          (Color(hex: "#F7797D"), Color(hex: "#FBD786")),  // rose → orange
      ]

      var body: some View {
          TimelineView(.animation) { timeline in
              let elapsed = timeline.date.timeIntervalSinceReferenceDate
              let cyclePosition = (elapsed.truncatingRemainder(dividingBy: 18.0)) / 18.0 // 0.0–1.0 over 18s
              let pairIndex = Int(cyclePosition * 3) % 3
              let nextPairIndex = (pairIndex + 1) % 3
              let pairProgress = (cyclePosition * 3).truncatingRemainder(dividingBy: 1.0)

              let startColor = colorPairs[pairIndex].0.interpolated(to: colorPairs[nextPairIndex].0, by: pairProgress)
              let endColor = colorPairs[pairIndex].1.interpolated(to: colorPairs[nextPairIndex].1, by: pairProgress)

              LinearGradient(
                  colors: [startColor, endColor],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
              )
          }
          .ignoresSafeArea()
      }
  }

  // MARK: - Color helpers

  extension Color {
      init(hex: String) {
          let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
          var int: UInt64 = 0
          Scanner(string: hex).scanHexInt64(&int)
          let r = Double((int >> 16) & 0xFF) / 255
          let g = Double((int >> 8) & 0xFF) / 255
          let b = Double(int & 0xFF) / 255
          self.init(red: r, green: g, blue: b)
      }

      func interpolated(to other: Color, by fraction: Double) -> Color {
          // Resolve both colors to RGB components in sRGB color space
          let nsA = NSColor(self).usingColorSpace(.sRGB) ?? .white
          let nsB = NSColor(other).usingColorSpace(.sRGB) ?? .white
          let t = max(0, min(1, fraction))
          return Color(
              red:   nsA.redComponent   + (nsB.redComponent   - nsA.redComponent)   * t,
              green: nsA.greenComponent + (nsB.greenComponent - nsA.greenComponent) * t,
              blue:  nsA.blueComponent  + (nsB.blueComponent  - nsA.blueComponent)  * t
          )
      }
  }
  ```

- [ ] **Step 2: Add to Xcode target and build**

  Add file to target. Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add Sources/GradientView.swift
  git commit -m "feat: add animated gradient background view"
  ```

---

## Task 6: QuoteCardView

**Files:**
- Create: `Sources/QuoteCardView.swift`

- [ ] **Step 1: Create `QuoteCardView.swift`**

  ```swift
  import SwiftUI

  struct QuoteCardView: View {
      let quote: Quote

      var body: some View {
          VStack(spacing: 16) {
              Text(""\(quote.text)"")
                  .font(.system(size: 52, weight: .bold, design: .default))
                  .foregroundColor(.white)
                  .multilineTextAlignment(.center)
                  .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

              Text("— \(quote.author)")
                  .font(.system(size: 24, weight: .regular, design: .default))
                  .foregroundColor(.white.opacity(0.6))
                  .multilineTextAlignment(.center)
          }
          .padding(.horizontal, 48)
          .padding(.vertical, 36)
          .background(.ultraThinMaterial)
          .cornerRadius(20)
          .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 80) // keeps card within 80% of screen width
      }
  }
  ```

- [ ] **Step 2: Add to Xcode target and build**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add Sources/QuoteCardView.swift
  git commit -m "feat: add frosted-glass quote card view"
  ```

---

## Task 7: ContentView

**Files:**
- Create: `Sources/ContentView.swift`

- [ ] **Step 1: Create `ContentView.swift`**

  ```swift
  import SwiftUI

  struct ContentView: View {
      @ObservedObject var store: QuoteStore

      var body: some View {
          ZStack {
              GradientView()

              QuoteCardView(quote: store.currentQuote)
                  .transition(.opacity)
                  .id(store.currentQuote.id) // forces SwiftUI to treat each new quote as a new view → triggers transition

              // Attribution (bottom-right)
              VStack {
                  Spacer()
                  HStack {
                      Spacer()
                      Text("Powered by ZenQuotes.io")
                          .font(.system(size: 11))
                          .foregroundColor(.white.opacity(0.3))
                          .padding(16)
                  }
              }
          }
          .animation(.easeInOut(duration: 0.8), value: store.currentQuote.id)
      }
  }
  ```

- [ ] **Step 2: Add to Xcode target and build**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

  ```bash
  git add Sources/ContentView.swift
  git commit -m "feat: add root ContentView composing gradient and quote card"
  ```

---

## Task 8: ScreenSaverView (Main Entry Point)

**Files:**
- Create: `Sources/ScreenSaverView.swift`

- [ ] **Step 1: Create `ScreenSaverView.swift`**

  ```swift
  import ScreenSaver
  import SwiftUI

  final class ScreenSaverView: ScreenSaver.ScreenSaverView {
      private var hostingView: NSHostingView<ContentView>?
      private let store = QuoteStore()
      private var quoteTimer: Timer?

      override init?(frame: NSRect, isPreview: Bool) {
          super.init(frame: frame, isPreview: isPreview)
          setupHostingView(frame: frame)
          store.load()
      }

      required init?(coder: NSCoder) {
          super.init(coder: coder)
          setupHostingView(frame: bounds)
          store.load()
      }

      override func startAnimation() {
          super.startAnimation()
          quoteTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
              Task { @MainActor in self?.store.advance() }
          }
          RunLoop.main.add(quoteTimer!, forMode: .common)
      }

      override func stopAnimation() {
          super.stopAnimation()
          quoteTimer?.invalidate()
          quoteTimer = nil
      }

      override func animateOneFrame() {
          // SwiftUI + TimelineView handles all animation; nothing needed here.
      }

      // MARK: - Private

      private func setupHostingView(frame: NSRect) {
          let content = ContentView(store: store)
          let hosting = NSHostingView(rootView: content)
          hosting.frame = bounds
          hosting.autoresizingMask = [.width, .height]
          addSubview(hosting)
          hostingView = hosting
      }
  }
  ```

- [ ] **Step 2: Add to Xcode target and build**

  Cmd+B. Expected: Build Succeeded.

- [ ] **Step 3: Verify `Info.plist` principal class**

  Confirm `NSPrincipalClass` in `Info.plist` is `MotivationalScreenSaver.ScreenSaverView` (with the module prefix). This is how macOS discovers the entry point.

- [ ] **Step 4: Commit**

  ```bash
  git add Sources/ScreenSaverView.swift
  git commit -m "feat: add ScreenSaverView with SwiftUI host and quote timer"
  ```

---

## Task 9: Build and Install

- [ ] **Step 1: Build the Release target**

  In Xcode: Product → Scheme → Edit Scheme → set Run config to **Release**. Then Cmd+B.

- [ ] **Step 2: Locate the built `.saver` bundle**

  In Xcode, click the `.saver` product in the Products group → Show in Finder. Path will be something like:
  `~/Library/Developer/Xcode/DerivedData/MotivationalScreenSaver-.../Build/Products/Release/MotivationalScreenSaver.saver`

- [ ] **Step 3: Install the screen saver**

  Double-click `MotivationalScreenSaver.saver` in Finder. macOS will prompt to install it. Choose "Install for this user only."

- [ ] **Step 4: Activate in System Settings**

  System Settings → Screen Saver → select **MotivationalScreenSaver** from the list.

- [ ] **Step 5: Preview**

  Click "Preview" in Screen Saver settings to verify the saver renders correctly with gradient, quote card, and attribution.

- [ ] **Step 6: Verify quote rotation**

  Wait ~30 seconds in preview; confirm the quote fades out and a new one fades in.

- [ ] **Step 7: Commit**

  ```bash
  git add .
  git commit -m "feat: complete motivational screen saver implementation"
  ```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Blank screen / crash on activation | `NSPrincipalClass` missing/wrong in `Info.plist` | Check bundle ID matches module name exactly |
| Quotes never load (always fallback) | Missing network entitlement | Verify `com.apple.security.network.client = true` in `.entitlements` |
| Old saver still showing after install | macOS cached old bundle | Remove from `~/Library/Screen Savers/`, reinstall |
| Gradient not animating | `TimelineView` not in view hierarchy | Verify `GradientView` is embedded in `ContentView` |
| Build error "ScreenSaverView ambiguous" | Name conflict with framework class | Ensure file-level class uses `ScreenSaver.ScreenSaverView` as superclass |
