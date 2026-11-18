//
//  StateViews.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI

// MARK: - LoadingStateView
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: Metrics.spacing) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.background)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .padding(Metrics.spacing * 2)
        .foregroundStyle(Color.background)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .padding(Metrics.screenPadding)
        .screenBackground()
    }
}

// MARK: - ErrorStateView
struct ErrorStateView: View {
    var title: String = "Что-то пошло не так"
    let error: Error
    var retryTitle: String = "Повторить"
    let retry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        MessageStateView(systemImage: "exclamationmark.triangle", title: title, message: error.localizedDescription) {
            Button {
                Task {
                    isRetrying = true
                    await retry()
                    isRetrying = false
                }
            } label: {
                if isRetrying {
                    ProgressView().tint(Color.card)
                } else {
                    Text(retryTitle)
                }
            }
            .buttonStyle(.inverted)
            .disabled(isRetrying)
        }
    }
}

// MARK: - EmptyStateView
struct EmptyStateView<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        MessageStateView(systemImage: systemImage, title: title, message: message, actions: actions)
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}

// MARK: - MessageStateView
private struct MessageStateView<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: Metrics.spacing) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .semibold))
                .symbolEffect(.bounce, options: .nonRepeating)
            Text(title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .opacity(0.8)
            actions()
        }
        .padding(Metrics.spacing * 1.5)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.background)
        .background(Color.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .padding(Metrics.screenPadding)
        .screenBackground()
    }
}

// MARK: - InvertedButtonStyle
struct InvertedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(Color.card)
            .background(Color.background, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius - 6))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InvertedButtonStyle {
    static var inverted: InvertedButtonStyle { InvertedButtonStyle() }
}
