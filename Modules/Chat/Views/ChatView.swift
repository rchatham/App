//
//  ChatView.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import SwiftUI

public struct ChatView: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var promptTextFieldIsActive: Bool

    public init() {
        viewModel = ViewModel(messageService: MessageService())
    }

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack {
                messageList
                messageComposerView
                    .invalidInputAlert(isPresented: $viewModel.showAlert)
                    .enterAPIKeyAlert(
                        isPresented: $viewModel.enterApiKey,
                        apiKey: $viewModel.apiKey)
            }
            .navigationTitle("ChatGPT")
            .toolbar {
                #if DEBUG
                NavigationLink(destination: viewModel.settingsView()) {
                    Image(systemName: "gear")
                }
                #endif
            }
            .dismissKeyboardOnSwipe()
        }
    }

    @ViewBuilder
    var messageList: some View {
        MessageListView(viewModel: viewModel.messageListViewModel())
    }

    @ViewBuilder
    var messageComposerView: some View {
        MessageComposerView(viewModel: viewModel.messageComposerViewModel())
    }
}

extension ChatView {
    @MainActor class ViewModel: ObservableObject {
        @Published var apiKey = ""
        @Published var input = ""
        @Published var showAlert = false
        @Published var enterApiKey = false
        private let messageService: MessageService

        init(messageService: MessageService) {
            self.messageService = messageService
        }

        func delete(id: UUID) {
            Task {
                await messageService.deleteMessage(id: id)
            }
        }

        func settingsView() -> some View {
            return ChatSettingsView(viewModel: ChatSettingsView.ViewModel())
        }

        func messageComposerViewModel() -> MessageComposerView.ViewModel {
            return MessageComposerView.ViewModel(messageService: messageService)
        }

        func messageListViewModel() -> MessageListView.ViewModel {
            return MessageListView.ViewModel(messageService: messageService)
        }
    }
}

// A reusable View extension to add keyboard dismissal
extension View {
    /// Adds a drag gesture to dismiss the keyboard when swiping down
    func dismissKeyboardOnSwipe() -> some View {
        self.gesture(
            DragGesture()
                .onChanged { _ in
#if os(iOS)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
                }
        )
    }
}
