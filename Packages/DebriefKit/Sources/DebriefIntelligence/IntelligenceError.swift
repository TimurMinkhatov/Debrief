//
//  IntelligenceError.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import FirebaseAILogic
import Foundation
import FoundationModels

// MARK: - IntelligenceError
public enum IntelligenceError: LocalizedError, Equatable {
    case accessDenied
    case network
    case serviceUnavailable
    case quotaExceeded
    case modelUnavailable
    case answerTooLong
    case rejectedContent
    case unexpected

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            "Сервис оценки отклонил запрос: приложение не прошло проверку App Check."
        case .network:
            "Нет связи с сервисом оценки. Проверь интернет и VPN."
        case .serviceUnavailable:
            "Сервис оценки временно недоступен. Попробуй чуть позже."
        case .quotaExceeded:
            "Слишком много запросов к модели. Подожди немного и повтори."
        case .modelUnavailable:
            "Модель для оценки сейчас недоступна."
        case .answerTooLong:
            "Ответ слишком длинный для модели. Попробуй сформулировать короче."
        case .rejectedContent:
            "Модель отказалась обрабатывать этот ответ. Переформулируй его."
        case .unexpected:
            "Не удалось получить оценку. Попробуй ещё раз."
        }
    }
}

// MARK: - Mapping
extension IntelligenceError {
    init(_ error: any Error) {
        switch error {
        case let error as IntelligenceError:
            self = error
        case let error as GeminiLanguageModel.Error:
            self = Self(gemini: error)
        case let error as LanguageModelError:
            self = Self(languageModel: error)
        case is URLError:
            self = .network
        default:
            self = .unexpected
        }
    }

    private init(gemini error: GeminiLanguageModel.Error) {
        if case .apiError(let apiError) = error {
            self = Self(statusCode: apiError.statusCode)
        } else if case .networkFailure = error {
            self = .network
        } else if case .serviceUnavailable = error {
            self = .serviceUnavailable
        } else if case .modelNotFound = error {
            self = .modelUnavailable
        } else {
            self = .unexpected
        }
    }

    private init(languageModel error: LanguageModelError) {
        switch error {
        case .rateLimited:
            self = .quotaExceeded
        case .contextSizeExceeded:
            self = .answerTooLong
        case .guardrailViolation, .refusal:
            self = .rejectedContent
        case .timeout:
            self = .serviceUnavailable
        default:
            self = .unexpected
        }
    }

    init(statusCode: Int?) {
        switch statusCode {
        case 401, 403:
            self = .accessDenied
        case 429:
            self = .quotaExceeded
        case let code? where (500..<600).contains(code):
            self = .serviceUnavailable
        default:
            self = .unexpected
        }
    }
}
