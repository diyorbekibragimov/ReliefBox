//
//  ChatView.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 01/02/2025.
//

import SwiftUI
import Combine
import MLCSwift

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isOnline = false
    @State private var threadId: String?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @ObservedObject var llmEngine: LocalLLMEngine
    private let networkManager = NetworkManager()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages.indices, id: \.self) { index in
                            MessageView(currentMessage: messages[index])
                                .id(index)
                                .padding(.horizontal)
                                .padding(.vertical, 4) // Add vertical spacing
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80) // Increase bottom padding
                }
                .onChange(of: messages) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Loading Indicator
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
            }
            
            // Input Area
            inputField
                .padding(.bottom, keyboardHeight > 0 ? 0 : UIApplication.shared.windows.first?.safeAreaInsets.bottom)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
                .keyboardAdaptive()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .hideOnTap()
        .navigationBarItems(trailing: onlineToggle)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var onlineToggle: some View {
        Toggle(isOn: $isOnline) {
            Text(isOnline ? "Online" : "Offline")
                .font(.caption)
                .foregroundColor(isOnline ? .green : .gray)
        }
        .toggleStyle(SwitchToggleStyle(tint: .green))
        .padding(.trailing)
    }
    
    private var inputField: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: { showImagePicker = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18))
                    .padding(8)
                    .background(Circle().fill(Color.gray.opacity(0.1)))
                    .foregroundColor(.gray)
            }
            
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                    .submitLabel(.send)
                    .onSubmit(sendMessage)
                
                if !newMessage.isEmpty {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isOnline ? .green : .blue)
                            .padding(.trailing, 8)
                    }
                    .transition(.scale)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 48)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard !messages.isEmpty else { return }
        let lastIndex = messages.count - 1
        withAnimation {
            proxy.scrollTo(lastIndex, anchor: .bottom)
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil else { return }
        
        let userMessage = Message(
            content: newMessage,
            isCurrentUser: true,
            image: selectedImage
        )
        
        messages.append(userMessage)
        newMessage = ""
        selectedImage = nil
        
        if isOnline {
            handleOnlineMessage()
        } else {
            handleOfflineMessage()
        }
    }
    
    private func handleOnlineMessage() {
        isLoading = true
        messages.append(Message(content: "", isCurrentUser: false))
        let replyIndex = messages.count - 1
        
        Task {
            do {
                // Create thread if needed
                if threadId == nil {
                    threadId = try await networkManager.createThread()
                }
                
                // Send message
                if let threadId = threadId {
                    let response = try await networkManager.sendMessage(message: messages[messages.count-2].content, threadId: threadId)
                    
                    await MainActor.run {
                        messages[replyIndex].content = response
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    messages.removeLast()
                }
            }
        }
    }
    
    private func handleOfflineMessage() {
        messages.append(Message(content: "", isCurrentUser: false))
        let replyIndex = messages.count - 1
        
        Task {
            do {
                for await responseChunk in await llmEngine.engine.chat.completions.create(messages: buildConversation()) {
                    if let partial = responseChunk.choices.first?.delta.content?.asText(), !partial.isEmpty {
                        await MainActor.run {
                            messages[replyIndex].content += partial
                        }
                    }
                }
            } catch {
                print("LLM error: \(error)")
            }
        }
    }
    
    private func buildConversation() -> [ChatCompletionMessage] {
        var conversation: [ChatCompletionMessage] = [Config.systemMessageRole]
        messages.forEach { message in
            let role: ChatCompletionRole = message.isCurrentUser ? .user : .assistant
            conversation.append(ChatCompletionMessage(role: role, content: message.content))
        }
        return conversation
    }
}

// MARK: - Network Manager
import Just

class NetworkManager {
    private let baseURL = "https://reliefbox.hasanbek.me"
    
    func createThread() async throws -> String {
        let response = Just.get("\(baseURL)/thread/create")
        
        guard response.ok else {
            throw NSError(domain: "NetworkError", code: response.statusCode ?? 500,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create thread"])
        }
        
        guard let json = response.json as? [String: Any],
              let threadId = json["threadId"] as? String else {
            throw NSError(domain: "ParseError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return threadId
    }
    
    func sendMessage(message: String, threadId: String) async throws -> String {
        let url = "\(baseURL)/thread/\(threadId)/chat"
        let response = Just.post(
            url,
            data: ["message": message],
            headers: ["Accept": "application/json"]
        )
        
        guard response.ok else {
            let errorBody = response.text ?? "No error message"
            throw NSError(domain: "NetworkError", code: response.statusCode ?? 500,
                        userInfo: [NSLocalizedDescriptionKey: "Server error: \(errorBody)"])
        }
        
        guard let json = response.json as? [String: Any],
              let aiResponse = json["ai_response"] as? String else {
            throw NSError(domain: "ParseError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return aiResponse
    }
}


struct ThreadCreationResponse: Codable {
    let threadId: String
}

struct ChatResponse: Codable {
    let aiResponse: String
}

// MARK: - Keyboard Handling
fileprivate struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height > 0 ? height - 34 : 0
                }
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}
