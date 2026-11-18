//
//  InterviewView.swift
//  Debrief
//
//  Created by Timur Minkhatov on 07/10/2026.
//

import SwiftUI
import DebriefDomain

struct InterviewView: View {

    @State private var viewModel: InterviewViewModel

    init(viewModel: InterviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            loadingMessage: "Подбираем вопросы",
            errorTitle: "Не удалось продолжить",
            retry: viewModel.retry
        ) {
            EmptyStateView(systemImage: "tray", title: "Вопросов пока нет", message: viewModel.emptyMessage) {
                Button("Выбрать другой", action: viewModel.leave)
                    .buttonStyle(.inverted)
            }
        } loaded: { stage in
            switch stage {
            case .answering where viewModel.isResumeStep:
                ResumeStepView(viewModel: viewModel)
                    .transition(.screenContent)
            case .answering:
                ChatView(viewModel: viewModel)
            case .finishing:
                LoadingStateView(message: "Подводим итоги")
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isExitGuarded)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            if viewModel.state.content == .answering {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Выйти", systemImage: "xmark", action: viewModel.requestExit)
                }
            }
        }
        .alert("Прервать собеседование?", isPresented: $viewModel.isExitConfirmationPresented) {
            Button("Продолжить", role: .cancel) {}
            Button("Прервать", role: .destructive, action: viewModel.leave)
        } message: {
            Text("Ответы этого прогона не сохранятся.")
        }
        .task { await viewModel.start() }
    }
}

// MARK: - ChatView
private struct ChatView: View {

    @Bindable var viewModel: InterviewViewModel

    private let bottomID = "bottom"

    var body: some View {
        VStack(spacing: 0) {
            StageHeader(viewModel: viewModel)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .transition(.asymmetric(
                                    insertion: .move(edge: message.isFromInterviewer ? .leading : .trailing)
                                        .combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        if viewModel.isSending {
                            TypingIndicator()
                                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                        }
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding(Metrics.screenPadding)
                    .id(viewModel.flow.currentIndex)
                    .transition(.push(from: .trailing))
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.smooth, value: viewModel.messages)
                .animation(.smooth, value: viewModel.isSending)
                .animation(.smooth(duration: 0.5), value: viewModel.flow.currentIndex)
                .onChange(of: viewModel.messages) {
                    withAnimation(.smooth) { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
                .onChange(of: viewModel.isSending) {
                    withAnimation(.smooth) { proxy.scrollTo(bottomID, anchor: .bottom) }
                }
            }

            if let error = viewModel.sendError {
                SendErrorBanner(error: error, dismiss: viewModel.dismissSendError)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            inputBar
        }
        .animation(.smooth, value: viewModel.sendError != nil)
        .screenBackground()
        .sensoryFeedback(.success, trigger: viewModel.flow.currentIndex)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "",
                text: $viewModel.input,
                prompt: Text(viewModel.inputPlaceholder).foregroundStyle(Color.background.opacity(0.55)),
                axis: .vertical
            )
            .lineLimit(1...6)
            .foregroundStyle(Color.background)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.card, in: RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            .disabled(viewModel.isSending)

            Button {
                Task { await viewModel.submit() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.headline)
                    .foregroundStyle(Color.background)
                    .frame(width: 44, height: 44)
                    .background(Color.card, in: Circle())
            }
            .disabled(!viewModel.canSend)
            .opacity(viewModel.canSend ? 1 : 0.4)
            .animation(.snappy, value: viewModel.canSend)
            .accessibilityLabel("Отправить")
        }
        .padding(.horizontal, Metrics.screenPadding)
        .padding(.vertical, 10)
    }
}

// MARK: - StageHeader
private struct StageHeader: View {
    let viewModel: InterviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let caption = viewModel.stageCaption, let symbol = viewModel.currentStageSymbol {
                Label(caption, systemImage: symbol)
                    .font(.caption.weight(.semibold))
                    .opacity(0.75)
                    .contentTransition(.opacity)
            }
            ProgressView(value: viewModel.progress)
                .tint(Color.card)
        }
        .padding(.horizontal, Metrics.screenPadding)
        .animation(.smooth, value: viewModel.progress)
        .animation(.smooth, value: viewModel.stageCaption)
    }
}

// MARK: - ResumeStepView
private struct ResumeStepView: View {

    @Bindable var viewModel: InterviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            StageHeader(viewModel: viewModel)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.spacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(viewModel.resumeTitle, systemImage: StageKind.resume.symbolName)
                            .font(.headline)
                        Text(viewModel.resumeMessage)
                            .font(.callout)
                            .opacity(0.8)
                    }
                    .card()

                    TextField(
                        "",
                        text: $viewModel.input,
                        prompt: Text(viewModel.inputPlaceholder).foregroundStyle(Color.background.opacity(0.55)),
                        axis: .vertical
                    )
                    .lineLimit(8...20)
                    .foregroundStyle(Color.background)
                    .card()
                    .disabled(viewModel.isSending)

                    if let error = viewModel.sendError {
                        SendErrorBanner(error: error, dismiss: viewModel.dismissSendError)
                            .padding(.horizontal, -Metrics.screenPadding)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    SaveButton(title: viewModel.resumeSubmitTitle, isSaving: viewModel.isSending) {
                        await viewModel.submit()
                    }
                    .disabled(!viewModel.canSend)

                    Button(viewModel.resumeSkipTitle) {
                        Task { await viewModel.skipResume() }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isSending)
                }
                .padding(Metrics.screenPadding)
                .animation(.smooth, value: viewModel.sendError != nil)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .screenBackground()
    }
}

// MARK: - SendErrorBanner
private struct SendErrorBanner: View {
    let error: Error
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
            VStack(alignment: .leading, spacing: 2) {
                Text("Ответ не отправился")
                    .font(.subheadline.bold())
                Text(error.localizedDescription)
                    .font(.caption)
                    .opacity(0.8)
                    .lineLimit(3)
            }
            Spacer()
            Button("Закрыть", systemImage: "xmark", action: dismiss)
                .labelStyle(.iconOnly)
        }
        .card(padding: 12)
        .padding(.horizontal, Metrics.screenPadding)
    }
}
