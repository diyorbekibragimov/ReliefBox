//
//  ChatView.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI
import Combine
import MLCSwift

struct ChatView: View {
    @State private var messages = DataSource.messages
    @State private var newMessage: String = ""
    
    @ObservedObject var llmEngine: LocalLLMEngine
    
    // ------------------- NEW STATE VARIABLES -------------------
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    
    // Build the full conversation as ChatCompletionMessage array
    private func buildConversation() -> [ChatCompletionMessage] {
        var conversation: [ChatCompletionMessage] = []
        
        conversation.append(Config.systemMessageRole)
        
        for msg in messages {
            let role = msg.isCurrentUser ? ChatCompletionRole.user : ChatCompletionRole.assistant
            conversation.append(ChatCompletionMessage(role: role, content: msg.content))
        }
        return conversation
    }
    
    // Appends the user message, then sends the entire conversation to the LLM
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
           || selectedImage != nil
        else {
            return
        }

        // 1) Create the message with text + selected image
        messages.append(
            Message(
                content: newMessage,
                isCurrentUser: true,
                image: selectedImage
            )
        )
        
        // Clear the user's input.
        newMessage = ""
        selectedImage = nil
        
        // 2) Insert an empty placeholder for the LLM’s upcoming reply.
        messages.append(Message(content: "", isCurrentUser: false))
        let replyIndex = messages.count - 1
        
        // 3) Build the entire conversation (including the new user message)
        let conversation = buildConversation()
        
        // 4) Call the LLM with the full conversation, streaming partial replies
        Task {
            do {
                for await responseChunk in await llmEngine.engine
                    .chat
                    .completions
                    .create(messages: conversation)
                {
                    if let partial = responseChunk.choices.first?.delta.content?.asText(),
                       !partial.isEmpty {
                        // Update the last (assistant) message in real time
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
    
    var body: some View {
        VStack(spacing: 0) {
            
            // The main chat area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(messages, id: \.self) { message in
                            MessageView(currentMessage: message)
                                .id(message)
                        }
                    }
                    // Auto-scroll after each message update
                    .onReceive(Just(messages)) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        withAnimation {
                            proxy.scrollTo(messages.last, anchor: .bottom)
                        }
                    }
                }.hideOnTap()
                
                // Bottom input bar
                HStack {
                    // MARK: - Left: "+" button
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .padding(6)
                            .background(
                                Circle()
                                    .foregroundColor(Color.gray.opacity(0.2))
                            )
                    }
                    .padding(.trailing, 6)
                    
                    // MARK: - Middle: Rounded text field + icons inside
                        ZStack(alignment: .leading) {
                            // Placeholder if there's no text
                            if newMessage.isEmpty {
                                Text("Send a message")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 12)
                            }
                            
                            // Actual text field plus mic or send icon
                            HStack {
                                TextField("", text: $newMessage)
                                    .padding(.leading, 8)
                                    .padding(.vertical, 6)
                                
                                if newMessage.isEmpty {
                                    // Show mic icon on the right (in gray)
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                } else {
                                    // Show send (arrow.up) button on the right
                                    Button(action: sendMessage) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 14))
                                            .bold()
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(
                                                Circle().foregroundColor(.blue)
                                            )
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding()
            }
        }
        // ------------------ PRESENT THE IMAGE PICKER SHEET ------------------
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}
