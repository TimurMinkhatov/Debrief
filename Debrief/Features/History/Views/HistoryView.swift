//
//  HistoryView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct HistoryView: View {

    @State private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ChipPicker(options: viewModel.filters, title: \.title, selection: $viewModel.filter)
                .card(padding: 6)
                .padding(.horizontal, Metrics.screenPadding)
                .padding(.bottom, 8)

            StateContainer(
                state: viewModel.state,
                loadingMessage: "Загружаем историю",
                errorTitle: "Не удалось загрузить историю",
                retry: viewModel.load
            ) {
                EmptyStateView(systemImage: "clock.arrow.circlepath", title: "Пусто", message: viewModel.emptyMessage)
            } loaded: { sections in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(sections) { section in
                            Text(section.title)
                                .font(.headline)
                                .padding(.top, 8)
                            ForEach(section.runs) { run in
                                Button { viewModel.open(run) } label: {
                                    RunRow(run: run)
                                }
                                .buttonStyle(.plain)
                                .scrollTransition(.animated(.smooth)) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.4)
                                        .offset(y: phase.value * 12)
                                }
                            }
                        }
                    }
                    .padding(Metrics.screenPadding)
                }
                .screenBackground()
            }
        }
        .screenBackground()
        .navigationTitle(viewModel.title)
        .task { await viewModel.load() }
    }
}
