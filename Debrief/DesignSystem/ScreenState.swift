//
//  ScreenState.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import Foundation

// MARK: - ScreenState
enum ScreenState<Content> {
    case loading
    case empty
    case loaded(Content)
    case failed(Error)

    var phase: ScreenPhase {
        switch self {
        case .loading: .loading
        case .empty: .empty
        case .loaded: .loaded
        case .failed: .failed
        }
    }

    var content: Content? {
        if case .loaded(let content) = self { return content }
        return nil
    }
}

// MARK: - ScreenPhase
enum ScreenPhase: Hashable {
    case loading
    case empty
    case loaded
    case failed
}

// MARK: - FormState
enum FormState {
    case editing
    case saving
    case saved
    case failed(Error)

    var phase: FormPhase {
        switch self {
        case .editing: .editing
        case .saving: .saving
        case .saved: .saved
        case .failed: .failed
        }
    }

    var isSaving: Bool { phase == .saving }

    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

// MARK: - FormPhase
enum FormPhase: Hashable {
    case editing
    case saving
    case saved
    case failed
}
