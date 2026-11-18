//
//  InterviewViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 07/10/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class InterviewViewModel {

    enum Stage: Hashable {
        case answering
        case finishing
    }

    private let user: User
    private let profession: Profession
    private let grade: Grade
    private let questionRepository: any QuestionRepositoryProtocol
    private let runRepository: any RunRepositoryProtocol
    private let interviewService: any InterviewServiceProtocol
    private let router: Router

    private(set) var state: ScreenState<Stage> = .loading
    private(set) var flow: InterviewFlow
    private(set) var isSending = false
    private(set) var pendingAnswer: String?
    private(set) var sendError: Error?

    var input: String = ""
    var isExitConfirmationPresented = false

    let resumeTitle = "Разбор резюме"
    let resumeMessage = "Вставь текст своего резюме: модель оценит его под выбранный грейд и подскажет, что усилить. Этап можно пропустить."
    let resumeSubmitTitle = "Разобрать резюме"
    let resumeSkipTitle = "Пропустить"

    init(
        user: User,
        profession: Profession,
        grade: Grade,
        questionRepository: any QuestionRepositoryProtocol,
        runRepository: any RunRepositoryProtocol,
        interviewService: any InterviewServiceProtocol,
        router: Router
    ) {
        self.user = user
        self.profession = profession
        self.grade = grade
        self.questionRepository = questionRepository
        self.runRepository = runRepository
        self.interviewService = interviewService
        self.router = router
        self.flow = InterviewFlow(questions: [], profession: profession, grade: grade)
    }

    // MARK: - Presentation
    var title: String {
        guard state.content == .answering, let stage = flow.currentStage else {
            return "Собеседование"
        }
        guard stage != .resume else {
            return stage.title(for: profession)
        }
        let total = flow.questions(in: stage).count
        let current = min(flow.answeredCount(in: stage) + 1, total)
        return "\(stage.title(for: profession)) · \(current) из \(total)"
    }

    var stageCaption: String? {
        guard let stage = flow.currentStage, let index = flow.stages.firstIndex(of: stage) else {
            return nil
        }
        return "Этап \(index + 1) из \(flow.stages.count) · \(stage.title(for: profession))"
    }

    var currentStageSymbol: String? {
        flow.currentStage?.symbolName
    }

    var isResumeStep: Bool {
        flow.currentStep == .resume
    }

    var progress: Double {
        flow.totalSteps == 0 ? 0 : Double(flow.completedSteps) / Double(flow.totalSteps)
    }

    var isExitGuarded: Bool {
        state.content != nil
    }

    var inputPlaceholder: String {
        if isResumeStep {
            return "Текст резюме"
        }
        return flow.pendingFollowUp == nil ? "Твой ответ" : "Ответ на уточнение"
    }

    var emptyMessage: String {
        "Для пары «\(profession.title), \(grade.title)» каталог ещё наполняется. Попробуй другой грейд."
    }

    var canSend: Bool {
        !isSending && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && flow.currentStep != nil
    }

    var messages: [ChatMessage] {
        guard let question = flow.currentQuestion else { return [] }
        var messages = [ChatMessage(
            id: "question-\(question.id)",
            text: question.prompt,
            isFromInterviewer: true,
            code: question.kind.snippet
        )]

        if let followUp = flow.pendingFollowUp {
            messages.append(ChatMessage(id: "answer-\(question.id)", text: followUp.turn.answer, isFromInterviewer: false))
            messages.append(ChatMessage(id: "follow-up-\(question.id)", text: followUp.question, isFromInterviewer: true))
        }
        if let pendingAnswer {
            let id = flow.pendingFollowUp == nil ? "answer-\(question.id)" : "follow-up-answer-\(question.id)"
            messages.append(ChatMessage(id: id, text: pendingAnswer, isFromInterviewer: false))
        }
        return messages
    }

    // MARK: - Actions
    func start() async {
        guard flow.questions.isEmpty else { return }
        state = .loading
        do {
            let questions = try await questionRepository.questions()
            let pastRuns = try await runRepository.runs(for: user.id)
            let picked = [StageKind.theory, .review].flatMap { stage in
                QuestionSelector.pick(
                    from: questions,
                    targetProfession: profession,
                    targetGrade: grade,
                    stage: stage,
                    pastRuns: pastRuns
                )
            }
            flow = InterviewFlow(questions: picked, profession: profession, grade: grade)
            state = flow.questions(in: .theory).isEmpty ? .empty : .loaded(.answering)
        } catch {
            state = .failed(error)
        }
    }

    func submit() async {
        guard canSend else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)

        isSending = true
        sendError = nil
        pendingAnswer = isResumeStep ? nil : text
        input = ""

        var next = flow
        do {
            try await next.answer(text, using: interviewService)
            flow = next
        } catch {
            sendError = error
            input = text
        }
        isSending = false
        pendingAnswer = nil

        if flow.isFinished {
            await finish()
        }
    }

    func skipResume() async {
        guard isResumeStep, !isSending else { return }
        flow.skipResume()
        input = ""
        sendError = nil
        if flow.isFinished {
            await finish()
        }
    }

    func retry() async {
        if flow.isFinished {
            await finish()
        } else {
            await start()
        }
    }

    func dismissSendError() {
        sendError = nil
    }

    func requestExit() {
        isExitConfirmationPresented = true
    }

    func leave() {
        router.pop()
    }

    private func finish() async {
        state = .loaded(.finishing)
        do {
            let summary = try await interviewService.verdict(
                results: flow.results,
                questions: flow.questions,
                resumeReview: flow.resumeReview,
                profession: profession,
                targetGrade: grade
            )
            guard let run = flow.makeRun(userID: user.id, summaryText: summary) else {
                return
            }
            try await runRepository.save(run)
            router.reset(to: .result(run))
        } catch {
            state = .failed(error)
        }
    }
}
