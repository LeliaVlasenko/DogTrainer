import SwiftUI

struct RecentSessionsView: View {
    let sessions: [TrainingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "progress.recent.title"))
                .font(.system(size: 15, weight: .semibold))

            if sessions.isEmpty {
                Text(String(localized: "progress.recent.empty"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions, id: \.date) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct SessionRow: View {
    let session: TrainingSession

    private var successRate: Int { Int(session.successRate * 100) }
    private var rateColor: Color {
        switch successRate {
        case 80...: return .green
        case 50...: return .orange
        default:    return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mood emoji
            Text(session.mood.emoji)
                .font(.system(size: 24))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .medium))
                HStack(spacing: 6) {
                    Text(String(localized: "progress.session.commands \(session.commandsDoneCount)"))
                    Text("·")
                    Text(session.durationFormatted)
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Success rate badge
            Text("\(successRate)%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(rateColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(rateColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
