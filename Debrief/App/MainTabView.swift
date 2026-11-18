//
//  MainTabView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct MainTabView: View {
    let user: User

    @State private var selection: TabID = .interview

    var body: some View {
        TabView(selection: $selection) {
            Tab("Собеседование", systemImage: "bubble.left.and.text.bubble.right", value: TabID.interview) {
                RoutedStack(root: .home, user: user)
                    .id(user)
            }
            Tab("Прогресс", systemImage: "chart.bar.xaxis", value: TabID.progress) {
                RoutedStack(root: .progress, user: user)
                    .id(user)
            }
            Tab("Профиль", systemImage: "person.crop.circle", value: TabID.profile) {
                RoutedStack(root: .profile, user: user)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Color.card)
    }

    enum TabID: Hashable {
        case interview
        case progress
        case profile
    }
}
