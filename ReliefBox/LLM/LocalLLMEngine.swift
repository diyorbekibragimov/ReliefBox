//
//  LocalLLMEngine.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI
import MLCSwift

class LocalLLMEngine: ObservableObject {
    let engine = MLCEngine()

    // 1) Add a loading state
    @Published var isModelLoaded: Bool = false
    
    init() {
        Task {
            // Example: If your model is in App Bundle => "bundle/Llama-3.2-3B-Instruct-q4f16_1-MLC"
            if let resourcePath = Bundle.main.resourceURL?
                .appendingPathComponent("bundle")
                .appendingPathComponent("Llama-3.2-3B-Instruct-q4f16_1-MLC")
            {
                let modelPath = resourcePath.path
                let modelLib  = "llama_q4f16_1_d44304359a2802d16aa168086928bcad"
                await engine.reload(modelPath: modelPath, modelLib: modelLib)
                
                // 2) Once done loading, mark as loaded
                await MainActor.run {
                    self.isModelLoaded = true
                }
            } else {
                print("Could not locate model folder in app bundle.")
                // If the model cannot be loaded, you might still want
                // to set isModelLoaded = true so it won't hang on splash:
                await MainActor.run {
                    self.isModelLoaded = true
                }
            }
        }
    }
}
