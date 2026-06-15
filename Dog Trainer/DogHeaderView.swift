import SwiftUI

struct DogHeaderView: View {
    let dog: Dog

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 6..<12:  return String(localized: "home.greeting.morning")
        case 12..<18: return String(localized: "home.greeting.afternoon")
        default:      return String(localized: "home.greeting.evening")
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 64, height: 64)
                Text(dog.level.emoji)
                    .font(.system(size: 34))
            }

            // Name + greeting
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(dog.name)
                    .font(.system(size: 26, weight: .bold))
                Text(dog.breed)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Streak badge
            if dog.currentStreak > 0 {
                VStack(spacing: 2) {
                    Text("🔥")
                        .font(.system(size: 22))
                    Text("\(dog.currentStreak)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(String(localized: "home.streak.days"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 48)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
