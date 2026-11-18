//
//  OnboardingView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 29/09/2026.
//

import SwiftUI
import DebriefDomain

struct OnboardingView: View {

    @State private var viewModel: OnboardingViewModel
    @State private var isAppeared = false

    init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacing * 1.5) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.title)
                        .font(.largeTitle.bold())
                    Text(viewModel.subtitle)
                        .font(.callout)
                        .opacity(0.8)
                }
                .padding(.top, Metrics.spacing * 2)

                UserFormFields(name: $viewModel.name, profession: $viewModel.profession, grade: $viewModel.grade)
                    .opacity(isAppeared ? 1 : 0)
                    .offset(y: isAppeared ? 0 : 24)

                FormStatusLabel(state: viewModel.state)

                SaveButton(title: viewModel.saveTitle, isSaving: viewModel.state.isSaving) {
                    await viewModel.save()
                }
                .disabled(!viewModel.canSave)
            }
            .padding(Metrics.screenPadding)
            .animation(.smooth, value: viewModel.state.phase)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .onAppear {
            withAnimation(.smooth(duration: 0.6).delay(0.15)) {
                isAppeared = true
            }
        }
    }
}
