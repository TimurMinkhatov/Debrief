//
//  UserRepository.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 30/09/2026.
//

import Foundation
import SwiftData
import DebriefDomain

@MainActor
public final class UserRepository: UserRepositoryProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func findUser() async throws -> User? {
        try context.fetch(FetchDescriptor<UserRecord>()).first?.toDomain()
    }

    public func save(_ user: User) async throws {
        let userID = user.id
        var descriptor = FetchDescriptor<UserRecord>(predicate: #Predicate { $0.id == userID })
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor).first

        if let existing {
            existing.name = user.name
            existing.profession = user.profession
            existing.targetGrade = user.targetGrade
        } else {
            context.insert(UserRecord(user: user))
        }

        try context.save()
    }
}
