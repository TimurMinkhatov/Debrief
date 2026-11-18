//
//  RootView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 29/09/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var container: Container?

    var body: some View {
        Group {
            if let container {
                RootContentView(session: container.session)
                    .environment(container)
            } else {
                LoadingStateView(message: "Запускаемся")
            }
        }
        .task {
            if container == nil {
                container = Container(modelContext: modelContext)
            }
        }
    }
}

private struct RootContentView: View {

    @Environment(Container.self) private var container
    let session: AppSession

    var body: some View {
        ZStack {
            switch session.state {
            case .loading:
                LoadingStateView(message: "Загружаем профиль")
                    .transition(.screenContent)
            case .noUser:
                OnboardingView(viewModel: container.makeOnboardingViewModel())
                    .transition(.screenContent)
            case .ready(let user):
                MainTabView(user: user)
                    .transition(.screenContent)
            case .failed(let error):
                ErrorStateView(title: "Не удалось загрузить профиль", error: error) {
                    await session.load()
                }
                .transition(.screenContent)
            }
        }
        .task { await session.load() }
    }
}
