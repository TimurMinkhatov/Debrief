//
//  ScoringTests.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Testing

@Suite("Scoring")
struct ScoringTests {

    // MARK: - overallScore
    @Test func overallScoreOfEmptyRunIsZero() {
        let run = makeRun(completedAt: referenceDate, results: [])

        #expect(run.overallScore == 0)
    }

    @Test func overallScoreIsAverageOfQuestions() {
        let run = makeRun(completedAt: referenceDate, results: [
            makeResult(questionID: "a", score: 100),
            makeResult(questionID: "b", score: 50),
            makeResult(questionID: "c", score: 0)
        ])

        #expect(run.overallScore == 50)
    }

    @Test func overallScoreRoundsDown() {
        let run = makeRun(completedAt: referenceDate, results: [
            makeResult(questionID: "a", score: 70),
            makeResult(questionID: "b", score: 69)
        ])

        #expect(run.overallScore == 69)
    }

    // MARK: - estimatedGrade
    @Test(arguments: Grade.allCases)
    func passingScoreKeepsTargetGrade(target: Grade) {
        #expect(Grade.estimated(forScore: 70, target: target) == target)
        #expect(Grade.estimated(forScore: 100, target: target) == target)
    }

    @Test(arguments: [
        (Grade.intern, Grade.intern),
        (.junior, .intern),
        (.middle, .junior),
        (.senior, .middle)
    ])
    func failingScoreDropsOneGrade(target: Grade, expected: Grade) {
        #expect(Grade.estimated(forScore: 69, target: target) == expected)
        #expect(Grade.estimated(forScore: 0, target: target) == expected)
    }

    @Test func runEstimatedGradeUsesOverallScore() {
        let run = makeRun(targetGrade: .middle, completedAt: referenceDate, results: [
            makeResult(questionID: "a", score: 69)
        ])

        #expect(run.estimatedGrade == .junior)
    }

    // MARK: - RunStatistics
    @Test func latestScoreByTopicTakesMostRecentRun() {
        let questions = [makeQuestion(id: "a", topicID: "t1"), makeQuestion(id: "b", topicID: "t1"), makeQuestion(id: "c", topicID: "t2")]
        let older = makeRun(completedAt: referenceDate - 10 * day, results: [
            makeResult(questionID: "a", score: 20),
            makeResult(questionID: "c", score: 40)
        ])
        let newer = makeRun(completedAt: referenceDate, results: [makeResult(questionID: "b", score: 80)])

        let scores = RunStatistics.latestScoreByTopic(in: [older, newer], questions: questions)

        #expect(scores == ["t1": 80, "t2": 40])
    }

    @Test func latestScoreByTopicIgnoresUnknownQuestions() {
        let run = makeRun(completedAt: referenceDate, results: [makeResult(questionID: "removed", score: 50)])

        let scores = RunStatistics.latestScoreByTopic(in: [run], questions: [])

        #expect(scores.isEmpty)
    }

    // MARK: - Assessment
    @Test func assessmentCountsFullAsOneAndPartialAsHalf() {
        let assessment = Assessment(keyPoints: ["a", "b", "c", "d"], coverage: [.full, .partial, .none, .partial])

        #expect(assessment.score == 50)
        #expect(assessment.missedPoints == ["c"])
        #expect(assessment.partialPoints == ["b", "d"])
    }

    @Test func assessmentTreatsMissingCoverageAsNone() {
        let assessment = Assessment(keyPoints: ["a", "b", "c"], coverage: [.full])

        #expect(assessment.score == 33)
        #expect(assessment.missedPoints == ["b", "c"])
        #expect(assessment.partialPoints.isEmpty)
    }

    @Test func assessmentOfEmptyKeyPointsIsZero() {
        #expect(Assessment(keyPoints: [], coverage: []).score == 0)
    }

    @Test(arguments: [
        ([Coverage.full, .full, .full, .full], 100),
        ([.none, .none, .none, .none], 0),
        ([.partial, .partial, .partial, .partial], 50),
        ([.full, .partial, .none, .none], 38)
    ])
    func assessmentScoreBoundaries(coverage: [Coverage], expected: Int) {
        #expect(Assessment(keyPoints: ["a", "b", "c", "d"], coverage: coverage).score == expected)
    }

    // MARK: - Decoding
    @Test func resultWithoutPartialPointsDecodesFromOldData() throws {
        let json = """
            {"questionID":"a","turn":{"question":"q","answer":"a"},"score":50,"missedPoints":["x"]}
            """

        let result = try JSONDecoder().decode(QuestionResult.self, from: Data(json.utf8))

        #expect(result.partialPoints.isEmpty)
        #expect(result.missedPoints == ["x"])
        #expect(result.followUp == nil)
    }

    @Test func resultRoundTripsPartialPoints() throws {
        let result = QuestionResult(
            questionID: "a",
            turn: Turn(question: "q", answer: "a"),
            followUp: nil,
            score: 50,
            missedPoints: ["x"],
            partialPoints: ["y"]
        )

        let decoded = try JSONDecoder().decode(QuestionResult.self, from: JSONEncoder().encode(result))

        #expect(decoded == result)
    }

    // MARK: - Stages decoding
    @Test func questionWithoutKindIsTheory() throws {
        let json = """
            {"id":"q","topicID":"t","profession":"iosDeveloper","grade":"intern","prompt":"p","keyPoints":["a"]}
            """

        let question = try JSONDecoder().decode(Question.self, from: Data(json.utf8))

        #expect(question.kind == .theory)
        #expect(question.stage == .theory)
    }

    @Test func reviewQuestionDecodesSnippet() throws {
        let json = """
            {"id":"q","topicID":"t","profession":"iosDeveloper","grade":"intern","kind":"review","snippet":"let a = b!","prompt":"p","keyPoints":["a"]}
            """

        let question = try JSONDecoder().decode(Question.self, from: Data(json.utf8))

        #expect(question.kind == .review(snippet: "let a = b!"))
        #expect(question.kind.snippet == "let a = b!")
        #expect(question.stage == .review)
    }

    @Test func reviewQuestionWithoutSnippetFails() {
        let json = """
            {"id":"q","topicID":"t","profession":"iosDeveloper","grade":"intern","kind":"review","prompt":"p","keyPoints":["a"]}
            """

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Question.self, from: Data(json.utf8))
        }
    }

    @Test func resumeIsNotAQuestionKind() {
        let json = """
            {"id":"q","topicID":"t","profession":"iosDeveloper","grade":"intern","kind":"resume","prompt":"p","keyPoints":["a"]}
            """

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Question.self, from: Data(json.utf8))
        }
    }

    @Test func oldResultDecodesAsTheory() throws {
        let json = """
            {"questionID":"a","turn":{"question":"q","answer":"a"},"score":50,"missedPoints":[]}
            """

        let result = try JSONDecoder().decode(QuestionResult.self, from: Data(json.utf8))

        #expect(result.stage == .theory)
    }

    @Test func overallScoreIncludesReviewResults() {
        let run = makeRun(completedAt: referenceDate, results: [
            makeResult(questionID: "t", score: 100),
            QuestionResult(questionID: "r", stage: .review, turn: Turn(question: "q", answer: "a"), followUp: nil, score: 50, missedPoints: [])
        ])

        #expect(run.overallScore == 75)
        #expect(run.results(for: .review).map(\.questionID) == ["r"])
    }
}
