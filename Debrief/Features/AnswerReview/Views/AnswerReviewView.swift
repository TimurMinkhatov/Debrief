//
//  AnswerReviewView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct AnswerReviewView: View {

    @State private var viewModel: AnswerReviewViewModel

    init(viewModel: AnswerReviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            loadingMessage: "Загружаем ответы",
            errorTitle: "Не удалось открыть ответы",
            retry: viewModel.load
        ) { review in
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacing) {
                    HStack {
                        if let topicTitle = review.topicTitle {
                            Text(topicTitle)
                                .font(.headline)
                        }
                        Spacer()
                        ScoreBadge(score: viewModel.result.score)
                    }
                    .card()

                    VStack(spacing: 12) {
                        ForEach(review.messages) { message in
                            MessageBubble(message: message)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Что ожидалось", systemImage: "checklist")
                            .font(.headline)
                        Text(viewModel.coverageTitle(for: review))
                            .font(.caption)
                            .opacity(0.7)
                        ForEach(review.points) { point in
                            Label(point.text, systemImage: point.coverage.symbolName)
                                .font(.callout)
                                .opacity(point.coverage == .none ? 0.85 : 1)
                                .accessibilityValue(point.coverage.accessibilityTitle)
                        }
                    }
                    .card()
                }
                .padding(Metrics.screenPadding)
            }
            .screenBackground()
        }
        .navigationTitle("Ответы")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}
