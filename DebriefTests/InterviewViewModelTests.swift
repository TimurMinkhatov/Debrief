//
//  InterviewViewModelTests.swift
//  DebriefTests
//
//  Created by Timur Minkhatov on 01/11/2026.
//

@testable import Debrief
import DebriefDomain
import Foundation
import Testing

@MainActor
@Suite("InterviewViewModel")
struct InterviewViewModelTests {

    private let questions = (1...3).map { makeQuestion(id: "q\($0)") }
    private let reviewTask = makeQuestion(id: "r1", kind: .review(snippet: "let x = y!"))
    private let service = StubInterviewService()
    private let runRepository = InMemoryRunRepository()
    private let router = Router()

    private func makeViewModel(
        questions: [Question]? = nil,
        profession: Profession = .iosDeveloper,
        grade: Grade = .intern
    ) -> InterviewViewModel {
        InterviewViewModel(
            user: testUser,
            profession: profession,
            grade: grade,
            questionRepository: StubQuestionRepository(questions: questions ?? self.questions),
            runRepository: runRepository,
            interviewService: service,
            router: router
        )
    }

    private func answer(_ viewModel: InterviewViewModel, _ text: String) async {
        viewModel.input = text
        await viewModel.submit()
    }

    // MARK: - Start
    @Test func startPicksQuestionsAndShowsChat() async {
        let viewModel = makeViewModel()

        await viewModel.start()

        #expect(viewModel.state.content == .answering)
        #expect(viewModel.flow.questions.count == 3)
        #expect(viewModel.title == "Теория · 1 из 3")
        #expect(viewModel.stageCaption == "Этап 1 из 2 · Теория")
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.isFromInterviewer == true)
    }

    @Test func startShowsEmptyWhenCatalogHasNothingForGrade() async {
        let viewModel = makeViewModel(grade: .senior)

        await viewModel.start()

        #expect(viewModel.state.phase == .empty)
        #expect(viewModel.emptyMessage.contains("Senior"))
    }

    @Test func startShowsErrorWhenCatalogFails() async {
        let repository = StubQuestionRepository(questions: questions)
        repository.error = TestError()
        let viewModel = InterviewViewModel(
            user: testUser,
            profession: .iosDeveloper,
            grade: .intern,
            questionRepository: repository,
            runRepository: runRepository,
            interviewService: service,
            router: router
        )

        await viewModel.start()

        #expect(viewModel.state.phase == .failed)
        repository.error = nil
        await viewModel.retry()
        #expect(viewModel.state.content == .answering)
    }

    // MARK: - Answering
    @Test func cannotSendBlankInput() async {
        let viewModel = makeViewModel()
        await viewModel.start()

        viewModel.input = "   "

        #expect(!viewModel.canSend)
    }

    @Test func followUpStaysOnSameQuestionAndShowsDialog() async {
        service.evaluateOutcomes = [.followUp("А подробнее?")]
        let viewModel = makeViewModel()
        await viewModel.start()

        await answer(viewModel, "Первый ответ")

        #expect(viewModel.flow.currentIndex == 0)
        #expect(viewModel.messages.map(\.text) == ["Вопрос \(viewModel.flow.questions[0].id)", "Первый ответ", "А подробнее?"])
        #expect(viewModel.inputPlaceholder == "Ответ на уточнение")
        #expect(viewModel.input.isEmpty)
    }

    @Test func answerToFollowUpMovesToNextQuestion() async {
        service.evaluateOutcomes = [.followUp("А подробнее?")]
        let viewModel = makeViewModel()
        await viewModel.start()

        await answer(viewModel, "Первый ответ")
        await answer(viewModel, "Второй ответ")

        #expect(viewModel.flow.currentIndex == 1)
        #expect(viewModel.flow.results.first?.score == 90)
        #expect(viewModel.inputPlaceholder == "Твой ответ")
    }

    @Test func sendErrorKeepsInputAndShowsBanner() async {
        service.answerError = TestError()
        let viewModel = makeViewModel()
        await viewModel.start()

        await answer(viewModel, "Мой ответ")

        #expect(viewModel.input == "Мой ответ")
        #expect(viewModel.sendError != nil)
        #expect(viewModel.flow.currentIndex == 0)
        #expect(!viewModel.isSending)

        viewModel.dismissSendError()
        #expect(viewModel.sendError == nil)
    }

    // MARK: - Finish
    @Test func lastAnswerSavesRunAndOpensResult() async throws {
        let viewModel = makeViewModel()
        router.push(.interview(.iosDeveloper, .intern))
        await viewModel.start()

        for index in 1...3 {
            await answer(viewModel, "Ответ \(index)")
        }
        #expect(viewModel.isResumeStep)
        await viewModel.skipResume()

        let saved = try #require(runRepository.storedRuns.first)
        #expect(runRepository.storedRuns.count == 1)
        #expect(saved.results.count == 3)
        #expect(saved.summaryText == "Хороший прогон")
        #expect(saved.userID == testUser.id)
        #expect(router.path == [.result(saved)])
    }

    @Test func verdictFailureShowsErrorAndRetryFinishes() async throws {
        service.verdictError = TestError()
        let viewModel = makeViewModel(questions: [makeQuestion(id: "only")])
        await viewModel.start()

        await answer(viewModel, "Ответ")
        await viewModel.skipResume()

        #expect(viewModel.state.phase == .failed)
        #expect(runRepository.storedRuns.isEmpty)

        service.verdictError = nil
        await viewModel.retry()

        #expect(service.verdictCalls == 2)
        let saved = try #require(runRepository.storedRuns.first)
        #expect(router.path == [.result(saved)])
    }

    // MARK: - Leaving
    @Test func exitRequiresConfirmationAndPops() async {
        let viewModel = makeViewModel()
        router.push(.interview(.iosDeveloper, .intern))
        await viewModel.start()

        #expect(viewModel.isExitGuarded)
        viewModel.requestExit()
        #expect(viewModel.isExitConfirmationPresented)

        viewModel.leave()
        #expect(router.path.isEmpty)
    }

    // MARK: - Stages
    @Test func reviewStageFollowsTheoryWithCode() async {
        let viewModel = makeViewModel(questions: [makeQuestion(id: "t1"), reviewTask])
        await viewModel.start()

        #expect(viewModel.flow.stages == [.theory, .review, .resume])
        await answer(viewModel, "Теория")

        #expect(viewModel.title == "Ревью кода · 1 из 1")
        #expect(viewModel.stageCaption == "Этап 2 из 3 · Ревью кода")
        #expect(viewModel.messages.first?.code == "let x = y!")
    }

    @Test func resumeStepSendsReviewIntoVerdictAndRun() async throws {
        let viewModel = makeViewModel(questions: [makeQuestion(id: "t1")])
        await viewModel.start()
        await answer(viewModel, "Теория")

        #expect(viewModel.isResumeStep)
        #expect(viewModel.title == "Резюме")
        #expect(viewModel.inputPlaceholder == "Текст резюме")
        #expect(viewModel.messages.isEmpty)

        await answer(viewModel, "Мой опыт: 2 года SwiftUI")

        let saved = try #require(runRepository.storedRuns.first)
        #expect(saved.resumeReview == service.resumeReview)
        #expect(service.verdictResumeReviews == [service.resumeReview])
        #expect(router.path == [.result(saved)])
    }

    @Test func skippedResumeSavesRunWithoutReview() async throws {
        let viewModel = makeViewModel(questions: [makeQuestion(id: "t1")])
        await viewModel.start()
        await answer(viewModel, "Теория")

        viewModel.input = "черновик"
        await viewModel.skipResume()

        let saved = try #require(runRepository.storedRuns.first)
        #expect(saved.resumeReview == nil)
        #expect(service.verdictResumeReviews == [nil])
    }

    @Test func resumeErrorKeepsTextAndStep() async {
        service.resumeError = TestError()
        let viewModel = makeViewModel(questions: [makeQuestion(id: "t1")])
        await viewModel.start()
        await answer(viewModel, "Теория")

        await answer(viewModel, "Резюме")

        #expect(viewModel.isResumeStep)
        #expect(viewModel.input == "Резюме")
        #expect(viewModel.sendError != nil)
        #expect(runRepository.storedRuns.isEmpty)
    }

    @Test func onlyReviewTasksMeansEmpty() async {
        let viewModel = makeViewModel(questions: [reviewTask])

        await viewModel.start()

        #expect(viewModel.state.phase == .empty)
    }
}
