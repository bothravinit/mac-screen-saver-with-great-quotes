import SwiftUI
import AppKit

struct InstallView: View {
    @State private var installState: InstallState = .ready

    enum InstallState { case ready, installed }

    var body: some View {
        VStack(spacing: 0) {
            heroPreview
            installPanel
        }
        .frame(width: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .fixedSize()
    }

    // MARK: - Hero

    private var heroPreview: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.29, green: 0.00, blue: 0.88),
                    Color(red: 0.56, green: 0.18, blue: 0.89),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Text("\u{201C}The only way to do great work is to love what you do.\u{201D}")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.4), radius: 4)
                    .padding(.horizontal, 24)

                Text("— Steve Jobs")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 20)
            .padding(36)
        }
        .frame(height: 220)
    }

    // MARK: - Install panel

    private var installPanel: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Motivational Screen Saver")
                    .font(.title2.bold())
                Text("Animated gradients. Daily wisdom. Free forever.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "quote.bubble.fill",       text: "100 motivational quotes, refreshed weekly")
                FeatureRow(icon: "paintpalette.fill",       text: "Animated gradient background")
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Rotates every 30 seconds with a smooth fade")
                FeatureRow(icon: "wifi.slash",              text: "Works offline with built-in fallback quotes")
            }

            Button(action: installScreenSaver) {
                HStack(spacing: 8) {
                    Image(systemName: installState == .installed ? "checkmark.circle.fill" : "square.and.arrow.down")
                    Text(installState == .installed ? "Screen Saver Installed!" : "Install Screen Saver")
                        .fontWeight(.semibold)
                }
                .frame(width: 240, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(installState == .installed)

            if installState == .installed {
                VStack(spacing: 6) {
                    Text("Now activate it in System Settings")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Open Screen Saver Settings \u{2192}") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.desktopscreeneffect")!
                        )
                    }
                    .buttonStyle(.link)
                    .font(.footnote)
                }
            }
        }
        .padding(32)
    }

    // MARK: - Actions

    private func installScreenSaver() {
        let saverURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/Screen Savers/MotivationalScreenSaver.saver")
        NSWorkspace.shared.open(saverURL)
        installState = .installed
    }
}

// MARK: - Feature row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}
