//
//  Fixtures.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation

// MARK: - Builders
func makeQuestion(
    id: String,
    topicID: String? = nil,
    profession: Profession = .iosDeveloper,
    grade: Grade = .intern,
    kind: QuestionKind = .theory,
    keyPoints: [String] = ["a", "b"]
) -> Question {
    Question(
        id: id,
        topicID: topicID ?? "topic-\(id)",
        profession: profession,
        grade: grade,
        kind: kind,
        prompt: "prompt-\(id)",
        keyPoints: keyPoints
    )
}

func makeResult(questionID: String, score: Int) -> QuestionResult {
    QuestionResult(
        questionID: questionID,
        turn: Turn(question: "q", answer: "a"),
        followUp: nil,
        score: score,
        missedPoints: []
    )
}

func makeRun(
    userID: UUID = UUID(),
    targetGrade: Grade = .intern,
    completedAt: Date,
    results: [QuestionResult]
) -> InterviewRun {
    InterviewRun(
        userID: userID,
        profession: .iosDeveloper,
        targetGrade: targetGrade,
        completedAt: completedAt,
        results: results,
        summaryText: ""
    )
}

let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)
let day: TimeInterval = 60 * 60 * 24

// MARK: - SeededGenerator
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - StubInterviewService
final class StubInterviewService: InterviewServiceProtocol, @unchecked Sendable {
    var evaluateOutcome: QuestionOutcome = .finished(Assessment(score: 100, missedPoints: []))
    var scoreResult = Assessment(score: 100, missedPoints: [])
    var error: Error?
    private(set) var evaluateCalls: [(question: Question, answer: String)] = []
    private(set) var scoreCalls: [(question: Question, turn: Turn, followUp: Turn)] = []

    func evaluate(question: Question, answer: String) async throws -> QuestionOutcome {
        evaluateCalls.append((question, answer))
        if let error { throw error }
        return evaluateOutcome
    }

    func score(question: Question, turn: Turn, followUp: Turn) async throws -> Assessment {
        scoreCalls.append((question, turn, followUp))
        if let error { throw error }
        return scoreResult
    }

    var resumeReview = ResumeReview(summary: "Хорошо", strengths: ["Swift"], gaps: ["Тесты"])
    private(set) var resumeCalls: [(text: String, profession: Profession, grade: Grade)] = []

    func reviewResume(text: String, profession: Profession, targetGrade: Grade) async throws -> ResumeReview {
        resumeCalls.append((text, profession, targetGrade))
        if let error { throw error }
        return resumeReview
    }

    func verdict(
        results: [QuestionResult],
        questions: [Question],
        resumeReview: ResumeReview?,
        profession: Profession,
        targetGrade: Grade
    ) async throws -> String {
        if let error { throw error }
        return "verdict"
    }
}

struct StubError: Error, Equatable {}
