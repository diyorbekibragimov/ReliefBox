//
//  ContentView.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var llmEngine = LocalLLMEngine()
    
    var body: some View {
        ZStack {
            if llmEngine.isModelLoaded {
                // Main chat UI
                ChatView(llmEngine: llmEngine)
                    .transition(.opacity)
            } else {
                SplashView()
                    .transition(.opacity)
            }
        }
        // Animate changes in the if/else
        .animation(.easeInOut(duration: 0.8), value: llmEngine.isModelLoaded)
    }
}
