//
//  CatalogTests.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefData
import DebriefDomain
import Testing

@Suite("Bundled catalog")
struct CatalogTests {

    private let repository = BundledQuestionRepository()

    // MARK: - Decoding
    @Test func topicsDecodeAndAreNotEmpty() async throws {
        let topics = try await repository.topics()

        #expect(!topics.isEmpty)
        #expect(topics.allSatisfy { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    @Test func questionsDecodeAndAreNotEmpty() async throws {
        let questions = try await repository.questions()

        #expect(!questions.isEmpty)
    }

    // MARK: - Integrity
    @Test func topicIDsAreUnique() async throws {
        let ids = try await repository.topics().map(\.id)

        #expect(Set(ids).count == ids.count, "Дубли: \(duplicates(in: ids))")
    }

    @Test func questionIDsAreUnique() async throws {
        let ids = try await repository.questions().map(\.id)

        #expect(Set(ids).count == ids.count, "Дубли: \(duplicates(in: ids))")
    }

    @Test func everyQuestionReferencesExistingTopic() async throws {
        let topicIDs = Set(try await repository.topics().map(\.id))
        let orphans = try await repository.questions().filter { !topicIDs.contains($0.topicID) }

        #expect(orphans.isEmpty, "Неизвестный topicID у: \(orphans.map(\.id))")
    }

    @Test func everyQuestionHasPromptAndKeyPoints() async throws {
        let questions = try await repository.questions()

        for question in questions {
            #expect(!question.prompt.trimmingCharacters(in: .whitespaces).isEmpty, "Пустой prompt у \(question.id)")
            #expect(!question.keyPoints.isEmpty, "Нет ключевых пунктов у \(question.id)")
            #expect(
                question.keyPoints.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                "Пустой ключевой пункт у \(question.id)"
            )
        }
    }

    @Test func everyTopicHasAtLeastOneQuestion() async throws {
        let usedTopicIDs = Set(try await repository.questions().map(\.topicID))
        let unused = try await repository.topics().filter { !usedTopicIDs.contains($0.id) }

        #expect(unused.isEmpty, "Темы без вопросов: \(unused.map(\.id))")
    }

    // MARK: - Selection on real data
    @Test(arguments: Profession.allCases, Grade.allCases)
    func catalogHasEnoughTopicsForEveryStage(profession: Profession, grade: Grade) async throws {
        let questions = try await repository.questions()

        for stage in [StageKind.theory, .review] {
            let topics = Set(questions.filter { $0.profession == profession && $0.grade == grade && $0.stage == stage }.map(\.topicID))
            let required = SelectionRules.questionCount(for: stage)
            #expect(topics.count >= required, "\(profession) \(grade) \(stage): тем \(topics.count), нужно \(required)")
        }
    }

    @Test(arguments: Profession.allCases, Grade.allCases)
    func selectorFillsEveryStageFromCatalog(profession: Profession, grade: Grade) async throws {
        let questions = try await repository.questions()

        for stage in [StageKind.theory, .review] {
            let picked = QuestionSelector.pick(from: questions, targetProfession: profession, targetGrade: grade, stage: stage, pastRuns: [])

            #expect(picked.count == SelectionRules.questionCount(for: stage))
            #expect(Set(picked.map(\.topicID)).count == picked.count)
            #expect(picked.allSatisfy { $0.profession == profession && $0.grade == grade && $0.stage == stage })
        }
    }

    @Test func reviewTasksHaveSnippetsAndTheoryDoesNot() async throws {
        let questions = try await repository.questions()

        for question in questions {
            switch question.kind {
            case .theory:
                #expect(question.kind.snippet == nil)
            case .review(let snippet):
                #expect(!snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Пустой фрагмент у \(question.id)")
            }
        }
        #expect(questions.contains { $0.stage == .review })
    }

    @Test func topicsAreNotSharedBetweenProfessions() async throws {
        let questions = try await repository.questions()
        let professionsByTopic = Dictionary(grouping: questions, by: \.topicID).mapValues { Set($0.map(\.profession)) }
        let shared = professionsByTopic.filter { $0.value.count > 1 }.map(\.key)

        #expect(shared.isEmpty, "Темы в нескольких профессиях: \(shared)")
    }

    @Test func keyPointsAreUniqueWithinQuestion() async throws {
        let questions = try await repository.questions()

        for question in questions {
            #expect(Set(question.keyPoints).count == question.keyPoints.count, "Повтор пункта у \(question.id)")
        }
    }

    private func duplicates(in ids: [String]) -> [String] {
        Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.map(\.key)
    }
}
