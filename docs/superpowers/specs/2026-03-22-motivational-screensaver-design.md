# Motivational macOS Screen Saver — Design Spec

**Date:** 2026-03-22
**Status:** Approved

---

## Overview

A native macOS screen saver (`.saver` bundle) built with Swift + SwiftUI + ScreenSaver framework. It displays one motivational quote at a time, cycling every 30 seconds with a smooth fade transition, on an animated gradient background.

---

## Architecture

Two primary components:

### 1. QuoteStore

Responsible for all quote data management.

- **Fetching:** On first activation (when no cache exists), fetches 100 quotes from ZenQuotes API (`https://zenquotes.io/api/quotes`). ZenQuotes free tier requires no API key and asks for attribution (displayed as "Powered by ZenQuotes.io" in small text).
- **HTTP 429 handling:** If rate-limited, fall back to cache (or hardcoded quotes if no cache).
- **Caching:** Persists quotes to `~/Library/Application Support/MotivationalScreenSaver/quotes.json` using `JSONEncoder`. Cache includes a `fetchedAt` timestamp.
- **Cache freshness:** If `fetchedAt` is older than 7 days, triggers a background refresh on activation. Background fetch completes silently; new quotes replace cache and take effect on next activation (not mid-session) to avoid race conditions.
- **Fallback:** If API unreachable and no cache exists, serves the hardcoded fallback set (see Fallback Quotes section).
- **Rotation:** Each activation generates a fresh shuffle of all available quotes. Shuffle index is NOT persisted — each session starts a new random order. When all quotes are shown, reshuffle and repeat.

### 2. ScreenSaverView (SwiftUI Host)

A `ScreenSaverView` subclass hosting SwiftUI via `NSHostingView`.

- **Hosting:** `ScreenSaverView` embeds an `NSHostingView<ContentView>` as a full-frame subview in `init(frame:isPreview:)`.
- **QuoteStore:** A single `QuoteStore` instance is created per `ScreenSaverView` instance. Each display gets its own independent instance (no shared singleton — avoids multi-screen state conflicts).
- **Timer:** Created in `startAnimation()`, invalidated in `stopAnimation()`. Runs on the main `RunLoop` (`.common` mode) to survive modal panels. Fires every 30 seconds and increments the quote index in `QuoteStore` via `@Published` property, driving SwiftUI re-render.
- **Transition:** Quote changes use SwiftUI `.transition(.opacity)` with `.animation(.easeInOut(duration: 0.8))`.

---

## Data Model

```swift
// Quote.swift
struct Quote: Codable, Identifiable {
    let id: UUID           // generated locally, not from API
    let text: String       // maps from API field "q"
    let author: String     // maps from API field "a"

    enum CodingKeys: String, CodingKey {
        case text = "q"
        case author = "a"
    }
    // id is excluded from Codable — assigned on decode via custom init
}

// Cache envelope
struct QuoteCache: Codable {
    let fetchedAt: Date
    let quotes: [Quote]
}
```

ZenQuotes API response is a JSON array of `{"q": "...", "a": "...", "h": "..."}` objects. The `h` field (HTML) is ignored.

---

## Visual Design

- **Background:** `ContentView` uses a `TimelineView(.animation)` to drive a continuously animating `LinearGradient`. Three color pairs cycle sequentially (not randomly), interpolated smoothly:
  - Deep purple (#4A00E0) → Indigo (#8E2DE2)
  - Teal (#11998E) → Navy (#0F2027)
  - Rose (#F7797D) → Orange (#FBD786)
  - Full cycle duration: ~18 seconds (6s per pair), loops continuously.
- **Quote card:**
  - Centered horizontally and vertically on screen.
  - Max width: 80% of screen width.
  - Padding: 48pt horizontal, 36pt vertical.
  - Corner radius: 20pt.
  - Background: `.ultraThinMaterial` (available macOS 12+).
  - Drop shadow: radius 20, opacity 0.3.
- **Quote text:** SF Pro Display, 52pt, bold, white, drop shadow (radius 4, opacity 0.5).
- **Author text:** SF Pro Display, 24pt, regular, white at 60% opacity. Positioned below quote with 16pt spacing.
- **Attribution:** "Powered by ZenQuotes.io" — 11pt, white at 30% opacity, bottom-right corner, 16pt inset.
- **Sizing note:** All sizes are SwiftUI logical points. On Retina displays SwiftUI handles scaling automatically.

---

## File Structure

```
MotivationalScreenSaver/
├── Sources/
│   ├── ScreenSaverView.swift      # ScreenSaverView subclass; NSHostingView host; timer lifecycle
│   ├── ContentView.swift          # Root SwiftUI view: gradient background + QuoteCardView
│   ├── QuoteCardView.swift        # Frosted card with quote text, author, fade transition
│   ├── GradientView.swift         # TimelineView-driven animated gradient
│   ├── QuoteStore.swift           # Fetch, cache, shuffle, rotate logic
│   ├── Quote.swift                # Quote + QuoteCache Codable models
│   └── FallbackQuotes.swift       # Hardcoded [Quote] array (10 quotes)
├── Resources/
│   └── Info.plist                 # NSPrincipalClass = ScreenSaverView
├── MotivationalScreenSaver.entitlements
│   # com.apple.security.network.client = true (required for URLSession in .saver)
└── MotivationalScreenSaver.xcodeproj
    # Target: macOS Screen Saver
    # Bundle ID: com.vinitbothra.MotivationalScreenSaver
    # Deployment target: macOS 12.0
    # Code signing: local development (sign to run locally)
```

---

## Data Flow

1. Screen saver activates → `startAnimation()` → `QuoteStore.load()`.
2. `load()`: read cache from disk → if missing/stale, fetch from API → if fetch fails, use fallback.
3. Shuffle loaded quotes. Display first quote immediately.
4. Timer fires every 30s → advance to next quote in shuffle → SwiftUI re-renders with fade transition.
5. All quotes shown → reshuffle, continue.
6. `stopAnimation()` → timer invalidated. Next activation starts fresh.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| API unavailable, cache exists | Use cached quotes |
| API unavailable, no cache | Use hardcoded fallback |
| HTTP 429 rate limit | Treat as unavailable; use cache or fallback |
| Malformed API response | Log to `os_log`, use cache or fallback |
| Cache write failure | Continue in-memory; log error; retry next activation |
| Empty API response | Use fallback |

---

## Entitlements & Network

The `.saver` bundle requires `com.apple.security.network.client = true` in its `.entitlements` file to allow outbound network access via `URLSession`. Without this, API calls silently fail under App Sandbox.

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (`TimelineView`, `.ultraThinMaterial`, `.transition`, `NSHostingView`)
- **Framework:** ScreenSaver.framework
- **Minimum macOS:** 12.0 (Monterey) — required for SwiftUI `TimelineView` and `.ultraThinMaterial`
- **Quote API:** ZenQuotes (`https://zenquotes.io/api/quotes`) — free, no API key required
- **Storage:** `FileManager` + `JSONEncoder`/`JSONDecoder`

---

## Fallback Quotes (bundled in FallbackQuotes.swift)

1. "The only way to do great work is to love what you do." — Steve Jobs
2. "It does not matter how slowly you go as long as you do not stop." — Confucius
3. "In the middle of difficulty lies opportunity." — Albert Einstein
4. "Believe you can and you're halfway there." — Theodore Roosevelt
5. "The future belongs to those who believe in the beauty of their dreams." — Eleanor Roosevelt
6. "Success is not final, failure is not fatal: it is the courage to continue that counts." — Winston Churchill
7. "You are never too old to set another goal or to dream a new dream." — C.S. Lewis
8. "The secret of getting ahead is getting started." — Mark Twain
9. "Act as if what you do makes a difference. It does." — William James
10. "It always seems impossible until it's done." — Nelson Mandela

---

## Out of Scope

- Settings/preferences panel
- Multi-screen coordination (each display runs independently)
- Large offline pre-bundled quote database
- Testing harness (manual testing via Xcode's screen saver preview)
