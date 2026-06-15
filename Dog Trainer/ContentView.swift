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
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            if onboardingDone {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingDone)
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

            Text(String(localized: "tab.library"))
                .tabItem {
                    Label(String(localized: "tab.library"), systemImage: "books.vertical")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
        .environment(SubscriptionManager())
}
