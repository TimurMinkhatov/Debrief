//
//  AnswerReviewViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class AnswerReviewViewModel {

    struct Review {
        let topicTitle: String?
        let messages: [ChatMessage]
        let points: [Point]

        func count(of coverage: Coverage) -> Int {
            points.filter { $0.coverage == coverage }.count
        }
    }

    struct Point: Identifiable, Equatable {
        let text: String
        let coverage: Coverage

        var id: String { text }
    }

    private let questionRepository: any QuestionRepositoryProtocol
    let result: QuestionResult

    private(set) var state: ScreenState<Review> = .loading

    init(result: QuestionResult, questionRepository: any QuestionRepositoryProtocol) {
        self.result = result
        self.questionRepository = questionRepository
    }

    func coverageTitle(for review: Review) -> String {
        let partial = review.count(of: .partial)
        let base = "Раскрыто \(review.count(of: .full)) из \(review.points.count)"
        return partial == 0 ? base : "\(base), частично \(partial)"
    }

    func load() async {
        do {
            let questions = try await questionRepository.questions()
            let topics = try await questionRepository.topics()
            let question = questions.first { $0.id == result.questionID }
            let topicTitle = question.flatMap { question in topics.first { $0.id == question.topicID }?.title }
            state = .loaded(Review(
                topicTitle: topicTitle,
                messages: messages(code: question?.kind.snippet),
                points: points(keyPoints: question?.keyPoints ?? [])
            ))
        } catch {
            state = .failed(error)
        }
    }

    private func messages(code: String?) -> [ChatMessage] {
        var messages = [
            ChatMessage(id: "question", text: result.turn.question, isFromInterviewer: true, code: code),
            ChatMessage(id: "answer", text: result.turn.answer, isFromInterviewer: false)
        ]
        if let followUp = result.followUp {
            messages.append(ChatMessage(id: "follow-up", text: followUp.question, isFromInterviewer: true))
            messages.append(ChatMessage(id: "follow-up-answer", text: followUp.answer, isFromInterviewer: false))
        }
        return messages
    }

    private func points(keyPoints: [String]) -> [Point] {
        let missed = Set(result.missedPoints)
        let partial = Set(result.partialPoints)
        let known = keyPoints.map { point in
            Point(text: point, coverage: missed.contains(point) ? .none : partial.contains(point) ? .partial : .full)
        }
        let unknownPartial = result.partialPoints
            .filter { !keyPoints.contains($0) }
            .map { Point(text: $0, coverage: .partial) }
        let unknownMissed = result.missedPoints
            .filter { !keyPoints.contains($0) }
            .map { Point(text: $0, coverage: .none) }
        return known + unknownPartial + unknownMissed
    }
}
