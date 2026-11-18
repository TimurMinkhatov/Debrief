//
//  Selection.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 16/09/2026.
//

import Foundation

// MARK: - SelectionRules
public enum SelectionRules {
    public static let theoryCount: Int = 8
    public static let reviewCount: Int = 2
    public static let cooldown: TimeInterval = 60 * 60 * 24 * 14
    public static let maxWeight: Int = 100
    public static let minWeight: Int = 10

    public static func questionCount(for stage: StageKind) -> Int {
        switch stage {
        case .theory: theoryCount
        case .review: reviewCount
        case .resume: 0
        }
    }
}

// MARK: - QuestionSelector
public enum QuestionSelector {

    public static func pick(
        from questions: [Question],
        targetProfession: Profession,
        targetGrade: Grade,
        stage: StageKind = .theory,
        pastRuns: [InterviewRun],
        count: Int? = nil,
        date: Date = Date()
    ) -> [Question] {
        var generator = SystemRandomNumberGenerator()
        return pick(
            from: questions,
            targetProfession: targetProfession,
            targetGrade: targetGrade,
            stage: stage,
            pastRuns: pastRuns,
            count: count,
            date: date,
            using: &generator
        )
    }

    public static func pick(
        from questions: [Question],
        targetProfession: Profession,
        targetGrade: Grade,
        stage: StageKind = .theory,
        pastRuns: [InterviewRun],
        count: Int? = nil,
        date: Date = Date(),
        using generator: inout some RandomNumberGenerator
    ) -> [Question] {
        let count = count ?? SelectionRules.questionCount(for: stage)
        let eligible = questions.filter {
            $0.grade == targetGrade && $0.profession == targetProfession && $0.stage == stage
        }
        guard !eligible.isEmpty else {
            return []
        }

        let attempts = lastAttempts(in: pastRuns)

        var pool = eligible.filter { question in
            guard let attempt = attempts[question.id] else {
                return true
            }
            return date.timeIntervalSince(attempt.askedAt) > SelectionRules.cooldown
        }
        if pool.isEmpty {
            pool = eligible
        }

        var picked: [Question] = []
        while picked.count < count, !pool.isEmpty {
            let weights = pool.map { weight(for: $0, attempts: attempts) }
            guard let index = index(forWeights: weights, using: &generator) else {
                break
            }
            let question = pool[index]
            picked.append(question)
            pool.removeAll { $0.topicID == question.topicID }
        }
        return picked
    }

    static func lastAttempts(in pastRuns: [InterviewRun]) -> [String: (askedAt: Date, score: Int)] {
        var attempts: [String: (askedAt: Date, score: Int)] = [:]
        for run in pastRuns.sorted(by: { $0.completedAt > $1.completedAt }) {
            for result in run.results where attempts[result.questionID] == nil {
                attempts[result.questionID] = (askedAt: run.completedAt, score: result.score)
            }
        }
        return attempts
    }

    static func weight(
        for question: Question,
        attempts: [String: (askedAt: Date, score: Int)]
    ) -> Int {
        guard let attempt = attempts[question.id] else {
            return SelectionRules.maxWeight
        }
        return max(SelectionRules.maxWeight - attempt.score, SelectionRules.minWeight)
    }

    static func index(forWeights weights: [Int], using generator: inout some RandomNumberGenerator) -> Int? {
        let total = weights.reduce(0, +)
        guard total > 0 else {
            return weights.isEmpty ? nil : 0
        }
        let random = Int.random(in: 0..<total, using: &generator)
        var accumulated = 0
        for i in weights.indices {
            accumulated += weights[i]
            if accumulated > random {
                return i
            }
        }
        return weights.index(before: weights.endIndex)
    }
}
