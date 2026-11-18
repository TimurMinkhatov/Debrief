//
//  RunRecord.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftData
import DebriefDomain
import Foundation

@Model
final class RunRecord {

    @Attribute(.unique)
    var id: UUID

    var userID: UUID
    var profession: Profession
    var targetGrade: Grade
    var completedAt: Date
    var summaryText: String
    var resultsData: Data
    var resumeReviewData: Data?

    init(
        id: UUID,
        userID: UUID,
        profession: Profession,
        targetGrade: Grade,
        completedAt: Date,
        summaryText: String,
        resultsData: Data,
        resumeReviewData: Data?
    ) {
        self.id = id
        self.userID = userID
        self.profession = profession
        self.targetGrade = targetGrade
        self.completedAt = completedAt
        self.summaryText = summaryText
        self.resultsData = resultsData
        self.resumeReviewData = resumeReviewData
    }

    convenience init(run: InterviewRun) throws {
        self.init(
            id: run.id,
            userID: run.userID,
            profession: run.profession,
            targetGrade: run.targetGrade,
            completedAt: run.completedAt,
            summaryText: run.summaryText,
            resultsData: try JSONEncoder().encode(run.results),
            resumeReviewData: try run.resumeReview.map { try JSONEncoder().encode($0) }
        )
    }

    func toDomain() throws -> InterviewRun {
        InterviewRun(
            id: id,
            userID: userID,
            profession: profession,
            targetGrade: targetGrade,
            completedAt: completedAt,
            results: try JSONDecoder().decode([QuestionResult].self, from: resultsData),
            resumeReview: try resumeReviewData.map { try JSONDecoder().decode(ResumeReview.self, from: $0) },
            summaryText: summaryText
        )
    }
}
