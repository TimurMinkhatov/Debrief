//
//  ResultViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class ResultViewModel {

    struct Content {
        let sections: [Section]
        let resumeReview: ResumeReview?
    }

    struct Section: Identifiable {
        let stage: StageKind
        let title: String
        let items: [Item]

        var id: StageKind { stage }

        var averageScore: Int {
            QuestionResult.averageScore(of: items.map(\.result))
        }
    }

    struct Item: Identifiable {
        let number: Int
        let result: QuestionResult
        let topicTitle: String?

        var id: String { result.id }

        var caption: String {
            topicTitle.map { "\(number). \($0)" } ?? "Вопрос \(number)"
        }

        var isComplete: Bool {
            result.missedPoints.isEmpty && result.partialPoints.isEmpty
        }

        var gapsTitle: String {
            guard !isComplete else { return "Все ключевые пункты раскрыты" }
            var parts: [String] = []
            if !result.missedPoints.isEmpty {
                parts.append("Не прозвучало: \(result.missedPoints.count)")
            }
            if !result.partialPoints.isEmpty {
                parts.append("Частично: \(result.partialPoints.count)")
            }
            return parts.joined(separator: " · ")
        }
    }

    private let questionRepository: any QuestionRepositoryProtocol
    private let router: Router
    let run: InterviewRun

    private(set) var state: ScreenState<Content> = .loading

    init(run: InterviewRun, questionRepository: any QuestionRepositoryProtocol, router: Router) {
        self.run = run
        self.questionRepository = questionRepository
        self.router = router
    }

    var gradeTitle: String {
        "Ориентировочно \(run.estimatedGrade.title)"
    }

    var subtitle: String {
        "\(run.profession.title) · цель \(run.targetGrade.title) · \(run.dateText)"
    }

    var resumeTitle: String {
        StageKind.resume.title(for: run.profession)
    }

    var verdict: String? {
        run.summaryText.isEmpty ? nil : run.summaryText
    }

    func load() async {
        do {
            let topics = try await questionRepository.topics()
            let questions = try await questionRepository.questions()
            let titleByTopic = Dictionary(topics.map { ($0.id, $0.title) }, uniquingKeysWith: { first, _ in first })
            let topicByQuestion = Dictionary(questions.map { ($0.id, $0.topicID) }, uniquingKeysWith: { first, _ in first })

            let sections = StageKind.allCases.compactMap { stage -> Section? in
                let results = run.results(for: stage)
                guard !results.isEmpty else { return nil }
                let items = results.enumerated().map { index, result in
                    Item(
                        number: index + 1,
                        result: result,
                        topicTitle: topicByQuestion[result.questionID].flatMap { titleByTopic[$0] }
                    )
                }
                return Section(stage: stage, title: stage.title(for: run.profession), items: items)
            }

            guard !sections.isEmpty || run.resumeReview != nil else {
                state = .empty
                return
            }
            state = .loaded(Content(sections: sections, resumeReview: run.resumeReview))
        } catch {
            state = .failed(error)
        }
    }

    func open(_ item: Item) {
        router.push(.answerReview(item.result))
    }
}
