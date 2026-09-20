//
//  ContentView.swift
//  Dog Trainer
//
//  Created by Lelia Vlasenko on 15/06/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @Query private var dogs: [Dog]
    @State private var selectedTab: AppTab = .home

    // Показуємо MainTabView лише коли онбординг пройдено ТА є хоча б одна собака.
    // Якщо юзер видалив останню собаку — автоматично повертаємось в онбординг.
    private var showMain: Bool { onboardingDone && !dogs.isEmpty }

    var body: some View {
        Group {
            if showMain {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showMain)
        // Слухаємо deep links від App Intents
        .onReceive(NotificationCenter.default.publisher(for: .openAppTab)) { note in
            if let raw = note.userInfo?["tab"] as? String,
               let tab = AppTab(rawValue: raw) {
                selectedTab = tab
            }
        }
    }
}

// MARK: - Tab bar

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(String(localized: "tab.home"), systemImage: "house")
                }
                .tag(AppTab.home)

            ProgressView()
                .tabItem {
                    Label(String(localized: "tab.progress"), systemImage: "chart.bar")
                }
                .tag(AppTab.progress)

            LibraryView()
                .tabItem {
                    Label(String(localized: "tab.library"), systemImage: "books.vertical")
                }
                .tag(AppTab.library)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
        .environment(SubscriptionManager())
        .environment(NotificationManager())
}
