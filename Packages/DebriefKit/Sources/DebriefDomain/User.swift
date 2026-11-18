//
//  User.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 15/09/2026.
//

import Foundation

// MARK: - User
public struct User: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var profession: Profession
    public var targetGrade: Grade

    public init(id: UUID = UUID(), name: String, profession: Profession, targetGrade: Grade) {
        self.id = id
        self.name = name
        self.profession = profession
        self.targetGrade = targetGrade
    }
}
