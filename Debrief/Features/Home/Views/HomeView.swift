//
//  HomeView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/10/2026.
//

import SwiftUI
import DebriefDomain

struct HomeView: View {

    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            loadingMessage: "Загружаем историю",
            errorTitle: "Не удалось загрузить историю",
            retry: viewModel.load
        ) { summary in
            ScrollView {
                VStack(spacing: Metrics.spacing) {
                    startCard
                    lastRunCard(summary: summary)
                }
                .padding(Metrics.screenPadding)
            }
            .screenBackground()
        }
        .navigationTitle(viewModel.greeting)
        .task { await viewModel.load() }
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: Metrics.spacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.startTitle)
                    .font(.title2.bold())
                Text(viewModel.startDescription)
                    .font(.callout)
                    .opacity(0.8)
            }
            ChipPicker(options: viewModel.professions, title: \.title, selection: $viewModel.selectedProfession)
            ChipPicker(options: viewModel.grades, title: \.title, selection: $viewModel.selectedGrade)
            Button("Начать", action: viewModel.startInterview)
                .buttonStyle(.inverted)
        }
        .card(padding: Metrics.spacing * 1.25)
    }

    @ViewBuilder
    private func lastRunCard(summary: HomeViewModel.Summary) -> some View {
        if let run = summary.lastRun {
            Button(action: viewModel.openLastRun) {
                HStack(spacing: Metrics.spacing) {
                    ScoreRing(score: run.overallScore, lineWidth: 7)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Последний прогон")
                            .font(.caption.weight(.semibold))
                            .opacity(0.7)
                        Text(run.gradeSummary)
                            .font(.headline)
                        if let caption = viewModel.lastRunCaption(for: summary) {
                            Text(caption)
                                .font(.caption)
                                .opacity(0.7)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.bold())
                        .opacity(0.6)
                }
                .card()
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label(viewModel.emptyHistoryTitle, systemImage: "sparkles")
                    .font(.headline)
                Text(viewModel.emptyHistoryMessage)
                    .font(.callout)
                    .opacity(0.8)
            }
            .card()
        }
    }
}
