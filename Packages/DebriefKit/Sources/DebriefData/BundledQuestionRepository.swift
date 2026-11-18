//
//  BundledQuestionRepository.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 07/10/2026.
//

import DebriefDomain
import Foundation

public final class BundledQuestionRepository: QuestionRepositoryProtocol {
    
    public init() {
        
    }
    
    public func topics() async throws -> [Topic] {
        let data = try await findJson(name: "topics")
        let decode = JSONDecoder()
        let items = try decode.decode([Topic].self, from: data)
        return items
    }
    
    public func questions() async throws -> [Question] {
        let data = try await findJson(name: "questions")
        let decode = JSONDecoder()
        let items = try decode.decode([Question].self, from: data)
        return items
    }
    
    private func findJson(name: String) async throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw CatalogError.resourceMissing(name: name)
        }
        return try Data(contentsOf: url)
    }
}

private enum CatalogError: Error {
    case resourceMissing(name: String)
}
