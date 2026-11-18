//
//  UserRecord.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 30/09/2026.
//

import SwiftData
import DebriefDomain
import Foundation

@Model
final class UserRecord {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var profession: Profession
    var targetGrade: Grade

    init(id: UUID, name: String, profession: Profession, targetGrade: Grade) {
        self.id = id
        self.name = name
        self.profession = profession
        self.targetGrade = targetGrade
    }

    func toDomain() -> User {
        return User(id: id, name: name, profession: profession, targetGrade: targetGrade)
    }

    convenience init(user: User) {
        self.init(id: user.id, name: user.name, profession: user.profession, targetGrade: user.targetGrade)
    }
}
