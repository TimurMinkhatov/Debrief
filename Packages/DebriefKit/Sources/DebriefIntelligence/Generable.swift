//
//  Generable.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 08/10/2026.
//

import DebriefDomain
import Foundation
import FoundationModels

// MARK: - PointCoverage
@Generable
enum PointCoverage {
    case full
    case partial
    case none
}

// MARK: - PointVerdict
@Generable
struct PointVerdict {
    @Guide(description: "Номер ключевого пункта из списка, начиная с 1")
    let number: Int

    let coverage: PointCoverage
}

// MARK: - Evaluation
@Generable
struct Evaluation {
    @Guide(description: "Оценка каждого ключевого пункта, по одной на номер")
    let points: [PointVerdict]

    let additionalQuestion: String?
}

extension Evaluation {
    func outcome(for question: Question) -> QuestionOutcome {
        let followUp = additionalQuestion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard followUp.isEmpty else {
            return .followUp(followUp)
        }
        return .finished(PointVerdict.assessment(of: points, keyPoints: question.keyPoints))
    }
}

// MARK: - Score
@Generable
struct Score {
    @Guide(description: "Оценка каждого ключевого пункта, по одной на номер")
    let points: [PointVerdict]
}

extension Score {
    func assessment(for question: Question) -> Assessment {
        PointVerdict.assessment(of: points, keyPoints: question.keyPoints)
    }
}

// MARK: - Mapping
extension PointVerdict {
    static func assessment(of verdicts: [PointVerdict], keyPoints: [String]) -> Assessment {
        var coverage = [Coverage](repeating: .none, count: keyPoints.count)
        var assigned = Set<Int>()
        for verdict in verdicts {
            let index = verdict.number - 1
            guard coverage.indices.contains(index), !assigned.contains(index) else {
                continue
            }
            coverage[index] = verdict.coverage.domain
            assigned.insert(index)
        }
        return Assessment(keyPoints: keyPoints, coverage: coverage)
    }
}

extension PointCoverage {
    var domain: Coverage {
        switch self {
        case .full: .full
        case .partial: .partial
        case .none: .none
        }
    }
}

// MARK: - ResumeAnalysis
@Generable
struct ResumeAnalysis {
    @Guide(description: "Общий вывод о соответствии резюме целевому грейду в двух-трёх предложениях")
    let summary: String

    @Guide(description: "До пяти конкретных сильных сторон, опирающихся на текст резюме")
    let strengths: [String]

    @Guide(description: "До пяти конкретных пробелов или того, что стоит добавить или переписать")
    let gaps: [String]
}

extension ResumeAnalysis {
    static let itemLimit = 5

    var review: ResumeReview {
        ResumeReview(
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            strengths: Self.cleaned(strengths),
            gaps: Self.cleaned(gaps)
        )
    }

    private static func cleaned(_ items: [String]) -> [String] {
        Array(
            items
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(itemLimit)
        )
    }
}
