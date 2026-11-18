//
//  Protocols.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 15/09/2026.
//

import Foundation

public protocol QuestionRepositoryProtocol: Sendable {
    func topics() async throws -> [Topic]
    func questions() async throws -> [Question]
}

public protocol UserRepositoryProtocol: Sendable {
    func findUser() async throws -> User?
    func save(_ user: User) async throws
}

public protocol RunRepositoryProtocol: Sendable {
    func runs(for userID: UUID) async throws -> [InterviewRun]
    func save(_ run: InterviewRun) async throws
}

public protocol InterviewServiceProtocol: Sendable {
    func evaluate(question: Question, answer: String) async throws -> QuestionOutcome
    func score(question: Question, turn: Turn, followUp: Turn) async throws -> Assessment
    func reviewResume(text: String, profession: Profession, targetGrade: Grade) async throws -> ResumeReview
    func verdict(
        results: [QuestionResult],
        questions: [Question],
        resumeReview: ResumeReview?,
        profession: Profession,
        targetGrade: Grade
    ) async throws -> String
}
