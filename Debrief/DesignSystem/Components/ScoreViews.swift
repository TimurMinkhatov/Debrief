//
//  ScoreViews.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI

// MARK: - ScoreRing
struct ScoreRing: View {
    let score: Int
    var lineWidth: CGFloat = 12

    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.background.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.background, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.1)
                .padding(lineWidth * 2)
                .contentTransition(.numericText(value: progress))
        }
        .foregroundStyle(Color.background)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                progress = Double(score) / 100
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                progress = Double(newValue) / 100
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Балл \(score) из 100")
    }
}

// MARK: - ScoreBar
struct ScoreBar: View {
    let score: Int?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.background.opacity(0.2))
                Capsule()
                    .fill(Color.background)
                    .frame(width: proxy.size.width * Double(score ?? 0) / 100)
            }
        }
        .frame(height: 8)
        .animation(.easeOut(duration: 0.6), value: score)
    }
}

// MARK: - ScoreBadge
struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.headline.monospacedDigit())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(Color.card)
            .background(Color.background, in: Capsule())
    }
}
