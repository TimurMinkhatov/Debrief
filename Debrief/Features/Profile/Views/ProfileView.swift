//
//  ProfileView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct ProfileView: View {

    @State private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacing) {
                UserFormFields(name: $viewModel.name, profession: $viewModel.profession, grade: $viewModel.grade)

                FormStatusLabel(state: viewModel.state, savedMessage: viewModel.savedMessage, hasChanges: viewModel.hasChanges)

                SaveButton(title: viewModel.saveTitle, isSaving: viewModel.state.isSaving) {
                    await viewModel.save()
                }
                .disabled(!viewModel.canSave)
            }
            .padding(Metrics.screenPadding)
            .animation(.smooth, value: viewModel.state.phase)
            .animation(.smooth, value: viewModel.hasChanges)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .navigationTitle(viewModel.title)
        .sensoryFeedback(.success, trigger: viewModel.state.phase == .saved)
    }
}
