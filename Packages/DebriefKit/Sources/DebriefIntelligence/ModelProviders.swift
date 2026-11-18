//
//  ModelProviders.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import FoundationModels
import FirebaseAILogic

// MARK: - LanguageModelProvider
protocol LanguageModelProvider: Sendable {
    var isAvailable: Bool { get }
    func makeModel() -> any LanguageModel
}

// MARK: - ModelChain
struct ModelChain: Sendable {
    let providers: [any LanguageModelProvider]

    func firstAvailable() -> (any LanguageModelProvider)? {
        providers.first { $0.isAvailable }
    }

    func makeModel() throws -> any LanguageModel {
        guard let provider = firstAvailable() else {
            throw IntelligenceError.modelUnavailable
        }
        return provider.makeModel()
    }
}

// MARK: - GeminiModelProvider
struct GeminiModelProvider: LanguageModelProvider {
    private let modelName: String

    init(modelName: String = "gemini-3.5-flash") {
        self.modelName = modelName
    }

    var isAvailable: Bool { true }

    func makeModel() -> any LanguageModel {
        FirebaseAI.firebaseAI(backend: .googleAI()).geminiLanguageModel(name: modelName)
    }
}

