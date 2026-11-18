//
//  ProfileViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {

    private let session: AppSession
    private var savedUser: User

    var name: String { didSet { resetStatus() } }
    var profession: Profession { didSet { resetStatus() } }
    var grade: Grade { didSet { resetStatus() } }
    private(set) var state: FormState = .editing

    let title = "Профиль"
    let saveTitle = "Сохранить"
    let savedMessage = "Сохранено. Новые собеседования пойдут с этими настройками."

    init(user: User, session: AppSession) {
        self.session = session
        self.savedUser = user
        self.name = user.name
        self.profession = user.profession
        self.grade = user.targetGrade
    }

    var hasChanges: Bool {
        editedUser != savedUser
    }

    var canSave: Bool {
        hasChanges && !trimmedName.isEmpty && !state.isSaving
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var editedUser: User {
        User(id: savedUser.id, name: trimmedName, profession: profession, targetGrade: grade)
    }

    func save() async {
        guard canSave else { return }
        let user = editedUser
        state = .saving
        do {
            try await session.save(user)
            savedUser = user
            state = .saved
        } catch {
            state = .failed(error)
        }
    }

    private func resetStatus() {
        switch state {
        case .saved, .failed:
            state = .editing
        case .editing, .saving:
            break
        }
    }
}
