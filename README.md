# Motivational Screen Saver for macOS

A native macOS screen saver that displays motivational quotes on a beautiful animated gradient background. Quotes rotate every 30 seconds with smooth fade transitions.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

## Features

- Animated gradient background cycling through rich color pairs (purple→indigo, teal→navy, rose→orange)
- 100 quotes fetched from [ZenQuotes.io](https://zenquotes.io) and cached locally
- Quotes rotate every 30 seconds with a smooth 0.8s crossfade transition
- Fallback set of 10 built-in quotes if the network is unavailable
- Cache refreshes automatically every 7 days in the background

## Quick Install (no developer tools needed)

1. Download **[MotivationalScreenSaver.zip](https://github.com/bothravinit/mac-screen-saver-with-great-quotes/releases/latest/download/MotivationalScreenSaver.zip)** from the latest release
2. Unzip to get `MotivationalScreenSaver.saver`
3. Double-click the `.saver` file — macOS will ask *"Do you want to install this screen saver?"*
4. Click **Install for this user only**
5. Open **System Settings** → search **Screen Saver** → select **MotivationalScreenSaver**

> If macOS blocks the file, go to **System Settings → Privacy & Security** and click **Allow Anyway**.

---

## Requirements

- macOS 12.0 (Monterey) or later
- Swift 5.9+ (Command Line Tools or Xcode)

## Installation

### Option 1: Build from source (Command Line Tools — no Xcode required)

1. **Clone the repository**

   ```bash
   git clone https://github.com/bothravinit/mac-screen-saver-with-great-quotes.git
   cd mac-screen-saver-with-great-quotes
   ```

2. **Build the screen saver**

   ```bash
   mkdir -p build/MotivationalScreenSaver.saver/Contents/MacOS
   cp Resources/Info.plist build/MotivationalScreenSaver.saver/Contents/

   swiftc \
     -module-name MotivationalScreenSaver \
     -parse-as-library \
     -Xlinker -bundle \
     -sdk $(xcrun --show-sdk-path) \
     -target arm64-apple-macos12.0 \
     -framework ScreenSaver \
     -framework SwiftUI \
     -framework AppKit \
     -framework Foundation \
     Sources/Quote.swift \
     Sources/FallbackQuotes.swift \
     Sources/QuoteStore.swift \
     Sources/GradientView.swift \
     Sources/QuoteCardView.swift \
     Sources/ContentView.swift \
     Sources/ScreenSaverView.swift \
     -o build/MotivationalScreenSaver.saver/Contents/MacOS/MotivationalScreenSaver
   ```

   > **Intel Mac?** Replace `-target arm64-apple-macos12.0` with `-target x86_64-apple-macos12.0`

3. **Sign the bundle**

   ```bash
   codesign --force --sign - --entitlements MotivationalScreenSaver.entitlements \
     build/MotivationalScreenSaver.saver
   ```

4. **Install**

   ```bash
   cp -R build/MotivationalScreenSaver.saver ~/Library/Screen\ Savers/
   ```

5. **Activate**

   Open **System Settings** → search for **Screen Saver** → select **MotivationalScreenSaver**.

---

### Option 2: Build with Xcode

1. Clone the repository and open `MotivationalScreenSaver.xcodeproj` in Xcode.
2. Set your Development Team in the target's **Signing & Capabilities** tab.
3. Build with **Cmd+B**.
4. In the Xcode Products group, right-click `MotivationalScreenSaver.saver` → **Show in Finder**.
5. Double-click the `.saver` file — macOS will prompt you to install it.
6. Open **System Settings** → **Screen Saver** → select **MotivationalScreenSaver**.

---

## Security prompt

On first install, macOS may block the screen saver because it is not notarized. To allow it:

**System Settings → Privacy & Security** → scroll down to the blocked item → click **Allow Anyway**.

## How it works

| Component | Description |
|---|---|
| `QuoteStore` | Fetches quotes from ZenQuotes API, caches to `~/Library/Application Support/MotivationalScreenSaver/quotes.json`, rotates via shuffle |
| `GradientView` | `TimelineView`-driven animated gradient, 18-second cycle |
| `QuoteCardView` | Frosted-glass card with quote text and author |
| `ContentView` | Composes gradient + card + attribution, drives fade transition |
| `ScreenSaverView` | `ScreenSaverView` subclass hosting SwiftUI via `NSHostingView`, 30s timer |

## Attribution

Quotes provided by [ZenQuotes.io](https://zenquotes.io).
