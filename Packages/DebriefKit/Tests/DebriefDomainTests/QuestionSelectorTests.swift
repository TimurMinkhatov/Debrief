//
//  QuestionSelectorTests.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

@testable import DebriefDomain
import Foundation
import Testing

@Suite("QuestionSelector")
struct QuestionSelectorTests {

    // MARK: - Filtering
    @Test func picksOnlyTargetProfessionAndGrade() {
        let questions = [
            makeQuestion(id: "intern-1"),
            makeQuestion(id: "intern-2"),
            makeQuestion(id: "junior-1", grade: .junior),
            makeQuestion(id: "middle-1", grade: .middle)
        ]
        var generator = SeededGenerator(seed: 1)

        let picked = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            pastRuns: [],
            date: referenceDate,
            using: &generator
        )

        #expect(Set(picked.map(\.id)) == ["intern-1", "intern-2"])
    }

    @Test func returnsEmptyWhenNothingMatchesGrade() {
        let questions = [makeQuestion(id: "intern-1")]

        let picked = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .senior,
            pastRuns: []
        )

        #expect(picked.isEmpty)
    }

    @Test func returnsEmptyForEmptyCatalog() {
        let picked = QuestionSelector.pick(from: [], targetProfession: .iosDeveloper, targetGrade: .intern, pastRuns: [])

        #expect(picked.isEmpty)
    }

    // MARK: - Count and topics
    @Test func respectsQuestionCount() {
        let questions = (0..<30).map { makeQuestion(id: "q\($0)") }
        var generator = SeededGenerator(seed: 2)

        let picked = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            pastRuns: [],
            date: referenceDate,
            using: &generator
        )

        #expect(picked.count == SelectionRules.theoryCount)
        #expect(Set(picked.map(\.id)).count == picked.count)
    }

    @Test(arguments: 0..<20)
    func picksAtMostOneQuestionPerTopic(seed: Int) {
        let questions = (0..<6).flatMap { topic in
            (0..<3).map { makeQuestion(id: "t\(topic)-q\($0)", topicID: "t\(topic)") }
        }
        var generator = SeededGenerator(seed: UInt64(seed))

        let picked = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            pastRuns: [],
            date: referenceDate,
            using: &generator
        )

        #expect(picked.count == 6)
        #expect(Set(picked.map(\.topicID)).count == picked.count)
    }

    // MARK: - Cooldown
    @Test func skipsQuestionsAskedWithinCooldown() {
        let questions = [makeQuestion(id: "recent"), makeQuestion(id: "old"), makeQuestion(id: "new")]
        let runs = [
            makeRun(completedAt: referenceDate - 3 * day, results: [makeResult(questionID: "recent", score: 0)]),
            makeRun(completedAt: referenceDate - 20 * day, results: [makeResult(questionID: "old", score: 0)])
        ]

        for seed in 0..<20 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let picked = QuestionSelector.pick(
                from: questions,
                targetProfession: .iosDeveloper,
                targetGrade: .intern,
                pastRuns: runs,
                date: referenceDate,
                using: &generator
            )
            #expect(Set(picked.map(\.id)) == ["old", "new"])
        }
    }

    @Test func cooldownUsesMostRecentRun() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b")]
        let runs = [
            makeRun(completedAt: referenceDate - 30 * day, results: [makeResult(questionID: "a", score: 0)]),
            makeRun(completedAt: referenceDate - 1 * day, results: [makeResult(questionID: "a", score: 0)])
        ]
        var generator = SeededGenerator(seed: 3)

        let picked = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            pastRuns: runs,
            date: referenceDate,
            using: &generator
        )

        #expect(picked.map(\.id) == ["b"])
    }

    @Test func fallsBackToWholePoolWhenEverythingIsOnCooldown() {
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b")]
        let runs = [makeRun(
            completedAt: referenceDate - day,
            results: [makeResult(questionID: "a", score: 50), makeResult(questionID: "b", score: 50)]
        )]
        var generator = SeededGenerator(seed: 4)

        let picked = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            pastRuns: runs,
            date: referenceDate,
            using: &generator
        )

        #expect(Set(picked.map(\.id)) == ["a", "b"])
    }

    // MARK: - Weights
    @Test func unaskedQuestionGetsMaxWeight() {
        let weight = QuestionSelector.weight(for: makeQuestion(id: "a"), attempts: [:])

        #expect(weight == SelectionRules.maxWeight)
    }

    @Test(arguments: [(0, 100), (40, 60), (90, 10), (95, 10), (100, 10)])
    func weightIsInverseOfLastScoreWithFloor(score: Int, expected: Int) {
        let attempts = ["a": (askedAt: referenceDate, score: score)]

        let weight = QuestionSelector.weight(for: makeQuestion(id: "a"), attempts: attempts)

        #expect(weight == expected)
    }

    @Test func lastAttemptTakesMostRecentRunRegardlessOfOrder() {
        let older = makeRun(completedAt: referenceDate - 20 * day, results: [makeResult(questionID: "a", score: 10)])
        let newer = makeRun(completedAt: referenceDate - 15 * day, results: [makeResult(questionID: "a", score: 90)])

        let attempts = QuestionSelector.lastAttempts(in: [older, newer])

        #expect(attempts["a"]?.score == 90)
        #expect(attempts["a"]?.askedAt == newer.completedAt)
    }

    @Test func weakQuestionsArePickedMoreOften() {
        let questions = [makeQuestion(id: "mastered", topicID: "t"), makeQuestion(id: "weak", topicID: "t")]
        let runs = [makeRun(
            completedAt: referenceDate - 30 * day,
            results: [makeResult(questionID: "mastered", score: 100), makeResult(questionID: "weak", score: 0)]
        )]
        var generator = SeededGenerator(seed: 5)
        var weakCount = 0
        let trials = 2_000

        for _ in 0..<trials {
            let picked = QuestionSelector.pick(
                from: questions,
                targetProfession: .iosDeveloper,
                targetGrade: .intern,
                pastRuns: runs,
                date: referenceDate,
                using: &generator
            )
            if picked.first?.id == "weak" {
                weakCount += 1
            }
        }

        let share = Double(weakCount) / Double(trials)
        #expect(share > 0.85 && share < 0.95)
    }

    // MARK: - Index for weights
    @Test func indexForEmptyWeightsIsNil() {
        var generator = SeededGenerator(seed: 6)

        #expect(QuestionSelector.index(forWeights: [], using: &generator) == nil)
    }

    @Test func indexNeverPicksZeroWeight() {
        var generator = SeededGenerator(seed: 7)

        for _ in 0..<500 {
            #expect(QuestionSelector.index(forWeights: [0, 5, 0], using: &generator) == 1)
        }
    }

    // MARK: - Stages
    @Test func picksOnlyRequestedStage() {
        let questions = (0..<5).map { makeQuestion(id: "t\($0)") }
            + (0..<5).map { makeQuestion(id: "r\($0)", kind: .review(snippet: "code")) }
        var generator = SeededGenerator(seed: 8)

        let theory = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            stage: .theory,
            pastRuns: [],
            date: referenceDate,
            using: &generator
        )
        let review = QuestionSelector.pick(
            from: questions,
            targetProfession: .iosDeveloper,
            targetGrade: .intern,
            stage: .review,
            pastRuns: [],
            date: referenceDate,
            using: &generator
        )

        #expect(theory.allSatisfy { $0.stage == .theory })
        #expect(theory.count == 5)
        #expect(review.allSatisfy { $0.stage == .review })
        #expect(review.count == SelectionRules.reviewCount)
    }

    @Test func resumeStageHasNoQuestions() {
        #expect(SelectionRules.questionCount(for: .resume) == 0)
        #expect(QuestionSelector.pick(from: [makeQuestion(id: "t")], targetProfession: .iosDeveloper, targetGrade: .intern, stage: .resume, pastRuns: []).isEmpty)
    }
}
