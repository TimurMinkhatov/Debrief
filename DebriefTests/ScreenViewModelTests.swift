//
//  ScreenViewModelTests.swift
//  DebriefTests
//
//  Created by Timur Minkhatov on 01/11/2026.
//

@testable import Debrief
import DebriefDomain
import Foundation
import Testing

private let day: TimeInterval = 60 * 60 * 24
private let baseDate = Date(timeIntervalSince1970: 1_800_000_000)

// MARK: - Router
@MainActor
@Suite("Router")
struct RouterTests {

    @Test func pushPopAndReset() {
        let router = Router()
        let run = makeRun(userID: testUser.id, results: [])

        router.push(.history)
        router.push(.result(run))
        #expect(router.path == [.history, .result(run)])

        router.pop()
        #expect(router.path == [.history])

        router.reset(to: .result(run))
        #expect(router.path == [.result(run)])

        router.pop()
        router.pop()
        #expect(router.path.isEmpty)
    }
}

// MARK: - Home
@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {

    @Test func loadsLastRunAndCount() async throws {
        let older = makeRun(userID: testUser.id, completedAt: baseDate, results: [makeResult(questionID: "a", score: 40)])
        let newer = makeRun(userID: testUser.id, completedAt: baseDate + day, results: [makeResult(questionID: "a", score: 90)])
        let viewModel = HomeViewModel(user: testUser, runRepository: InMemoryRunRepository(runs: [older, newer]), router: Router())

        await viewModel.load()

        let summary = try #require(viewModel.state.content)
        #expect(summary.lastRun == newer)
        #expect(summary.runCount == 2)
        #expect(viewModel.lastRunCaption(for: summary)?.contains("всего прогонов: 2") == true)
    }

    @Test func showsErrorWhenHistoryFails() async {
        let repository = InMemoryRunRepository()
        repository.error = TestError()
        let viewModel = HomeViewModel(user: testUser, runRepository: repository, router: Router())

        await viewModel.load()

        #expect(viewModel.state.phase == .failed)
    }

    @Test func startUsesSelectedProfessionAndGrade() {
        let router = Router()
        let viewModel = HomeViewModel(user: testUser, runRepository: InMemoryRunRepository(), router: router)
        #expect(viewModel.selectedProfession == testUser.profession)
        #expect(viewModel.selectedGrade == testUser.targetGrade)

        viewModel.selectedProfession = .systemAnalyst
        viewModel.selectedGrade = .middle
        viewModel.startInterview()

        #expect(router.path == [.interview(.systemAnalyst, .middle)])
    }

    @Test func openLastRunPushesResult() async {
        let run = makeRun(userID: testUser.id, results: [makeResult(questionID: "a", score: 50)])
        let router = Router()
        let viewModel = HomeViewModel(user: testUser, runRepository: InMemoryRunRepository(runs: [run]), router: router)

        viewModel.openLastRun()
        #expect(router.path.isEmpty)

        await viewModel.load()
        viewModel.openLastRun()
        #expect(router.path == [.result(run)])
    }
}

// MARK: - Result
@MainActor
@Suite("ResultViewModel")
struct ResultViewModelTests {

    @Test func itemsCarryNumbersAndTopicTitles() async throws {
        let run = makeRun(userID: testUser.id, results: [
            makeResult(questionID: "a", score: 50, missedPoints: ["x"]),
            makeResult(questionID: "removed", score: 100)
        ])
        let repository = StubQuestionRepository(
            topics: [Topic(id: "arc", title: "ARC")],
            questions: [makeQuestion(id: "a", topicID: "arc")]
        )
        let viewModel = ResultViewModel(run: run, questionRepository: repository, router: Router())

        await viewModel.load()

        let content = try #require(viewModel.state.content)
        let items = content.sections.flatMap(\.items)
        #expect(items.map(\.caption) == ["1. ARC", "Вопрос 2"])
        #expect(items.map(\.gapsTitle) == ["Не прозвучало: 1", "Все ключевые пункты раскрыты"])
        #expect(viewModel.verdict == "Итог")
    }

    @Test func gapsTitleCombinesMissedAndPartial() async throws {
        let run = makeRun(userID: testUser.id, results: [
            makeResult(questionID: "a", score: 40, missedPoints: ["x"], partialPoints: ["y", "z"]),
            makeResult(questionID: "b", score: 75, partialPoints: ["y"])
        ])
        let viewModel = ResultViewModel(run: run, questionRepository: StubQuestionRepository(), router: Router())

        await viewModel.load()

        let content = try #require(viewModel.state.content)
        let items = content.sections.flatMap(\.items)
        #expect(items.map(\.gapsTitle) == ["Не прозвучало: 1 · Частично: 2", "Частично: 1"])
        #expect(items.allSatisfy { !$0.isComplete })
    }

    @Test func openItemPushesAnswerReview() async throws {
        let result = makeResult(questionID: "a", score: 50)
        let router = Router()
        let viewModel = ResultViewModel(
            run: makeRun(userID: testUser.id, results: [result]),
            questionRepository: StubQuestionRepository(),
            router: router
        )
        await viewModel.load()

        viewModel.open(try #require(viewModel.state.content?.sections.first?.items.first))

        #expect(router.path == [.answerReview(result)])
    }

    @Test func resultsAreGroupedByStageWithOwnNumbering() async throws {
        let run = makeRun(userID: testUser.id, profession: .iosDeveloper, results: [
            makeResult(questionID: "t1", score: 100),
            makeResult(questionID: "t2", score: 50),
            makeResult(questionID: "r1", stage: .review, score: 25)
        ])
        let viewModel = ResultViewModel(run: run, questionRepository: StubQuestionRepository(), router: Router())

        await viewModel.load()

        let sections = try #require(viewModel.state.content?.sections)
        #expect(sections.map(\.stage) == [.theory, .review])
        #expect(sections.map(\.title) == ["Теория", "Ревью кода"])
        #expect(sections.map(\.averageScore) == [75, 25])
        #expect(sections[1].items.map(\.caption) == ["Вопрос 1"])
    }

    @Test func reviewSectionIsNamedForAnalyst() async throws {
        let run = makeRun(userID: testUser.id, profession: .systemAnalyst, results: [
            makeResult(questionID: "r1", stage: .review, score: 50)
        ])
        let viewModel = ResultViewModel(run: run, questionRepository: StubQuestionRepository(), router: Router())

        await viewModel.load()

        #expect(viewModel.state.content?.sections.map(\.title) == ["Ревью артефактов"])
    }

    @Test func resumeReviewIsShownWhenPresent() async throws {
        let review = ResumeReview(summary: "Хорошо", strengths: ["SwiftUI"], gaps: ["Тесты"])
        let run = makeRun(userID: testUser.id, results: [makeResult(questionID: "t1", score: 80)], resumeReview: review)
        let viewModel = ResultViewModel(run: run, questionRepository: StubQuestionRepository(), router: Router())

        await viewModel.load()

        #expect(viewModel.state.content?.resumeReview == review)
        #expect(viewModel.resumeTitle == "Резюме")
    }

    @Test func runWithoutResultsIsEmpty() async {
        let viewModel = ResultViewModel(
            run: makeRun(userID: testUser.id, results: []),
            questionRepository: StubQuestionRepository(),
            router: Router()
        )

        await viewModel.load()

        #expect(viewModel.state.phase == .empty)
    }
}

// MARK: - AnswerReview
@MainActor
@Suite("AnswerReviewViewModel")
struct AnswerReviewViewModelTests {

    @Test func showsDialogWithFollowUpAndMarksCoverage() async throws {
        let result = makeResult(
            questionID: "a",
            score: 50,
            missedPoints: ["пункт 3"],
            partialPoints: ["пункт 2"],
            followUp: Turn(question: "Уточнение", answer: "Ответ на уточнение")
        )
        let repository = StubQuestionRepository(
            topics: [Topic(id: "arc", title: "ARC")],
            questions: [makeQuestion(id: "a", topicID: "arc", keyPoints: ["пункт 1", "пункт 2", "пункт 3"])]
        )
        let viewModel = AnswerReviewViewModel(result: result, questionRepository: repository)

        await viewModel.load()

        let review = try #require(viewModel.state.content)
        #expect(review.topicTitle == "ARC")
        #expect(review.messages.map(\.text) == ["Вопрос a", "Ответ a", "Уточнение", "Ответ на уточнение"])
        #expect(review.messages.map(\.isFromInterviewer) == [true, false, true, false])
        #expect(review.points == [
            AnswerReviewViewModel.Point(text: "пункт 1", coverage: .full),
            AnswerReviewViewModel.Point(text: "пункт 2", coverage: .partial),
            AnswerReviewViewModel.Point(text: "пункт 3", coverage: .none)
        ])
        #expect(viewModel.coverageTitle(for: review) == "Раскрыто 1 из 3, частично 1")
    }

    @Test func reviewQuestionShowsSnippetInDialog() async throws {
        let result = makeResult(questionID: "r1", stage: .review, score: 50)
        let repository = StubQuestionRepository(questions: [makeQuestion(id: "r1", kind: .review(snippet: "let a = b!"))])
        let viewModel = AnswerReviewViewModel(result: result, questionRepository: repository)

        await viewModel.load()

        let review = try #require(viewModel.state.content)
        #expect(review.messages.first?.code == "let a = b!")
        #expect(review.messages.dropFirst().allSatisfy { $0.code == nil })
    }

    @Test func fallsBackToMissedPointsWhenQuestionRemoved() async throws {
        let result = makeResult(questionID: "removed", score: 0, missedPoints: ["старый пункт"])
        let viewModel = AnswerReviewViewModel(result: result, questionRepository: StubQuestionRepository())

        await viewModel.load()

        let review = try #require(viewModel.state.content)
        #expect(review.topicTitle == nil)
        #expect(review.messages.count == 2)
        #expect(review.points == [AnswerReviewViewModel.Point(text: "старый пункт", coverage: .none)])
    }

    @Test func showsErrorWhenCatalogFails() async {
        let repository = StubQuestionRepository()
        repository.error = TestError()
        let viewModel = AnswerReviewViewModel(result: makeResult(questionID: "a", score: 0), questionRepository: repository)

        await viewModel.load()

        #expect(viewModel.state.phase == .failed)
    }
}

// MARK: - ProgressOverview
@MainActor
@Suite("ProgressOverviewViewModel")
struct ProgressOverviewViewModelTests {

    private let repository = StubQuestionRepository(
        topics: [
            Topic(id: "arc", title: "ARC"),
            Topic(id: "swiftui", title: "SwiftUI"),
            Topic(id: "codable", title: "Codable"),
            Topic(id: "sa-sql", title: "SQL")
        ],
        questions: [
            makeQuestion(id: "arc-1", topicID: "arc"),
            makeQuestion(id: "swiftui-1", topicID: "swiftui"),
            makeQuestion(id: "codable-1", topicID: "codable"),
            makeQuestion(id: "sql-1", topicID: "sa-sql", profession: .systemAnalyst)
        ]
    )

    @Test func emptyWhenNoRunsForUserProfession() async {
        let analystRun = makeRun(userID: testUser.id, profession: .systemAnalyst, results: [makeResult(questionID: "sql-1", score: 50)])
        let viewModel = ProgressOverviewViewModel(
            user: testUser,
            runRepository: InMemoryRunRepository(runs: [analystRun]),
            questionRepository: repository,
            router: Router()
        )

        await viewModel.load()

        #expect(viewModel.state.phase == .empty)
    }

    @Test func topicsOfProfessionSortedWeakestFirstAndUnaskedLast() async throws {
        let run = makeRun(userID: testUser.id, results: [
            makeResult(questionID: "arc-1", score: 90),
            makeResult(questionID: "swiftui-1", score: 30)
        ])
        let viewModel = ProgressOverviewViewModel(
            user: testUser,
            runRepository: InMemoryRunRepository(runs: [run]),
            questionRepository: repository,
            router: Router()
        )

        await viewModel.load()

        let overview = try #require(viewModel.state.content)
        #expect(overview.topics.map(\.topic.id) == ["swiftui", "arc", "codable"])
        #expect(overview.topics.map(\.scoreText) == ["30", "90", "—"])
        #expect(overview.averageScore == 60)
    }

    @Test func showsOnlyRecentRunsAndOpensHistory() async throws {
        let runs = (0..<5).map { index in
            makeRun(userID: testUser.id, completedAt: baseDate + Double(index) * day, results: [makeResult(questionID: "arc-1", score: 50)])
        }
        let router = Router()
        let viewModel = ProgressOverviewViewModel(
            user: testUser,
            runRepository: InMemoryRunRepository(runs: runs),
            questionRepository: repository,
            router: router
        )

        await viewModel.load()

        let overview = try #require(viewModel.state.content)
        #expect(overview.recentRuns.count == ProgressOverviewViewModel.recentLimit)
        #expect(overview.recentRuns.first == runs.last)
        #expect(viewModel.historyTitle(for: overview) == "Вся история (5)")

        viewModel.openHistory()
        viewModel.open(runs[0])
        #expect(router.path == [.history, .result(runs[0])])
    }
}

// MARK: - History
@MainActor
@Suite("HistoryViewModel")
struct HistoryViewModelTests {

    private func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func groupsRunsByMonthNewestFirst() async throws {
        let october = makeRun(userID: testUser.id, completedAt: date(year: 2026, month: 10, day: 5), results: [])
        let novemberEarly = makeRun(userID: testUser.id, completedAt: date(year: 2026, month: 11, day: 1), results: [])
        let novemberLate = makeRun(userID: testUser.id, completedAt: date(year: 2026, month: 11, day: 20), results: [])
        let viewModel = HistoryViewModel(
            user: testUser,
            runRepository: InMemoryRunRepository(runs: [october, novemberLate, novemberEarly]),
            router: Router()
        )

        await viewModel.load()

        let sections = try #require(viewModel.state.content)
        #expect(sections.count == 2)
        #expect(sections[0].runs == [novemberLate, novemberEarly])
        #expect(sections[1].runs == [october])
        #expect(sections[0].title.lowercased().contains("ноябр"))
    }

    @Test func filterByProfessionAndEmptyState() async throws {
        let iosRun = makeRun(userID: testUser.id, profession: .iosDeveloper, results: [])
        let viewModel = HistoryViewModel(user: testUser, runRepository: InMemoryRunRepository(runs: [iosRun]), router: Router())
        await viewModel.load()

        viewModel.filter = .profession(.systemAnalyst)
        #expect(viewModel.state.phase == .empty)
        #expect(viewModel.emptyMessage.contains("Системный аналитик"))

        viewModel.filter = .profession(.iosDeveloper)
        #expect(viewModel.state.content?.flatMap(\.runs) == [iosRun])

        viewModel.filter = .all
        #expect(viewModel.state.content?.flatMap(\.runs) == [iosRun])
    }

    @Test func showsOtherUsersRunsNever() async {
        let foreign = makeRun(userID: UUID(), results: [])
        let viewModel = HistoryViewModel(user: testUser, runRepository: InMemoryRunRepository(runs: [foreign]), router: Router())

        await viewModel.load()

        #expect(viewModel.state.phase == .empty)
    }

    @Test func openPushesResult() {
        let run = makeRun(userID: testUser.id, results: [])
        let router = Router()
        let viewModel = HistoryViewModel(user: testUser, runRepository: InMemoryRunRepository(), router: router)

        viewModel.open(run)

        #expect(router.path == [.result(run)])
    }
}

// MARK: - Onboarding
@MainActor
@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {

    @Test func cannotSaveWithBlankName() {
        let viewModel = OnboardingViewModel(session: AppSession(userRepository: InMemoryUserRepository()))

        viewModel.name = "  "

        #expect(!viewModel.canSave)
    }

    @Test func saveStoresTrimmedUserAndSwitchesSession() async throws {
        let repository = InMemoryUserRepository()
        let session = AppSession(userRepository: repository)
        let viewModel = OnboardingViewModel(session: session)
        viewModel.name = "  Тимур "
        viewModel.profession = .systemAnalyst
        viewModel.grade = .middle

        await viewModel.save()

        let user = try #require(repository.user)
        #expect(user.name == "Тимур")
        #expect(user.profession == .systemAnalyst)
        #expect(user.targetGrade == .middle)
        #expect(session.state.phase == .ready)
        #expect(viewModel.state.phase == .saved)
    }

    @Test func failureIsShownAndClearedOnEdit() async {
        let repository = InMemoryUserRepository()
        repository.saveError = TestError()
        let viewModel = OnboardingViewModel(session: AppSession(userRepository: repository))
        viewModel.name = "Тимур"

        await viewModel.save()
        #expect(viewModel.state.phase == .failed)
        #expect(viewModel.state.error?.localizedDescription == "Тестовая ошибка")

        viewModel.name = "Тимур М."
        #expect(viewModel.state.phase == .editing)
    }
}

// MARK: - Profile
@MainActor
@Suite("ProfileViewModel")
struct ProfileViewModelTests {

    @Test func noChangesMeansNothingToSave() {
        let viewModel = ProfileViewModel(user: testUser, session: AppSession(userRepository: InMemoryUserRepository(user: testUser)))

        #expect(!viewModel.hasChanges)
        #expect(!viewModel.canSave)
    }

    @Test func savesChangesKeepingIdentity() async throws {
        let repository = InMemoryUserRepository(user: testUser)
        let session = AppSession(userRepository: repository)
        let viewModel = ProfileViewModel(user: testUser, session: session)

        viewModel.grade = .senior
        #expect(viewModel.canSave)
        await viewModel.save()

        let saved = try #require(repository.user)
        #expect(saved.id == testUser.id)
        #expect(saved.targetGrade == .senior)
        #expect(viewModel.state.phase == .saved)
        #expect(!viewModel.hasChanges)

        viewModel.name = "Другое имя"
        #expect(viewModel.state.phase == .editing)
        #expect(viewModel.hasChanges)
    }

    @Test func blankNameCannotBeSaved() {
        let viewModel = ProfileViewModel(user: testUser, session: AppSession(userRepository: InMemoryUserRepository(user: testUser)))

        viewModel.name = " "

        #expect(viewModel.hasChanges)
        #expect(!viewModel.canSave)
    }
}
