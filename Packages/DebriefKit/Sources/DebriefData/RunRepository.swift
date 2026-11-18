//
//  RunRepository.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import Foundation
import SwiftData
import DebriefDomain

@MainActor
public final class RunRepository: RunRepositoryProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func runs(for userID: UUID) async throws -> [InterviewRun] {
        let descriptor = FetchDescriptor<RunRecord>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    public func save(_ run: InterviewRun) async throws {
        let runID = run.id
        var descriptor = FetchDescriptor<RunRecord>(predicate: #Predicate { $0.id == runID })
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.completedAt = run.completedAt
            existing.summaryText = run.summaryText
            existing.resultsData = try JSONEncoder().encode(run.results)
            existing.resumeReviewData = try run.resumeReview.map { try JSONEncoder().encode($0) }
        } else {
            context.insert(try RunRecord(run: run))
        }

        try context.save()
    }
}
