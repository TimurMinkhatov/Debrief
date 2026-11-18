//
//  RunRow.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct RunRow: View {
    let run: InterviewRun

    var body: some View {
        HStack(spacing: Metrics.spacing) {
            ScoreRing(score: run.overallScore, lineWidth: 5)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(run.gradeSummary)
                    .font(.headline)
                Text("\(run.profession.title) · \(run.dateText)")
                    .font(.caption)
                    .opacity(0.7)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .opacity(0.6)
        }
        .card()
        .contentShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }
}
