import SwiftUI
import SwiftData
import StoreKit

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(NotificationManager.self) private var notificationManager
    @Query private var dogs: [Dog]
    @AppStorage(DogSelection.key) private var selectedID: String = ""

    @State private var showEdit = false
    @State private var showPaywall = false
    @State private var showAvatarGenerator = false
    @State private var showAddDog = false
    @State private var pendingDelete: Dog? = nil

    private var dog: Dog? {
        DogSelection.resolve(from: dogs, selectedIDString: selectedID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let dog {
                    DogProfileCard(
                        dog: dog,
                        onEdit: { showEdit = true },
                        onGenerateAvatar: { showAvatarGenerator = true }
                    )
                }

                DogsListSection(
                    dogs: dogs,
                    selected: dog,
                    onAdd: { showAddDog = true },
                    onDelete: { pendingDelete = $0 }
                )

                SubscriptionSection(
                    status: subscriptionManager.status,
                    onShowPaywall: { showPaywall = true }
                )

                RemindersSection()

                AppInfoSection()

                if DeveloperMode.isAvailable {
                    DeveloperSection()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle(String(localized: "profile.title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showEdit) {
            if let dog {
                EditDogView(dog: dog)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showAvatarGenerator) {
            if let dog {
                if #available(iOS 18.1, *) {
                    AvatarGeneratorView(dog: dog)
                }
            }
        }
        .sheet(isPresented: $showAddDog) {
            AddDogSheet()
        }
        .alert(
            String(localized: "profile.dog.delete.title"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { dog in
            Button(String(localized: "profile.dog.delete.confirm"), role: .destructive) {
                delete(dog)
            }
            Button(String(localized: "profile.edit.cancel"), role: .cancel) {}
        } message: { dog in
            Text(String(localized: "profile.dog.delete.message \(dog.name)"))
        }
    }

    private func delete(_ dog: Dog) {
        // Якщо видаляємо обрану — фолбек на іншу.
        if dog.id == self.dog?.id, let fallback = dogs.first(where: { $0.id != dog.id }) {
            DogSelection.select(fallback)
        }
        modelContext.delete(dog)
        try? modelContext.save()
    }
}

// MARK: - Dog card

private struct DogProfileCard: View {
    let dog: Dog
    let onEdit: () -> Void
    let onGenerateAvatar: () -> Void

    private var ageText: String? {
        guard let birthDate = dog.birthDate else { return nil }
        let years = Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0
        let months = Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0
        if years >= 1 {
            return String(localized: "profile.dog.age.years \(years)")
        } else {
            return String(localized: "profile.dog.age.months \(months)")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Avatar with camera overlay
            Button(action: onGenerateAvatar) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 88, height: 88)
                        DogAvatar(dog: dog, size: 88)
                    }
                    // Camera badge — підказка, що тут можна згенерувати аватар
                    ZStack {
                        Circle()
                            .fill(Color.appSage)
                            .frame(width: 30, height: 30)
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        Circle().strokeBorder(Color.appCardBackground, lineWidth: 3)
                    )
                    .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            // Name + meta
            VStack(spacing: 6) {
                Text(dog.name)
                    .font(.system(size: 24, weight: .bold))
                HStack(spacing: 6) {
                    Text(dog.breed)
                    if let ageText {
                        Text("·")
                        Text(ageText)
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

                // Level badge
                HStack(spacing: 4) {
                    BrandIcon(dog.level.iconName, size: 14)
                    Text(dog.level.localizedTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
            }

            // Edit button
            Button(action: onEdit) {
                Label(String(localized: "profile.edit"), systemImage: "pencil")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.appNestedBackground)
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Dogs list section

private struct DogsListSection: View {
    let dogs: [Dog]
    let selected: Dog?
    let onAdd: () -> Void
    let onDelete: (Dog) -> Void

    var body: some View {
        SectionCard(title: String(localized: "profile.dogs.title")) {
            VStack(spacing: 0) {
                ForEach(dogs) { dog in
                    Button {
                        DogSelection.select(dog)
                    } label: {
                        HStack(spacing: 12) {
                            DogAvatar(dog: dog, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dog.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                Text(dog.breed)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if dog.id == selected?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        if dogs.count > 1 {
                            Button(role: .destructive) {
                                onDelete(dog)
                            } label: {
                                Label(String(localized: "profile.dog.delete"), systemImage: "trash")
                            }
                        }
                    }
                    if dog.id != dogs.last?.id {
                        Divider().padding(.vertical, 10)
                    }
                }

                Divider().padding(.vertical, 10)

                Button(action: onAdd) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.appSage)
                        Text(String(localized: "profile.dog.add.title"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Subscription section

private struct SubscriptionSection: View {
    let status: SubscriptionStatus
    let onShowPaywall: () -> Void

    @State private var showManageSheet = false

    private var statusInfo: (icon: String, color: Color, title: String, subtitle: String) {
        switch status {
        case .loading:
            return ("hourglass", .secondary,
                    String(localized: "profile.subscription.status.loading"), "")
        case .trial(let days):
            return ("gift.fill", Color.appFlame,
                    String(localized: "profile.subscription.status.trial"),
                    String(localized: "profile.subscription.status.trial.sub \(days)"))
        case .active:
            return ("crown.fill", Color.appGold,
                    String(localized: "profile.subscription.status.active"),
                    String(localized: "profile.subscription.status.active.sub"))
        case .expired:
            return ("exclamationmark.circle.fill", Color.appCoral,
                    String(localized: "profile.subscription.status.expired"),
                    String(localized: "profile.subscription.status.expired.sub"))
        case .notSubscribed:
            return ("crown", .secondary,
                    String(localized: "profile.subscription.status.none"),
                    String(localized: "profile.subscription.status.none.sub"))
        case .unknown:
            return ("questionmark.circle", .secondary,
                    String(localized: "profile.subscription.status.none"), "")
        }
    }

    private var ctaTitle: String {
        switch status {
        case .active, .trial:
            return String(localized: "profile.subscription.manage")
        default:
            return String(localized: "profile.subscription.subscribe")
        }
    }

    var body: some View {
        SectionCard(title: String(localized: "profile.subscription.title")) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusInfo.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: statusInfo.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(statusInfo.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusInfo.title)
                            .font(.system(size: 15, weight: .semibold))
                        if !statusInfo.subtitle.isEmpty {
                            Text(statusInfo.subtitle)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                Button {
                    // Активна підписка/trial → відкриваємо системну "Manage Subscriptions"
                    // Інакше → показуємо власний paywall.
                    if status.isPremium {
                        showManageSheet = true
                    } else {
                        onShowPaywall()
                    }
                } label: {
                    Text(ctaTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .manageSubscriptionsSheet(isPresented: $showManageSheet)
            }
        }
    }
}

// MARK: - Reminders section

private struct RemindersSection: View {
    @Environment(NotificationManager.self) private var notificationManager
    @Query private var dogs: [Dog]
    @AppStorage(DogSelection.key) private var selectedID: String = ""
    @AppStorage("notif.enabled") private var enabled = true

    private var dog: Dog? {
        DogSelection.resolve(from: dogs, selectedIDString: selectedID)
    }

    private var hourBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = notificationManager.dailyReminderHour
                comps.minute = 0
                return Calendar.current.date(from: comps) ?? .now
            },
            set: { newDate in
                let hour = Calendar.current.component(.hour, from: newDate)
                notificationManager.dailyReminderHour = hour
                Task { await notificationManager.rescheduleAll(dog: dog) }
            }
        )
    }

    var body: some View {
        SectionCard(title: String(localized: "profile.reminders.title")) {
            VStack(spacing: 0) {
                Toggle(isOn: $enabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "profile.reminders.daily"))
                            .font(.system(size: 15))
                        Text(String(localized: "profile.reminders.daily.sub"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.accentColor)
                .onChange(of: enabled) { _, newValue in
                    Task {
                        if newValue {
                            _ = await notificationManager.requestPermission()
                            await notificationManager.rescheduleAll(dog: dog)
                        } else {
                            notificationManager.cancelAll()
                        }
                    }
                }

                if enabled {
                    Divider().padding(.vertical, 12)

                    HStack {
                        Text(String(localized: "profile.reminders.time"))
                            .font(.system(size: 15))
                        Spacer()
                        DatePicker(
                            "",
                            selection: hourBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }
            }
        }
    }
}

// MARK: - Developer section (DEBUG / DEVELOPER_MODE only)

private struct DeveloperSection: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        @Bindable var subs = subscriptionManager

        SectionCard(title: String(localized: "profile.developer.title")) {
            VStack(spacing: 0) {
                Toggle(isOn: $subs.devUnlockAll) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "hammer.fill")
                                .foregroundStyle(Color.appFlame)
                                .font(.system(size: 13))
                            Text(String(localized: "profile.developer.unlock"))
                                .font(.system(size: 15))
                        }
                        Text(String(localized: "profile.developer.unlock.sub"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color.appFlame)

                Divider().padding(.vertical, 10)

                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(String(localized: "profile.developer.note"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

// MARK: - App info section

private struct AppInfoSection: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        SectionCard(title: String(localized: "profile.info.title")) {
            VStack(spacing: 0) {
                InfoRow(
                    icon: "info.circle",
                    title: String(localized: "profile.info.version"),
                    trailing: version
                )
                Divider().padding(.vertical, 10)
                Link(destination: URL(string: "https://leliavlasenko.github.io/DogTrainer/privacy.html")!) {
                    InfoRow(
                        icon: "hand.raised",
                        title: String(localized: "profile.info.privacy"),
                        chevron: true
                    )
                }
                Divider().padding(.vertical, 10)
                Link(destination: URL(string: "https://leliavlasenko.github.io/DogTrainer/terms.html")!) {
                    InfoRow(
                        icon: "doc.text",
                        title: String(localized: "profile.info.terms"),
                        chevron: true
                    )
                }
            }
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    var trailing: String? = nil
    var chevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
        }
    }
}

// MARK: - Section card

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            content()
                .padding(16)
                .background(Color.appCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(ModelContainer.preview)
            .environment(SubscriptionManager())
            .environment(NotificationManager())
    }
}
