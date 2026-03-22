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
