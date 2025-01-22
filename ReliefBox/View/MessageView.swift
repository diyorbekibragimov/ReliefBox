//
//  MessageView.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI

struct MessageView: View {
    let currentMessage: Message
    
    var body: some View {
        HStack {
            if currentMessage.isCurrentUser {
                Spacer()
                
                // VSTACK for image + text
                VStack(alignment: .trailing) {
                    // 1. Show image if available
                    if let image = currentMessage.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250)
                            .cornerRadius(12)
                            .padding(.bottom, 4)
                    }
                    
                    // 2. Existing text bubble
                    Text(.init(currentMessage.content))
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color.green)
                        .cornerRadius(12)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .trailing)
                }
                
            } else {
                // VSTACK for image + text (left alignment)
                VStack(alignment: .leading) {
                    // 1. Show image if available
                    if let image = currentMessage.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250)
                            .cornerRadius(12)
                            .padding(.bottom, 4)
                    }
                    
                    // 2. Existing text bubble
                    Text(.init(currentMessage.content))
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .leading)
                }

                Spacer()
            }
        }
        .padding([.horizontal, .top], 5)
    }
}
