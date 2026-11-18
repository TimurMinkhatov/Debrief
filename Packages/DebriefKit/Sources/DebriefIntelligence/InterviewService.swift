//
//  InterviewService.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 08/10/2026.
//

import DebriefDomain
import Foundation
import FoundationModels
import OSLog

public final class InterviewService: InterviewServiceProtocol {

    private static let logger = Logger(subsystem: "tim.Debrief", category: "InterviewService")

    private let chain: ModelChain

    public convenience init() {
        self.init(chain: ModelChain(providers: [GeminiModelProvider()]))
    }

    init(chain: ModelChain) {
        self.chain = chain
    }

    public func evaluate(question: Question, answer: String) async throws -> QuestionOutcome {
        try await perform("evaluate") {
            let session = try makeSession(instructions: Prompts.instructionForEvaluation(profession: question.profession))
            let prompt = Prompts.evaluation(question: question, answer: answer)
            let response = try await session.respond(to: prompt, generating: Evaluation.self)
            return response.content.outcome(for: question)
        }
    }

    public func score(question: Question, turn: Turn, followUp: Turn) async throws -> Assessment {
        try await perform("score") {
            let session = try makeSession(instructions: Prompts.instructionForScore(profession: question.profession))
            let prompt = Prompts.scoring(question: question, turn: turn, followUp: followUp)
            let response = try await session.respond(to: prompt, generating: Score.self)
            return response.content.assessment(for: question)
        }
    }

    public func reviewResume(text: String, profession: Profession, targetGrade: Grade) async throws -> ResumeReview {
        try await perform("reviewResume") {
            let session = try makeSession(instructions: Prompts.instructionForResume(profession: profession))
            let prompt = Prompts.resume(text: text, targetGrade: targetGrade)
            let response = try await session.respond(to: prompt, generating: ResumeAnalysis.self)
            return response.content.review
        }
    }

    public func verdict(
        results: [QuestionResult],
        questions: [Question],
        resumeReview: ResumeReview?,
        profession: Profession,
        targetGrade: Grade
    ) async throws -> String {
        try await perform("verdict") {
            let session = try makeSession(instructions: Prompts.instructionForVerdict(profession: profession))
            let prompt = Prompts.verdict(
                results: results,
                questions: questions,
                resumeReview: resumeReview,
                targetGrade: targetGrade
            )
            let response = try await session.respond(to: prompt)
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func perform<Value>(_ operation: String, _ work: () async throws -> Value) async throws -> Value {
        do {
            return try await work()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            Self.logger.error("\(operation, privacy: .public) failed: \(String(reflecting: error), privacy: .public)")
            throw IntelligenceError(error)
        }
    }

    private func makeSession(instructions: String) throws -> LanguageModelSession {
        LanguageModelSession(model: try chain.makeModel(), instructions: instructions)
    }
}
