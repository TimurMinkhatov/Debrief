//
//  OnboardingViewModel.swift
//  Debrief
//
//  Created by Timur Minkhatov on 29/09/2026.
//

import DebriefDomain
import Foundation
import Observation

@Observable
@MainActor
final class OnboardingViewModel {

    private let session: AppSession

    var name: String = "" { didSet { resetFailure() } }
    var profession: Profession = .iosDeveloper
    var grade: Grade = .intern
    private(set) var state: FormState = .editing

    let title = "Debrief"
    let subtitle = "Тренажёр технического собеседования. Десять вопросов, уточнения по ходу, разбор того, что ты не раскрыл."
    let saveTitle = "Начать"

    init(session: AppSession) {
        self.session = session
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !state.isSaving
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() async {
        guard canSave else { return }
        state = .saving
        do {
            try await session.save(User(name: trimmedName, profession: profession, targetGrade: grade))
            state = .saved
        } catch {
            state = .failed(error)
        }
    }

    private func resetFailure() {
        if case .failed = state {
            state = .editing
        }
    }
}
