//
//  ResultView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct ResultView: View {

    @State private var viewModel: ResultViewModel

    init(viewModel: ResultViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            loadingMessage: "Готовим разбор",
            errorTitle: "Не удалось открыть разбор",
            retry: viewModel.load
        ) {
            EmptyStateView(systemImage: "doc", title: "Разбор пуст", message: "В этом прогоне нет ответов.")
        } loaded: { content in
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacing) {
                    summaryCard
                    if let verdict = viewModel.verdict {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Вердикт", systemImage: "text.quote")
                                .font(.headline)
                            Text(verdict)
                                .font(.callout)
                        }
                        .card()
                    }
                    ForEach(content.sections) { section in
                        SectionHeader(title: section.title, symbolName: section.stage.symbolName, score: section.averageScore)
                        ForEach(section.items) { item in
                            Button { viewModel.open(item) } label: {
                                ResultItemCard(item: item)
                            }
                            .buttonStyle(.plain)
                            .scrollTransition(.animated(.smooth)) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.4)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
                            }
                        }
                    }
                    if let review = content.resumeReview {
                        SectionHeader(title: viewModel.resumeTitle, symbolName: StageKind.resume.symbolName, score: nil)
                        ResumeReviewCard(review: review)
                    }
                }
                .padding(Metrics.screenPadding)
            }
            .screenBackground()
        }
        .navigationTitle("Результат")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var summaryCard: some View {
        VStack(spacing: Metrics.spacing) {
            ScoreRing(score: viewModel.run.overallScore)
                .frame(width: 150, height: 150)
            VStack(spacing: 4) {
                Text(viewModel.gradeTitle)
                    .font(.title2.bold())
                Text(viewModel.subtitle)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .opacity(0.75)
            }
        }
        .frame(maxWidth: .infinity)
        .card(padding: Metrics.spacing * 1.5)
    }
}

// MARK: - SectionHeader
private struct SectionHeader: View {
    let title: String
    let symbolName: String
    let score: Int?

    var body: some View {
        HStack {
            Label(title, systemImage: symbolName)
                .font(.title3.bold())
            Spacer()
            if let score {
                Text("\(score)")
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(Color.background)
                    .background(Color.card, in: Capsule())
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - ResumeReviewCard
private struct ResumeReviewCard: View {
    let review: ResumeReview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(review.summary)
                .font(.callout)
            ReviewList(title: "Сильные стороны", symbolName: "plus.circle", items: review.strengths)
            ReviewList(title: "Что усилить", symbolName: "arrow.up.circle", items: review.gaps)
        }
        .card()
    }
}

// MARK: - ReviewList
private struct ReviewList: View {
    let title: String
    let symbolName: String
    let items: [String]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .opacity(0.7)
                ForEach(items, id: \.self) { item in
                    Label(item, systemImage: symbolName)
                        .font(.callout)
                }
            }
        }
    }
}

// MARK: - ResultItemCard
private struct ResultItemCard: View {
    let item: ResultViewModel.Item

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.caption)
                    .font(.caption.weight(.semibold))
                    .opacity(0.7)
                Spacer()
                ScoreBadge(score: item.result.score)
            }
            Text(item.result.turn.question)
                .font(.headline)
                .multilineTextAlignment(.leading)
            ForEach(item.result.missedPoints, id: \.self) { point in
                Label(point, systemImage: Coverage.none.symbolName)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
            }
            ForEach(item.result.partialPoints, id: \.self) { point in
                Label(point, systemImage: Coverage.partial.symbolName)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
            }
            HStack {
                Label(item.gapsTitle, systemImage: item.isComplete ? "checkmark.seal" : "list.bullet")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Ответы")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
            }
            .opacity(0.85)
        }
        .card()
        .contentShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }
}
