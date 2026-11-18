//
//  FormControls.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI

// MARK: - SaveButton
struct SaveButton: View {
    let title: String
    let isSaving: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                Text(title).opacity(isSaving ? 0 : 1)
                if isSaving {
                    ProgressView().tint(Color.background)
                }
            }
        }
        .buttonStyle(.primary)
    }
}

// MARK: - FormStatusLabel
struct FormStatusLabel: View {
    let state: FormState
    var savedMessage: String = "Сохранено"
    var hasChanges: Bool = false

    var body: some View {
        Group {
            switch state {
            case .saved:
                Label(savedMessage, systemImage: "checkmark.circle")
            case .failed(let error):
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
            case .editing where hasChanges:
                Label("Есть несохранённые изменения", systemImage: "pencil")
                    .opacity(0.7)
            case .editing, .saving:
                EmptyView()
            }
        }
        .font(.callout)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
