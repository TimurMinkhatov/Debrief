//
//  Styles.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI

// MARK: - Metrics
enum Metrics {
    static let cornerRadius: CGFloat = 20
    static let screenPadding: CGFloat = 20
    static let spacing: CGFloat = 16
}

// MARK: - CardModifier
private struct CardModifier: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Color.background)
            .background(Color.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }
}

// MARK: - ScreenBackground
private struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .toolbarBackground(Color.background, for: .navigationBar)
            .foregroundStyle(Color.card)
    }
}

extension View {
    func card(padding: CGFloat = Metrics.spacing) -> some View {
        modifier(CardModifier(padding: padding))
    }

    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}

// MARK: - PrimaryButtonStyle
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Metrics.spacing)
            .foregroundStyle(Color.background)
            .background(Color.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
