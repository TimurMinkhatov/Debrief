//
//  HomeViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 07/10/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {

    struct Summary {
        let lastRun: InterviewRun?
        let runCount: Int
    }

    private let runRepository: any RunRepositoryProtocol
    private let router: Router
    private let user: User

    var selectedProfession: Profession
    var selectedGrade: Grade
    private(set) var state: ScreenState<Summary> = .loading

    let professions = Profession.allCases
    let grades = Grade.allCases
    let startTitle = "Новое собеседование"
    let startDescription = "\(SelectionRules.theoryCount) вопросов теории · \(SelectionRules.reviewCount) задания на ревью · разбор резюме"
    let emptyHistoryTitle = "Пока без прогонов"
    let emptyHistoryMessage = "После первого собеседования здесь появится последний балл и ориентировочный грейд."

    init(user: User, runRepository: any RunRepositoryProtocol, router: Router) {
        self.user = user
        self.runRepository = runRepository
        self.router = router
        self.selectedProfession = user.profession
        self.selectedGrade = user.targetGrade
    }

    var greeting: String {
        "Привет, \(user.name)"
    }

    func lastRunCaption(for summary: Summary) -> String? {
        guard let run = summary.lastRun else { return nil }
        return "\(run.dateText) · всего прогонов: \(summary.runCount)"
    }

    func load() async {
        do {
            let runs = try await runRepository.runs(for: user.id)
            state = .loaded(Summary(lastRun: runs.first, runCount: runs.count))
        } catch {
            state = .failed(error)
        }
    }

    func startInterview() {
        router.push(.interview(selectedProfession, selectedGrade))
    }

    func openLastRun() {
        guard let run = state.content?.lastRun else { return }
        router.push(.result(run))
    }
}
