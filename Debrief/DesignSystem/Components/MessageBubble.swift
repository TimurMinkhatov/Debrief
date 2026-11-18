//
//  MessageBubble.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI

// MARK: - ChatMessage
struct ChatMessage: Identifiable, Equatable {
    let id: String
    let text: String
    let isFromInterviewer: Bool
    var code: String? = nil
}

// MARK: - MessageBubble
struct MessageBubble: View {
    let text: String
    let isFromInterviewer: Bool
    var code: String? = nil

    var body: some View {
        HStack {
            if !isFromInterviewer {
                Spacer(minLength: 48)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
                if let code {
                    CodeBlock(code: code)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isFromInterviewer ? Color.background : Color.card)
            .background(bubbleBackground)
            if isFromInterviewer && code == nil {
                Spacer(minLength: 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: isFromInterviewer ? .leading : .trailing)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: isFromInterviewer ? 4 : 18,
            bottomTrailingRadius: isFromInterviewer ? 18 : 4,
            topTrailingRadius: 18
        )
        if isFromInterviewer {
            shape.fill(Color.card)
        } else {
            shape
                .fill(Color.card.opacity(0.12))
                .overlay(shape.stroke(Color.card, lineWidth: 1.5))
        }
    }
}

extension MessageBubble {
    init(message: ChatMessage) {
        self.init(text: message.text, isFromInterviewer: message.isFromInterviewer, code: message.code)
    }
}

// MARK: - CodeBlock
struct CodeBlock: View {
    let code: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: false)
                .padding(12)
        }
        .foregroundStyle(Color.background)
        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - TypingIndicator
struct TypingIndicator: View {
    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
                .font(.title2.bold())
                .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating)
                .foregroundStyle(Color.background)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
        .accessibilityLabel("Интервьюер печатает")
    }
}
