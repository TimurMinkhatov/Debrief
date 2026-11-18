//
//  Router.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Observation

// MARK: - AppRoute
enum AppRoute: Hashable {
    case home
    case progress
    case profile
    case interview(Profession, Grade)
    case result(InterviewRun)
    case answerReview(QuestionResult)
    case history
}

// MARK: - Router
@Observable
@MainActor
final class Router {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func reset(to route: AppRoute) {
        path = [route]
    }
}
