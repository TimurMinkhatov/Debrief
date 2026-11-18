//
//  Interview.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 15/09/2026.
//

import Foundation

// MARK: - QuestionResult
public struct QuestionResult: Identifiable, Codable, Hashable, Sendable {
    public let questionID: String
    public let stage: StageKind
    public let turn: Turn
    public let followUp: Turn?
    public let score: Int
    public let missedPoints: [String]
    public let partialPoints: [String]

    public var id: String { questionID }

    public static func averageScore(of results: [QuestionResult]) -> Int {
        guard !results.isEmpty else {
            return 0
        }
        return results.reduce(0) { $0 + $1.score } / results.count
    }

    public init(
        questionID: String,
        stage: StageKind = .theory,
        turn: Turn,
        followUp: Turn?,
        score: Int,
        missedPoints: [String],
        partialPoints: [String] = []
    ) {
        self.questionID = questionID
        self.stage = stage
        self.turn = turn
        self.followUp = followUp
        self.score = score
        self.missedPoints = missedPoints
        self.partialPoints = partialPoints
    }

    public init(questionID: String, stage: StageKind, turn: Turn, followUp: Turn?, assessment: Assessment) {
        self.init(
            questionID: questionID,
            stage: stage,
            turn: turn,
            followUp: followUp,
            score: assessment.score,
            missedPoints: assessment.missedPoints,
            partialPoints: assessment.partialPoints
        )
    }

    private enum CodingKeys: String, CodingKey {
        case questionID
        case stage
        case turn
        case followUp
        case score
        case missedPoints
        case partialPoints
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.questionID = try container.decode(String.self, forKey: .questionID)
        self.stage = try container.decodeIfPresent(StageKind.self, forKey: .stage) ?? .theory
        self.turn = try container.decode(Turn.self, forKey: .turn)
        self.followUp = try container.decodeIfPresent(Turn.self, forKey: .followUp)
        self.score = try container.decode(Int.self, forKey: .score)
        self.missedPoints = try container.decode([String].self, forKey: .missedPoints)
        self.partialPoints = try container.decodeIfPresent([String].self, forKey: .partialPoints) ?? []
    }
}

// MARK: - Coverage
public enum Coverage: String, Codable, Sendable {
    case full
    case partial
    case none
}

// MARK: - Assessment
public struct Assessment: Equatable, Sendable {
    public let score: Int
    public let missedPoints: [String]
    public let partialPoints: [String]

    public init(score: Int, missedPoints: [String], partialPoints: [String] = []) {
        self.score = score
        self.missedPoints = missedPoints
        self.partialPoints = partialPoints
    }

    public init(keyPoints: [String], coverage: [Coverage]) {
        let pairs = keyPoints.enumerated().map { index, point in
            (point: point, coverage: coverage.indices.contains(index) ? coverage[index] : .none)
        }
        let earned = pairs.reduce(0.0) { total, pair in
            switch pair.coverage {
            case .full: total + 1
            case .partial: total + 0.5
            case .none: total
            }
        }
        self.init(
            score: keyPoints.isEmpty ? 0 : Int((earned / Double(keyPoints.count) * 100).rounded()),
            missedPoints: pairs.filter { $0.coverage == .none }.map(\.point),
            partialPoints: pairs.filter { $0.coverage == .partial }.map(\.point)
        )
    }
}

// MARK: - InterviewRun
public struct InterviewRun: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let userID: UUID
    public let profession: Profession
    public let targetGrade: Grade
    public let completedAt: Date
    public let results: [QuestionResult]
    public let resumeReview: ResumeReview?
    public let summaryText: String

    public var overallScore: Int {
        QuestionResult.averageScore(of: results)
    }

    public var estimatedGrade: Grade {
        Grade.estimated(forScore: overallScore, target: targetGrade)
    }

    public init(
        id: UUID = UUID(),
        userID: UUID,
        profession: Profession,
        targetGrade: Grade,
        completedAt: Date = Date(),
        results: [QuestionResult],
        resumeReview: ResumeReview? = nil,
        summaryText: String
    ) {
        self.id = id
        self.userID = userID
        self.profession = profession
        self.targetGrade = targetGrade
        self.completedAt = completedAt
        self.results = results
        self.resumeReview = resumeReview
        self.summaryText = summaryText
    }

    public func results(for stage: StageKind) -> [QuestionResult] {
        results.filter { $0.stage == stage }
    }
}

// MARK: - ResumeReview
public struct ResumeReview: Codable, Hashable, Sendable {
    public let summary: String
    public let strengths: [String]
    public let gaps: [String]

    public init(summary: String, strengths: [String], gaps: [String]) {
        self.summary = summary
        self.strengths = strengths
        self.gaps = gaps
    }
}

// MARK: - Turn
public struct Turn: Codable, Hashable, Sendable {
    public let question: String
    public let answer: String

    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

// MARK: - QuestionOutcome
public enum QuestionOutcome: Equatable, Sendable {
    case followUp(String)
    case finished(Assessment)
}

// MARK: - InterviewFlow
public struct InterviewFlow: Sendable {

    public enum Step: Equatable, Sendable {
        case question(Question)
        case resume
    }

    public struct PendingFollowUp: Equatable, Sendable {
        public let turn: Turn
        public let question: String
    }

    public let questions: [Question]
    public let profession: Profession
    public let grade: Grade
    public let includesResume: Bool
    public private(set) var results: [QuestionResult] = []
    public private(set) var pendingFollowUp: PendingFollowUp?
    public private(set) var resumeReview: ResumeReview?
    public private(set) var isResumeCompleted = false

    public init(questions: [Question], profession: Profession, grade: Grade, includesResume: Bool = true) {
        self.questions = StageKind.allCases.flatMap { stage in questions.filter { $0.stage == stage } }
        self.profession = profession
        self.grade = grade
        self.includesResume = includesResume
    }

    // MARK: - Progress
    public var stages: [StageKind] {
        StageKind.allCases.filter { stage in
            stage == .resume ? includesResume && !questions.isEmpty : questions.contains { $0.stage == stage }
        }
    }

    public var currentQuestion: Question? {
        questions.indices.contains(results.count) ? questions[results.count] : nil
    }

    public var currentStep: Step? {
        if let currentQuestion {
            return .question(currentQuestion)
        }
        guard includesResume, !questions.isEmpty, !isResumeCompleted else {
            return nil
        }
        return .resume
    }

    public var currentStage: StageKind? {
        switch currentStep {
        case .question(let question): question.stage
        case .resume: .resume
        case nil: nil
        }
    }

    public var currentIndex: Int { results.count }

    public var totalSteps: Int {
        questions.count + (stages.contains(.resume) ? 1 : 0)
    }

    public var completedSteps: Int {
        results.count + (isResumeCompleted ? 1 : 0)
    }

    public func questions(in stage: StageKind) -> [Question] {
        questions.filter { $0.stage == stage }
    }

    public func answeredCount(in stage: StageKind) -> Int {
        results.filter { $0.stage == stage }.count
    }

    public var isFinished: Bool {
        !questions.isEmpty && currentStep == nil
    }

    // MARK: - Actions
    public mutating func answer(_ text: String, using service: any InterviewServiceProtocol) async throws {
        let answer = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty, let step = currentStep else {
            return
        }

        switch step {
        case .resume:
            resumeReview = try await service.reviewResume(text: answer, profession: profession, targetGrade: grade)
            isResumeCompleted = true
        case .question(let question):
            try await answerQuestion(question, text: answer, using: service)
        }
    }

    public mutating func skipResume() {
        guard currentStep == .resume else { return }
        isResumeCompleted = true
    }

    public func makeRun(userID: UUID, summaryText: String, completedAt: Date = Date()) -> InterviewRun? {
        guard isFinished else {
            return nil
        }
        return InterviewRun(
            userID: userID,
            profession: profession,
            targetGrade: grade,
            completedAt: completedAt,
            results: results,
            resumeReview: resumeReview,
            summaryText: summaryText
        )
    }

    private mutating func answerQuestion(_ question: Question, text: String, using service: any InterviewServiceProtocol) async throws {
        if let pendingFollowUp {
            let followUp = Turn(question: pendingFollowUp.question, answer: text)
            let assessment = try await service.score(question: question, turn: pendingFollowUp.turn, followUp: followUp)
            complete(question: question, turn: pendingFollowUp.turn, followUp: followUp, assessment: assessment)
            return
        }

        let turn = Turn(question: question.prompt, answer: text)
        switch try await service.evaluate(question: question, answer: text) {
        case .followUp(let followUpQuestion):
            pendingFollowUp = PendingFollowUp(turn: turn, question: followUpQuestion)
        case .finished(let assessment):
            complete(question: question, turn: turn, followUp: nil, assessment: assessment)
        }
    }

    private mutating func complete(question: Question, turn: Turn, followUp: Turn?, assessment: Assessment) {
        results.append(QuestionResult(
            questionID: question.id,
            stage: question.stage,
            turn: turn,
            followUp: followUp,
            assessment: assessment
        ))
        pendingFollowUp = nil
    }
}
