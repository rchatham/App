//
//  MessageComposerView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/2/23.
//

import SwiftUI

struct MessageComposerView: View {
    @StateObject var viewModel: ViewModel
    @FocusState private var promptTextFieldIsActive
    
    var body: some View {
        HStack {
            TextField("Enter your prompt", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.automatic)
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10))
                .foregroundColor(.primary)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .focused($promptTextFieldIsActive)
                .submitLabel(.done)
                .onSubmit(submitButtonTapped)
            Button(action: submitButtonTapped) {
                Text("Submit")
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 20))
                    .foregroundColor(.accentColor)
            }
        }
//        .defaultFocus($promptTextFieldIsActive, true, priority: .automatic)
//        .invalidInputAlert(isPresented: $viewModel.showAlert)
        .alert(isPresented: $viewModel.showAlert, content: {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
        })
        .enterAPIKeyAlert(
            isPresented: $viewModel.enterApiKey,
            apiKey: $viewModel.apiKey)
    }
    
    func submitButtonTapped() {
        viewModel.sendMessage()
        promptTextFieldIsActive = true
   }
}

extension MessageComposerView {
    @MainActor class ViewModel: ObservableObject {
        @Published var input: String = ""

        @Published var showAlert = false
        @Published var errorMessage: String = ""
        @Published var enterApiKey = false
        @Published var apiKey = ""

        private let messageService: MessageService

        init(messageService: MessageService) {
            self.messageService = messageService
        }
        
        func sendMessage() {
            guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            // Send the message completion request
            Task { [input] in
                do { try await messageService.performMessageCompletionRequest(message: input, stream: true) }
                catch let error as LangToolchainError {
                    switch error {
                    case .toolchainCannotHandleRequest:
                        print("cannot handle request, probably a missing api key")
                        self.enterApiKey = true
                    }
                }
//                catch let error as NetworkClient.NetworkError.missingApiKey {
//                    self.enterApiKey = true
//                }
                catch {
                    print("Error sending message completion request: \(error)")
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
            // Clear the input field
            input = ""
        }
    }
}

//struct MessageComposerView_Previews: PreviewProvider {
//    static var previews: some View {
//        MessageComposerView(viewModel: MessageComposerView.ViewModel(messageService: MessageService(messageDB: MessageDB(persistence: PersistenceController.preview)), conversation: Conversation.example()))
//    }
//}
