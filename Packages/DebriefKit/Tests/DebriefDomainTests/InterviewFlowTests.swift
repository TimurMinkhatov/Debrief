//
//  InterviewFlowTests.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Testing

@Suite("InterviewFlow")
struct InterviewFlowTests {

    private let questions = [makeQuestion(id: "q1"), makeQuestion(id: "q2")]

    // MARK: - Start
    @Test func startsAtFirstQuestion() {
        let flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)

        #expect(flow.currentQuestion?.id == "q1")
        #expect(flow.currentIndex == 0)
        #expect(!flow.isFinished)
        #expect(flow.pendingFollowUp == nil)
    }

    @Test func emptyFlowIsNeverFinished() {
        let flow = InterviewFlow(questions: [], profession: .iosDeveloper, grade: .intern)

        #expect(flow.currentQuestion == nil)
        #expect(!flow.isFinished)
        #expect(flow.makeRun(userID: UUID(), summaryText: "") == nil)
    }

    // MARK: - Answering
    @Test func finishedOutcomeRecordsResultAndAdvances() async throws {
        let service = StubInterviewService()
        service.evaluateOutcome = .finished(Assessment(score: 75, missedPoints: ["b"], partialPoints: ["a"]))
        var flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)

        try await flow.answer("  ответ  ", using: service)

        #expect(flow.currentQuestion?.id == "q2")
        #expect(flow.results == [QuestionResult(
            questionID: "q1",
            turn: Turn(question: "prompt-q1", answer: "ответ"),
            followUp: nil,
            score: 75,
            missedPoints: ["b"],
            partialPoints: ["a"]
        )])
        #expect(service.evaluateCalls.map(\.answer) == ["ответ"])
    }

    @Test func followUpKeepsCurrentQuestion() async throws {
        let service = StubInterviewService()
        service.evaluateOutcome = .followUp("А что с weak?")
        var flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)

        try await flow.answer("первый", using: service)

        #expect(flow.currentQuestion?.id == "q1")
        #expect(flow.results.isEmpty)
        #expect(flow.pendingFollowUp?.turn == Turn(question: "prompt-q1", answer: "первый"))
        #expect(flow.pendingFollowUp?.question == "А что с weak?")
    }

    @Test func answerToFollowUpIsScoredAndReplacesPreliminaryScore() async throws {
        let service = StubInterviewService()
        service.evaluateOutcome = .followUp("уточнение")
        service.scoreResult = Assessment(score: 90, missedPoints: [])
        var flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)

        try await flow.answer("первый", using: service)
        try await flow.answer("второй", using: service)

        #expect(service.evaluateCalls.count == 1)
        #expect(service.scoreCalls.count == 1)
        #expect(service.scoreCalls.first?.turn == Turn(question: "prompt-q1", answer: "первый"))
        #expect(service.scoreCalls.first?.followUp == Turn(question: "уточнение", answer: "второй"))
        #expect(flow.results.first?.score == 90)
        #expect(flow.results.first?.followUp == Turn(question: "уточнение", answer: "второй"))
        #expect(flow.pendingFollowUp == nil)
        #expect(flow.currentQuestion?.id == "q2")
    }

    @Test func atMostOneFollowUpPerQuestion() async throws {
        let service = StubInterviewService()
        service.evaluateOutcome = .followUp("уточнение")
        var flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)

        try await flow.answer("первый", using: service)
        try await flow.answer("второй", using: service)
        try await flow.answer("третий", using: service)

        #expect(flow.results.map(\.questionID) == ["q1"])
        #expect(flow.pendingFollowUp?.turn.answer == "третий")
        #expect(service.evaluateCalls.map(\.question.id) == ["q1", "q2"])
    }

    @Test func blankAnswerIsIgnored() async throws {
        let service = StubInterviewService()
        var flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)

        try await flow.answer(" \n ", using: service)

        #expect(service.evaluateCalls.isEmpty)
        #expect(flow.currentIndex == 0)
    }

    @Test func failedCallLeavesCopyUntouched() async {
        let service = StubInterviewService()
        service.error = StubError()
        let flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)
        var attempt = flow

        await #expect(throws: StubError.self) {
            try await attempt.answer("ответ", using: service)
        }
        #expect(attempt.currentIndex == 0)
        #expect(attempt.results.isEmpty)
    }

    // MARK: - Finish
    @Test func finishesAfterLastQuestionAndBuildsRun() async throws {
        let service = StubInterviewService()
        service.evaluateOutcome = .finished(Assessment(score: 60, missedPoints: []))
        var flow = InterviewFlow(questions: questions, profession: .iosDeveloper, grade: .intern, includesResume: false)
        let userID = UUID()

        try await flow.answer("один", using: service)
        #expect(flow.makeRun(userID: userID, summaryText: "") == nil)
        try await flow.answer("два", using: service)

        #expect(flow.isFinished)
        #expect(flow.currentQuestion == nil)
        let run = try #require(flow.makeRun(
            userID: userID,
            summaryText: "итог",
            completedAt: referenceDate
        ))
        #expect(run.userID == userID)
        #expect(run.targetGrade == .intern)
        #expect(run.completedAt == referenceDate)
        #expect(run.summaryText == "итог")
        #expect(run.results.map(\.questionID) == ["q1", "q2"])
    }

    @Test func answersAfterFinishAreIgnored() async throws {
        let service = StubInterviewService()
        var flow = InterviewFlow(questions: [makeQuestion(id: "only")], profession: .iosDeveloper, grade: .intern, includesResume: false)

        try await flow.answer("один", using: service)
        try await flow.answer("лишний", using: service)

        #expect(service.evaluateCalls.count == 1)
        #expect(flow.results.count == 1)
    }

    // MARK: - Stages
    private func stagedFlow(includesResume: Bool = true) -> InterviewFlow {
        InterviewFlow(
            questions: [
                makeQuestion(id: "r1", kind: .review(snippet: "let x = y!")),
                makeQuestion(id: "t1"),
                makeQuestion(id: "t2")
            ],
            profession: .systemAnalyst,
            grade: .middle,
            includesResume: includesResume
        )
    }

    @Test func questionsAreOrderedByStage() {
        let flow = stagedFlow()

        #expect(flow.questions.map(\.id) == ["t1", "t2", "r1"])
        #expect(flow.stages == [.theory, .review, .resume])
        #expect(flow.currentStage == .theory)
        #expect(flow.totalSteps == 4)
    }

    @Test func stagesSkipMissingKinds() {
        let flow = InterviewFlow(questions: [makeQuestion(id: "t1")], profession: .iosDeveloper, grade: .intern, includesResume: false)

        #expect(flow.stages == [.theory])
        #expect(flow.totalSteps == 1)
    }

    @Test func reviewResultsCarryStageAndResumeComesLast() async throws {
        let service = StubInterviewService()
        var flow = stagedFlow()

        for text in ["один", "два", "три"] {
            try await flow.answer(text, using: service)
        }

        #expect(flow.results.map(\.stage) == [.theory, .theory, .review])
        #expect(flow.currentStep == .resume)
        #expect(flow.currentStage == .resume)
        #expect(!flow.isFinished)
        #expect(flow.answeredCount(in: .review) == 1)
    }

    @Test func resumeAnswerProducesReviewAndFinishes() async throws {
        let service = StubInterviewService()
        var flow = stagedFlow()
        for text in ["один", "два", "три"] {
            try await flow.answer(text, using: service)
        }

        try await flow.answer("  Резюме кандидата  ", using: service)

        #expect(flow.isFinished)
        #expect(flow.resumeReview == service.resumeReview)
        #expect(service.resumeCalls.first?.text == "Резюме кандидата")
        #expect(service.resumeCalls.first?.profession == .systemAnalyst)
        #expect(service.resumeCalls.first?.grade == .middle)
        let run = try #require(flow.makeRun(userID: UUID(), summaryText: "итог"))
        #expect(run.resumeReview == service.resumeReview)
        #expect(run.results(for: .review).map(\.questionID) == ["r1"])
    }

    @Test func skipResumeFinishesWithoutReview() async throws {
        let service = StubInterviewService()
        var flow = stagedFlow()
        flow.skipResume()
        #expect(flow.currentStage == .theory)

        for text in ["один", "два", "три"] {
            try await flow.answer(text, using: service)
        }
        flow.skipResume()

        #expect(flow.isFinished)
        #expect(flow.completedSteps == flow.totalSteps)
        #expect(service.resumeCalls.isEmpty)
        #expect(try #require(flow.makeRun(userID: UUID(), summaryText: "")).resumeReview == nil)
    }

    @Test func failedResumeReviewKeepsStep() async throws {
        let service = StubInterviewService()
        var flow = stagedFlow()
        for text in ["один", "два", "три"] {
            try await flow.answer(text, using: service)
        }
        service.error = StubError()

        await #expect(throws: StubError.self) {
            try await flow.answer("резюме", using: service)
        }
        #expect(flow.currentStep == .resume)
    }
}
