//
//  ChatViewModel.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 20/01/2025.
//

import SwiftUI
import ExyteChat

class ChatViewModel: ObservableObject {
    @Published var messages: [ExyteChat.Message] = []
    
    private var currentUser: User {
        User(id: "user123", name: "User", avatarURL: nil, isCurrentUser: true)
    }
    
    func send(draft: ExyteChat.DraftMessage) {
        let user = currentUser
        
        print(draft.medias)
        
        let newMessage = ExyteChat.Message(
            id: UUID().uuidString,
            user: user,
            text: draft.text
        )
        
        messages.append(newMessage)
    }
}
