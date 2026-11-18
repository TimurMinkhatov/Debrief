//
//  ProgressOverviewViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class ProgressOverviewViewModel {

    struct Overview {
        let topics: [TopicRow]
        let recentRuns: [InterviewRun]
        let totalRuns: Int
        let averageScore: Int
    }

    struct TopicRow: Identifiable {
        let topic: Topic
        let score: Int?

        var id: String { topic.id }
        var scoreText: String { score.map(String.init) ?? "—" }
    }

    static let recentLimit = 3

    private let runRepository: any RunRepositoryProtocol
    private let questionRepository: any QuestionRepositoryProtocol
    private let router: Router
    private let user: User

    private(set) var state: ScreenState<Overview> = .loading

    let title = "Прогресс"

    init(user: User, runRepository: any RunRepositoryProtocol, questionRepository: any QuestionRepositoryProtocol, router: Router) {
        self.user = user
        self.runRepository = runRepository
        self.questionRepository = questionRepository
        self.router = router
    }

    var topicsCaption: String {
        "\(user.profession.title). Последний балл по каждой теме, слабые сверху: отбор будет предлагать их чаще."
    }

    var emptyMessage: String {
        "Пройди первое собеседование как \(user.profession.title), и здесь появятся баллы по темам и история прогонов."
    }

    func historyTitle(for overview: Overview) -> String {
        "Вся история (\(overview.totalRuns))"
    }

    func load() async {
        do {
            let runs = try await runRepository.runs(for: user.id).filter { $0.profession == user.profession }
            guard !runs.isEmpty else {
                state = .empty
                return
            }
            let questions = try await questionRepository.questions().filter { $0.profession == user.profession }
            let topicIDs = Set(questions.map(\.topicID))
            let topics = try await questionRepository.topics().filter { topicIDs.contains($0.id) }
            let scores = RunStatistics.latestScoreByTopic(in: runs, questions: questions)
            let rows = topics
                .map { TopicRow(topic: $0, score: scores[$0.id]) }
                .sorted { ($0.score ?? Int.max, $0.topic.title) < ($1.score ?? Int.max, $1.topic.title) }
            let average = runs.reduce(0) { $0 + $1.overallScore } / runs.count
            state = .loaded(Overview(
                topics: rows,
                recentRuns: Array(runs.prefix(Self.recentLimit)),
                totalRuns: runs.count,
                averageScore: average
            ))
        } catch {
            state = .failed(error)
        }
    }

    func open(_ run: InterviewRun) {
        router.push(.result(run))
    }

    func openHistory() {
        router.push(.history)
    }
}
