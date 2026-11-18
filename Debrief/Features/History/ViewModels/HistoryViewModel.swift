//
//  HistoryViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class HistoryViewModel {

    struct Section: Identifiable {
        let id: String
        let title: String
        let runs: [InterviewRun]
    }

    enum Filter: Hashable {
        case all
        case profession(Profession)

        var title: String {
            switch self {
            case .all: "Все"
            case .profession(let profession): profession.title
            }
        }
    }

    private let runRepository: any RunRepositoryProtocol
    private let router: Router
    private let user: User
    private var runs: [InterviewRun] = []

    var filter: Filter = .all { didSet { rebuild() } }
    private(set) var state: ScreenState<[Section]> = .loading

    let filters: [Filter] = [.all] + Profession.allCases.map(Filter.profession)
    let title = "История"

    init(user: User, runRepository: any RunRepositoryProtocol, router: Router) {
        self.user = user
        self.runRepository = runRepository
        self.router = router
    }

    var emptyMessage: String {
        switch filter {
        case .all: "Здесь будут все пройденные собеседования с ответами и разбором."
        case .profession(let profession): "Прогонов по профессии «\(profession.title)» пока нет."
        }
    }

    func load() async {
        do {
            runs = try await runRepository.runs(for: user.id)
            rebuild()
        } catch {
            state = .failed(error)
        }
    }

    func open(_ run: InterviewRun) {
        router.push(.result(run))
    }

    private func rebuild() {
        let filtered = runs.filter { run in
            switch filter {
            case .all: true
            case .profession(let profession): run.profession == profession
            }
        }
        guard !filtered.isEmpty else {
            state = .empty
            return
        }
        state = .loaded(Self.sections(for: filtered))
    }

    private static func sections(for runs: [InterviewRun]) -> [Section] {
        let calendar = Calendar.current
        var sections: [Section] = []
        for run in runs.sorted(by: { $0.completedAt > $1.completedAt }) {
            let components = calendar.dateComponents([.year, .month], from: run.completedAt)
            let id = "\(components.year ?? 0)-\(components.month ?? 0)"
            if let last = sections.last, last.id == id {
                sections[sections.count - 1] = Section(id: id, title: last.title, runs: last.runs + [run])
            } else {
                let title = run.completedAt.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "ru_RU")))
                sections.append(Section(id: id, title: title.capitalized, runs: [run]))
            }
        }
        return sections
    }
}
