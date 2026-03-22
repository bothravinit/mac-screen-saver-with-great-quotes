import SwiftUI

struct QuoteCardView: View {
    let quote: Quote

    var body: some View {
        VStack(spacing: 16) {
            Text("\u{201C}\(quote.text)\u{201D}")
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 80) // keeps card within 80% of screen width
    }
}
