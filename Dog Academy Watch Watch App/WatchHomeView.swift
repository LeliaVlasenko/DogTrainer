import SwiftUI

// MARK: - Watch main view
//
// Показує ім'я обраної собаки, поточний streak, і CTA "Log training".
// При тапі відправляє повідомлення на iPhone → iPhone логує сесію →
// відповідає новим streak'ом → UI оновлюється.

struct WatchHomeView: View {
    @Environment(WatchConnectivityManager.self) private var connectivity

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let snapshot = connectivity.snapshot {
                    // Header — dog name
                    VStack(spacing: 4) {
                        Text(snapshot.dogName)
                            .font(.system(size: 18, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(snapshot.dogBreed)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Streak
                    VStack(spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 28))
                            Text("\(snapshot.streak)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.4), value: snapshot.streak)
                        }
                        Text(snapshot.trainedToday
                             ? String(localized: "watch.trained_today")
                             : String(localized: "watch.not_trained"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)

                    // Log training
                    Button {
                        Task { await connectivity.logTraining() }
                    } label: {
                        HStack(spacing: 6) {
                            if connectivity.isLogging {
                                SwiftUI.ProgressView()
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text(String(localized: "watch.log_cta"))
                                    .lineLimit(1)
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                    .disabled(connectivity.isLogging)
                } else {
                    unavailableView
                }
            }
            .padding(.horizontal, 8)
        }
        .refreshable { await connectivity.requestSnapshot() }
    }

    // Fallback: iPhone поза досяжністю або ще не активований.
    private var unavailableView: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text(String(localized: "watch.unreachable.title"))
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.center)
            Text(String(localized: "watch.unreachable.body"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(String(localized: "watch.unreachable.retry")) {
                Task { await connectivity.requestSnapshot() }
            }
            .font(.system(size: 12))
            .padding(.top, 4)
        }
        .padding(.top, 16)
    }
}
