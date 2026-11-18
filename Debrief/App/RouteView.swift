//
//  RouteView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

// MARK: - RouteView
struct RouteView: View {
    let route: AppRoute
    let user: User

    @Environment(Container.self) private var container
    @Environment(Router.self) private var router

    var body: some View {
        switch route {
        case .home:
            HomeView(viewModel: container.makeHomeViewModel(user: user, router: router))
        case .progress:
            ProgressOverviewView(viewModel: container.makeProgressOverviewViewModel(user: user, router: router))
        case .profile:
            ProfileView(viewModel: container.makeProfileViewModel(user: user))
        case .interview(let profession, let grade):
            InterviewView(viewModel: container.makeInterviewViewModel(user: user, profession: profession, grade: grade, router: router))
        case .result(let run):
            ResultView(viewModel: container.makeResultViewModel(run: run, router: router))
        case .answerReview(let result):
            AnswerReviewView(viewModel: container.makeAnswerReviewViewModel(result: result))
        case .history:
            HistoryView(viewModel: container.makeHistoryViewModel(user: user, router: router))
        }
    }
}

// MARK: - RoutedStack
struct RoutedStack: View {
    let root: AppRoute
    let user: User

    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            RouteView(route: root, user: user)
                .navigationDestination(for: AppRoute.self) { route in
                    RouteView(route: route, user: user)
                }
        }
        .environment(router)
    }
}
