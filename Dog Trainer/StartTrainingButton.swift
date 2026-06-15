import SwiftUI

struct StartTrainingButton: View {
    let trainedToday: Bool
    let commandsReady: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: trainedToday ? "arrow.clockwise" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(trainedToday
                         ? String(localized: "home.cta.repeat")
                         : String(localized: "home.cta.start"))
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(trainedToday ? Color.secondary.opacity(0.15) : Color.accentColor)
                .foregroundStyle(trainedToday ? Color.primary : .white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.25), value: isPressed)
            }
            .disabled(!commandsReady)
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )

            // Підказка під кнопкою
            if !trainedToday {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(String(localized: "home.cta.duration"))
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}
