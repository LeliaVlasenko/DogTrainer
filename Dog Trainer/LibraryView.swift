import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query(sort: \Command.title) private var commands: [Command]

    @State private var searchText = ""
    @State private var selectedCategory: CommandCategory? = nil
    @State private var selectedDifficulty: CommandDifficulty? = nil
    @State private var selectedCommand: Command? = nil
    @State private var showPaywall = false

    private var filtered: [Command] {
        commands.filter { cmd in
            let matchesSearch = searchText.isEmpty ||
                cmd.title.localizedCaseInsensitiveContains(searchText) ||
                cmd.commandDescription.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || cmd.category == selectedCategory
            let matchesDifficulty = selectedDifficulty == nil || cmd.difficulty == selectedDifficulty
            return matchesSearch && matchesCategory && matchesDifficulty
        }
    }

    private var groupedByCategory: [(CommandCategory, [Command])] {
        let cats = selectedCategory.map { [$0] } ?? CommandCategory.allCases
        return cats.compactMap { cat in
            let cmds = filtered.filter { $0.category == cat }
            return cmds.isEmpty ? nil : (cat, cmds)
        }
    }

    private var stats: (total: Int, mastered: Int, premium: Int) {
        (
            total: commands.count,
            mastered: commands.filter { $0.isMastered }.count,
            premium: commands.filter { $0.isPremium }.count
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LibraryStatsBar(
                        total: stats.total,
                        mastered: stats.mastered,
                        isPremium: subscriptionManager.isPremium
                    ) { showPaywall = true }

                    FilterBarView(
                        selectedCategory: $selectedCategory,
                        selectedDifficulty: $selectedDifficulty
                    )

                    if filtered.isEmpty {
                        LibraryEmptyView(hasFilters: !searchText.isEmpty || selectedCategory != nil || selectedDifficulty != nil) {
                            searchText = ""
                            selectedCategory = nil
                            selectedDifficulty = nil
                        }
                    } else {
                        LazyVStack(spacing: 20, pinnedViews: []) {
                            ForEach(groupedByCategory, id: \.0) { category, cmds in
                                LibraryCategorySection(
                                    category: category,
                                    commands: cmds,
                                    isPremium: subscriptionManager.isPremium
                                ) { cmd in
                                    if cmd.isPremium && !subscriptionManager.isPremium {
                                        showPaywall = true
                                    } else {
                                        selectedCommand = cmd
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "tab.library"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: String(localized: "library.search.prompt")
            )
            .sheet(item: $selectedCommand) { cmd in
                LibraryCommandDetailView(command: cmd)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(ModelContainer.preview)
        .environment(SubscriptionManager())
}
