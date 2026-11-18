//
//  TestDoubles.swift
//  DebriefTests
//
//  Created by Timur Minkhatov on 01/11/2026.
//

@testable import Debrief
import DebriefDomain
import Foundation

// MARK: - Builders
func makeQuestion(
    id: String,
    topicID: String? = nil,
    profession: Profession = .iosDeveloper,
    grade: Grade = .intern,
    kind: QuestionKind = .theory,
    keyPoints: [String] = ["пункт 1", "пункт 2"]
) -> Question {
    Question(
        id: id,
        topicID: topicID ?? "topic-\(id)",
        profession: profession,
        grade: grade,
        kind: kind,
        prompt: "Вопрос \(id)",
        keyPoints: keyPoints
    )
}

func makeResult(
    questionID: String,
    stage: StageKind = .theory,
    score: Int,
    missedPoints: [String] = [],
    partialPoints: [String] = [],
    followUp: Turn? = nil
) -> QuestionResult {
    QuestionResult(
        questionID: questionID,
        stage: stage,
        turn: Turn(question: "Вопрос \(questionID)", answer: "Ответ \(questionID)"),
        followUp: followUp,
        score: score,
        missedPoints: missedPoints,
        partialPoints: partialPoints
    )
}

func makeRun(
    userID: UUID,
    profession: Profession = .iosDeveloper,
    completedAt: Date = Date(timeIntervalSince1970: 1_800_000_000),
    results: [QuestionResult],
    resumeReview: ResumeReview? = nil
) -> InterviewRun {
    InterviewRun(
        userID: userID,
        profession: profession,
        targetGrade: .junior,
        completedAt: completedAt,
        results: results,
        resumeReview: resumeReview,
        summaryText: "Итог"
    )
}

let testUser = User(name: "Тимур", profession: .iosDeveloper, targetGrade: .intern)

struct TestError: LocalizedError, Equatable {
    var errorDescription: String? { "Тестовая ошибка" }
}

// MARK: - StubQuestionRepository
final class StubQuestionRepository: QuestionRepositoryProtocol, @unchecked Sendable {
    var topicList: [Topic]
    var questionList: [Question]
    var error: Error?

    init(topics: [Topic] = [], questions: [Question] = []) {
        self.topicList = topics
        self.questionList = questions
    }

    func topics() async throws -> [Topic] {
        if let error { throw error }
        return topicList
    }

    func questions() async throws -> [Question] {
        if let error { throw error }
        return questionList
    }
}

// MARK: - InMemoryRunRepository
final class InMemoryRunRepository: RunRepositoryProtocol, @unchecked Sendable {
    var storedRuns: [InterviewRun]
    var error: Error?
    var saveError: Error?

    init(runs: [InterviewRun] = []) {
        self.storedRuns = runs
    }

    func runs(for userID: UUID) async throws -> [InterviewRun] {
        if let error { throw error }
        return storedRuns
            .filter { $0.userID == userID }
            .sorted { $0.completedAt > $1.completedAt }
    }

    func save(_ run: InterviewRun) async throws {
        if let saveError { throw saveError }
        storedRuns.removeAll { $0.id == run.id }
        storedRuns.append(run)
    }
}

// MARK: - InMemoryUserRepository
final class InMemoryUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    var user: User?
    var saveError: Error?

    init(user: User? = nil) {
        self.user = user
    }

    func findUser() async throws -> User? {
        user
    }

    func save(_ user: User) async throws {
        if let saveError { throw saveError }
        self.user = user
    }
}

// MARK: - StubInterviewService
final class StubInterviewService: InterviewServiceProtocol, @unchecked Sendable {
    var evaluateOutcomes: [QuestionOutcome] = []
    var defaultOutcome: QuestionOutcome = .finished(Assessment(score: 80, missedPoints: []))
    var scoreResult = Assessment(score: 90, missedPoints: [])
    var verdictText = "Хороший прогон"
    var answerError: Error?
    var verdictError: Error?
    private(set) var verdictCalls = 0

    func evaluate(question: Question, answer: String) async throws -> QuestionOutcome {
        if let answerError { throw answerError }
        return evaluateOutcomes.isEmpty ? defaultOutcome : evaluateOutcomes.removeFirst()
    }

    func score(question: Question, turn: Turn, followUp: Turn) async throws -> Assessment {
        if let answerError { throw answerError }
        return scoreResult
    }

    var resumeReview = ResumeReview(summary: "Хорошее резюме", strengths: ["SwiftUI"], gaps: ["Нет метрик"])
    var resumeError: Error?
    private(set) var verdictResumeReviews: [ResumeReview?] = []

    func reviewResume(text: String, profession: Profession, targetGrade: Grade) async throws -> ResumeReview {
        if let resumeError { throw resumeError }
        return resumeReview
    }

    func verdict(
        results: [QuestionResult],
        questions: [Question],
        resumeReview: ResumeReview?,
        profession: Profession,
        targetGrade: Grade
    ) async throws -> String {
        verdictCalls += 1
        verdictResumeReviews.append(resumeReview)
        if let verdictError { throw verdictError }
        return verdictText
    }
}
