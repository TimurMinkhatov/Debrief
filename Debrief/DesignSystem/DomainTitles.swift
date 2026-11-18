//
//  DomainTitles.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation

// MARK: - Profession
extension Profession {
    var title: String {
        switch self {
        case .iosDeveloper: "iOS-разработчик"
        case .systemAnalyst: "Системный аналитик"
        }
    }
}

// MARK: - Grade
extension Grade {
    var title: String {
        switch self {
        case .intern: "Intern"
        case .junior: "Junior"
        case .middle: "Middle"
        case .senior: "Senior"
        }
    }
}

// MARK: - StageKind
extension StageKind {
    func title(for profession: Profession) -> String {
        switch self {
        case .theory: "Теория"
        case .review: profession == .iosDeveloper ? "Ревью кода" : "Ревью артефактов"
        case .resume: "Резюме"
        }
    }

    var symbolName: String {
        switch self {
        case .theory: "text.book.closed"
        case .review: "chevron.left.forwardslash.chevron.right"
        case .resume: "doc.text.magnifyingglass"
        }
    }
}

// MARK: - Coverage
extension Coverage {
    var symbolName: String {
        switch self {
        case .full: "checkmark.circle.fill"
        case .partial: "circle.lefthalf.filled"
        case .none: "circle.dashed"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .full: "Раскрыт"
        case .partial: "Раскрыт частично"
        case .none: "Не раскрыт"
        }
    }
}

// MARK: - InterviewRun
extension InterviewRun {
    var gradeSummary: String {
        "\(estimatedGrade.title) при цели \(targetGrade.title)"
    }

    var dateText: String {
        completedAt.formatted(date: .abbreviated, time: .shortened)
    }
}
