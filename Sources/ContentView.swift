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
