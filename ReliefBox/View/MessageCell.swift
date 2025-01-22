//
//  MessageCell.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI

struct MessageCell: View {
    var contentMessage: String
    var isCurrentUser: Bool
    
    var body: some View {
        Text(contentMessage)
            .padding(10)
            .foregroundColor(Color.white)
            .background(isCurrentUser ? Color.blue : Color.green)
            .cornerRadius(10)
    }
}
