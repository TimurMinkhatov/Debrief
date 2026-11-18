//
//  AppSession.swift
//  Debrief
//
//  Created by Timur Minkhatov on 30/09/2026.
//

import Foundation
import DebriefDomain
import Observation

@Observable
@MainActor
final class AppSession {

    private let userRepository: any UserRepositoryProtocol
    private(set) var state: LoadState = .loading

    init(userRepository: any UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func load() async {
        do {
            if let user = try await userRepository.findUser() {
                state = .ready(user)
            } else {
                state = .noUser
            }
        } catch {
            state = .failed(error)
        }
    }

    func save(_ user: User) async throws {
        try await userRepository.save(user)
        state = .ready(user)
    }

    enum LoadState {
        case loading
        case noUser
        case ready(User)
        case failed(Error)

        var phase: Phase {
            switch self {
            case .loading: .loading
            case .noUser: .noUser
            case .ready: .ready
            case .failed: .failed
            }
        }
    }

    enum Phase: Hashable {
        case loading
        case noUser
        case ready
        case failed
    }
}
