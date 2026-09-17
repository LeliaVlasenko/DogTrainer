import SwiftUI

// MARK: - Card style modifier
//
// Стандартний вигляд карточки, який використовується скрізь у застосунку.
// Замість `.padding(16).background(Color.appCardBackground).clipShape(...)`
// пишеш просто `.cardStyle()`. Одне місце для правок design-tokens.

extension View {

    /// Стандартна карточка — cream-фон + округлені кути.
    /// - Parameters:
    ///   - padding: внутрішній відступ (за замовч. 16pt).
    ///   - radius: радіус закруглення (за замовч. 14pt).
    ///   - background: фонова заливка (за замовч. `Color.appCardBackground`).
    func cardStyle(
        padding: CGFloat = 16,
        radius: CGFloat = 14,
        background: Color = .appCardBackground
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
