//
//  Container.swift
//  Debrief
//
//  Created by Timur Minkhatov on 29/09/2026.
//

import DebriefDomain
import DebriefData
import DebriefIntelligence
import Observation
import SwiftData

@Observable
@MainActor
final class Container {
    let session: AppSession
    private let questionRepository: any QuestionRepositoryProtocol
    private let runRepository: any RunRepositoryProtocol
    private let interviewService: any InterviewServiceProtocol

    init(modelContext: ModelContext) {
        self.questionRepository = BundledQuestionRepository()
        self.runRepository = RunRepository(context: modelContext)
        self.interviewService = InterviewService()
        self.session = AppSession(userRepository: UserRepository(context: modelContext))
    }

    // MARK: - Onboarding
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(session: session)
    }

    // MARK: - Interview tab
    func makeHomeViewModel(user: User, router: Router) -> HomeViewModel {
        HomeViewModel(user: user, runRepository: runRepository, router: router)
    }

    func makeInterviewViewModel(user: User, profession: Profession, grade: Grade, router: Router) -> InterviewViewModel {
        InterviewViewModel(
            user: user,
            profession: profession,
            grade: grade,
            questionRepository: questionRepository,
            runRepository: runRepository,
            interviewService: interviewService,
            router: router
        )
    }

    func makeResultViewModel(run: InterviewRun, router: Router) -> ResultViewModel {
        ResultViewModel(run: run, questionRepository: questionRepository, router: router)
    }

    func makeAnswerReviewViewModel(result: QuestionResult) -> AnswerReviewViewModel {
        AnswerReviewViewModel(result: result, questionRepository: questionRepository)
    }

    // MARK: - Progress tab
    func makeProgressOverviewViewModel(user: User, router: Router) -> ProgressOverviewViewModel {
        ProgressOverviewViewModel(user: user, runRepository: runRepository, questionRepository: questionRepository, router: router)
    }

    func makeHistoryViewModel(user: User, router: Router) -> HistoryViewModel {
        HistoryViewModel(user: user, runRepository: runRepository, router: router)
    }

    // MARK: - Profile tab
    func makeProfileViewModel(user: User) -> ProfileViewModel {
        ProfileViewModel(user: user, session: session)
    }
}
