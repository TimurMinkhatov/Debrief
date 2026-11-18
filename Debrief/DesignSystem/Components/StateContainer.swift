//
//  StateContainer.swift
//  Debrief
//
//  Created by Timur Minkhatov on 01/11/2026.
//

import SwiftUI

struct StateContainer<Content, Loaded: View, Empty: View>: View {
    let state: ScreenState<Content>
    let loadingMessage: String
    let errorTitle: String
    let retry: () async -> Void
    @ViewBuilder let empty: () -> Empty
    @ViewBuilder let loaded: (Content) -> Loaded

    var body: some View {
        ZStack {
            switch state {
            case .loading:
                LoadingStateView(message: loadingMessage)
                    .transition(.screenContent)
            case .empty:
                empty()
                    .transition(.screenContent)
            case .failed(let error):
                ErrorStateView(title: errorTitle, error: error, retry: retry)
                    .transition(.screenContent)
            case .loaded(let content):
                loaded(content)
                    .transition(.screenContent)
            }
        }
    }
}

extension AnyTransition {
    static var screenContent: AnyTransition {
        .opacity.animation(.smooth(duration: 0.3))
    }
}

extension StateContainer where Empty == EmptyView {
    init(
        state: ScreenState<Content>,
        loadingMessage: String,
        errorTitle: String,
        retry: @escaping () async -> Void,
        @ViewBuilder loaded: @escaping (Content) -> Loaded
    ) {
        self.init(
            state: state,
            loadingMessage: loadingMessage,
            errorTitle: errorTitle,
            retry: retry,
            empty: { EmptyView() },
            loaded: loaded
        )
    }
}
