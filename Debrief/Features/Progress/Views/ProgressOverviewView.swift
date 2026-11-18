//
//  ProgressOverviewView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct ProgressOverviewView: View {

    @State private var viewModel: ProgressOverviewViewModel

    init(viewModel: ProgressOverviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            loadingMessage: "Считаем прогресс",
            errorTitle: "Не удалось загрузить прогресс",
            retry: viewModel.load
        ) {
            EmptyStateView(systemImage: "chart.bar.xaxis", title: "Прогресса пока нет", message: viewModel.emptyMessage)
        } loaded: { overview in
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacing) {
                    HStack(spacing: Metrics.spacing) {
                        ScoreRing(score: overview.averageScore, lineWidth: 7)
                            .frame(width: 72, height: 72)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Средний балл")
                                .font(.caption.weight(.semibold))
                                .opacity(0.7)
                            Text("Прогонов: \(overview.totalRuns)")
                                .font(.headline)
                        }
                    }
                    .card()

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Темы", systemImage: "square.grid.2x2")
                            .font(.headline)
                        Text(viewModel.topicsCaption)
                            .font(.caption)
                            .opacity(0.7)
                        ForEach(overview.topics) { row in
                            TopicScoreRow(row: row)
                        }
                    }
                    .card()

                    Text("Последние прогоны")
                        .font(.title3.bold())
                        .padding(.top, 8)

                    ForEach(overview.recentRuns) { run in
                        Button { viewModel.open(run) } label: {
                            RunRow(run: run)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(viewModel.historyTitle(for: overview), action: viewModel.openHistory)
                        .buttonStyle(.primary)
                }
                .padding(Metrics.screenPadding)
            }
            .screenBackground()
            .refreshable { await viewModel.load() }
        }
        .navigationTitle(viewModel.title)
        .task { await viewModel.load() }
    }
}

// MARK: - TopicScoreRow
private struct TopicScoreRow: View {
    let row: ProgressOverviewViewModel.TopicRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.topic.title)
                    .font(.subheadline)
                Spacer()
                Text(row.scoreText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            ScoreBar(score: row.score)
                .opacity(row.score == nil ? 0.5 : 1)
        }
    }
}
