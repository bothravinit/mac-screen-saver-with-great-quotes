import ScreenSaver
import SwiftUI

final class ScreenSaverView: ScreenSaver.ScreenSaverView {
    private var hostingView: NSHostingView<ContentView>?
    private let store = QuoteStore()
    private var quoteTimer: Timer?
    private var loadTask: Task<Void, Never>?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupHostingView()
        loadTask = Task { await store.load() }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHostingView()
        loadTask = Task { await store.load() }
    }

    override func startAnimation() {
        guard quoteTimer == nil else { return }
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
        loadTask?.cancel()
        loadTask = nil
    }

    override func animateOneFrame() {
        // SwiftUI + TimelineView handles all animation; nothing needed here.
    }

    // MARK: - Private

    private func setupHostingView() {
        let content = ContentView(store: store)
        let hosting = NSHostingView(rootView: content)
        hosting.frame = bounds
        hosting.autoresizingMask = [.width, .height]
        addSubview(hosting)
        hostingView = hosting
    }
}
