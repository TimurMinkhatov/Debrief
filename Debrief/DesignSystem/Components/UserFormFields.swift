//
//  UserFormFields.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI
import DebriefDomain

struct UserFormFields: View {
    @Binding var name: String
    @Binding var profession: Profession
    @Binding var grade: Grade

    var body: some View {
        VStack(spacing: Metrics.spacing) {
            FormCard(title: "Имя") {
                TextField("", text: $name, prompt: Text("Как к тебе обращаться").foregroundStyle(Color.background.opacity(0.5)))
                    .font(.title3)
                    .textContentType(.givenName)
                    .submitLabel(.done)
            }
            FormCard(title: "Профессия") {
                ChipPicker(options: Profession.allCases, title: \.title, selection: $profession)
            }
            FormCard(title: "Целевой грейд") {
                ChipPicker(options: Grade.allCases, title: \.title, selection: $grade)
            }
        }
    }
}

// MARK: - FormCard
struct FormCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .opacity(0.7)
            content()
        }
        .card()
    }
}
