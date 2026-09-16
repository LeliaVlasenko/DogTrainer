import SwiftUI
import SwiftData

struct AllBadgesView: View {
    @Query private var earned: [EarnedBadge]

    private var earnedMap: [String: Date] {
        Dictionary(uniqueKeysWithValues: earned.map { ($0.badgeId, $0.earnedAt) })
    }

    private var earnedCount: Int { earned.count }
    private var totalCount: Int { BadgeCatalog.all.count }

    // Групуємо по category
    private var streakBadges:   [BadgeDefinition] { BadgeCatalog.all.filter { $0.category == .streak } }
    private var sessionBadges:  [BadgeDefinition] { BadgeCatalog.all.filter { $0.category == .sessions } }
    private var masteryBadges:  [BadgeDefinition] { BadgeCatalog.all.filter { $0.category == .mastery } }
    private var specialBadges:  [BadgeDefinition] { BadgeCatalog.all.filter { $0.category == .special } }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress header
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(earnedCount)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                        Text("/ \(totalCount)")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    Text(String(localized: "badges.header.subtitle"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.12)).frame(height: 6)
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(width: geo.size.width * Double(earnedCount) / Double(max(1, totalCount)), height: 6)
                                .animation(.spring(response: 0.6), value: earnedCount)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                BadgeSection(
                    title: String(localized: "badges.section.streak"),
                    icon: "flame",
                    badges: streakBadges,
                    earnedMap: earnedMap
                )
                BadgeSection(
                    title: String(localized: "badges.section.sessions"),
                    icon: "figure.walk.dog",
                    badges: sessionBadges,
                    earnedMap: earnedMap
                )
                BadgeSection(
                    title: String(localized: "badges.section.mastery"),
                    icon: "graduationcap",
                    badges: masteryBadges,
                    earnedMap: earnedMap
                )
                BadgeSection(
                    title: String(localized: "badges.section.special"),
                    icon: "sparkles",
                    badges: specialBadges,
                    earnedMap: earnedMap
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle(String(localized: "badges.title"))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Section

private struct BadgeSection: View {
    let title: String
    let icon: String
    let badges: [BadgeDefinition]
    let earnedMap: [String: Date]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                let sectionEarned = badges.filter { earnedMap[$0.id] != nil }.count
                Text("\(sectionEarned)/\(badges.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(badges) { badge in
                    BadgeCard(
                        definition: badge,
                        isEarned: earnedMap[badge.id] != nil,
                        earnedAt: earnedMap[badge.id]
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AllBadgesView()
            .modelContainer(ModelContainer.preview)
    }
}
