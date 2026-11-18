//
//  Statistics.swift
//  DebriefKit
//
//  Created by Timur Minkhatov on 01/11/2026.
//

// MARK: - RunStatistics
public enum RunStatistics {

    public static func latestScoreByTopic(in runs: [InterviewRun], questions: [Question]) -> [String: Int] {
        let topicByQuestion = Dictionary(questions.map { ($0.id, $0.topicID) }, uniquingKeysWith: { first, _ in first })
        var scores: [String: Int] = [:]
        for run in runs.sorted(by: { $0.completedAt > $1.completedAt }) {
            for result in run.results {
                guard let topicID = topicByQuestion[result.questionID], scores[topicID] == nil else {
                    continue
                }
                scores[topicID] = result.score
            }
        }
        return scores
    }
}
