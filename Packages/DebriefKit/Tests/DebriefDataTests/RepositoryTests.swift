//
//  RepositoryTests.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefData
import DebriefDomain
import Foundation
import SwiftData
import Testing

@MainActor
private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Schema(DebriefSchema.models), configurations: configuration)
    return ModelContext(container)
}

private func makeRun(userID: UUID, completedAt: Date, score: Int = 50, summary: String = "итог") -> InterviewRun {
    InterviewRun(
        userID: userID,
        profession: .iosDeveloper,
        targetGrade: .junior,
        completedAt: completedAt,
        results: [
            QuestionResult(
                questionID: "arc-weak",
                turn: Turn(question: "Что такое weak?", answer: "Слабая ссылка"),
                followUp: Turn(question: "Почему опционал?", answer: "Обнуляется"),
                score: score,
                missedPoints: ["weak всегда опциональная var"]
            ),
            QuestionResult(
                questionID: "optionals-basics",
                turn: Turn(question: "Что такое опционал?", answer: "Перечисление"),
                followUp: nil,
                score: 100,
                missedPoints: []
            )
        ],
        summaryText: summary
    )
}

// MARK: - RunRepository
@Suite("RunRepository")
@MainActor
struct RunRepositoryTests {

    @Test func savedRunRoundTripsWithoutLoss() async throws {
        let repository = RunRepository(context: try makeContext())
        let userID = UUID()
        let run = makeRun(userID: userID, completedAt: Date(timeIntervalSince1970: 1_800_000_000))

        try await repository.save(run)
        let loaded = try await repository.runs(for: userID)

        #expect(loaded == [run])
    }

    @Test func resumeReviewAndStagesRoundTrip() async throws {
        let repository = RunRepository(context: try makeContext())
        let userID = UUID()
        let run = InterviewRun(
            userID: userID,
            profession: .systemAnalyst,
            targetGrade: .senior,
            completedAt: Date(timeIntervalSince1970: 1_800_000_000),
            results: [QuestionResult(
                questionID: "sa-review-sql-having",
                stage: .review,
                turn: Turn(question: "Найди ошибки", answer: "HAVING"),
                followUp: nil,
                score: 75,
                missedPoints: ["псевдоним"],
                partialPoints: ["JOIN"]
            )],
            resumeReview: ResumeReview(summary: "Сильный опыт", strengths: ["SQL"], gaps: ["Нет метрик"]),
            summaryText: "итог"
        )

        try await repository.save(run)

        #expect(try await repository.runs(for: userID) == [run])
    }

    @Test func runsAreFilteredByUser() async throws {
        let repository = RunRepository(context: try makeContext())
        let me = UUID()
        let other = UUID()

        try await repository.save(makeRun(userID: me, completedAt: .now))
        try await repository.save(makeRun(userID: other, completedAt: .now))

        let mine = try await repository.runs(for: me)
        #expect(mine.count == 1)
        #expect(mine.allSatisfy { $0.userID == me })
        #expect(try await repository.runs(for: UUID()).isEmpty)
    }

    @Test func runsAreSortedNewestFirst() async throws {
        let repository = RunRepository(context: try makeContext())
        let userID = UUID()
        let base = Date(timeIntervalSince1970: 1_800_000_000)

        try await repository.save(makeRun(userID: userID, completedAt: base))
        try await repository.save(makeRun(userID: userID, completedAt: base + 200))
        try await repository.save(makeRun(userID: userID, completedAt: base + 100))

        let dates = try await repository.runs(for: userID).map(\.completedAt)
        #expect(dates == [base + 200, base + 100, base])
    }

    @Test func savingSameRunTwiceUpdatesInsteadOfDuplicating() async throws {
        let repository = RunRepository(context: try makeContext())
        let userID = UUID()
        let run = makeRun(userID: userID, completedAt: .now, summary: "черновик")
        let updated = InterviewRun(
            id: run.id,
            userID: userID,
            profession: run.profession,
            targetGrade: run.targetGrade,
            completedAt: run.completedAt,
            results: run.results,
            summaryText: "финал"
        )

        try await repository.save(run)
        try await repository.save(updated)

        let loaded = try await repository.runs(for: userID)
        #expect(loaded.count == 1)
        #expect(loaded.first?.summaryText == "финал")
    }
}

// MARK: - UserRepository
@Suite("UserRepository")
@MainActor
struct UserRepositoryTests {

    @Test func returnsNilWhenNoUser() async throws {
        let repository = UserRepository(context: try makeContext())

        #expect(try await repository.findUser() == nil)
    }

    @Test func savesAndUpdatesSingleUser() async throws {
        let repository = UserRepository(context: try makeContext())
        var user = User(name: "Тимур", profession: .iosDeveloper, targetGrade: .intern)

        try await repository.save(user)
        user.name = "Тимур М."
        user.targetGrade = .junior
        try await repository.save(user)

        let loaded = try #require(try await repository.findUser())
        #expect(loaded.id == user.id)
        #expect(loaded.name == "Тимур М.")
        #expect(loaded.targetGrade == .junior)
    }
}
