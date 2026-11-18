//
//  Catalog.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 15/09/2026.
//

// MARK: - Profession
public enum Profession: String, Sendable, Codable, CaseIterable {
    case iosDeveloper
    case systemAnalyst
}

// MARK: - Grade
public enum Grade: String, Sendable, Codable, CaseIterable {
    case intern
    case junior
    case middle
    case senior
}

extension Grade {
    private static let passingScore: Int = 70
    public static func estimated(forScore score: Int, target: Grade) -> Grade {
        guard score < passingScore else {
            return target
        }
        switch target {
        case .intern, .junior:
            return .intern
        case .middle:
            return .junior
        case .senior:
            return .middle
        }
    }
}

// MARK: - Topic
public struct Topic: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

// MARK: - StageKind
public enum StageKind: String, Codable, Sendable, CaseIterable {
    case theory
    case review
    case resume
}

// MARK: - QuestionKind
public enum QuestionKind: Hashable, Sendable {
    case theory
    case review(snippet: String)

    public var stage: StageKind {
        switch self {
        case .theory: .theory
        case .review: .review
        }
    }

    public var snippet: String? {
        if case .review(let snippet) = self { return snippet }
        return nil
    }
}

// MARK: - Question
public struct Question: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let topicID: String
    public let profession: Profession
    public let grade: Grade
    public let kind: QuestionKind
    public let prompt: String
    public let keyPoints: [String]

    public var stage: StageKind { kind.stage }

    public init(
        id: String,
        topicID: String,
        profession: Profession,
        grade: Grade,
        kind: QuestionKind = .theory,
        prompt: String,
        keyPoints: [String]
    ) {
        self.id = id
        self.topicID = topicID
        self.profession = profession
        self.grade = grade
        self.kind = kind
        self.prompt = prompt
        self.keyPoints = keyPoints
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case topicID
        case profession
        case grade
        case kind
        case snippet
        case prompt
        case keyPoints
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.topicID = try container.decode(String.self, forKey: .topicID)
        self.profession = try container.decode(Profession.self, forKey: .profession)
        self.grade = try container.decode(Grade.self, forKey: .grade)
        self.prompt = try container.decode(String.self, forKey: .prompt)
        self.keyPoints = try container.decode([String].self, forKey: .keyPoints)

        switch try container.decodeIfPresent(StageKind.self, forKey: .kind) ?? .theory {
        case .theory:
            self.kind = .theory
        case .review:
            self.kind = .review(snippet: try container.decode(String.self, forKey: .snippet))
        case .resume:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Вопрос не может относиться к этапу резюме"
            )
        }
    }
}
