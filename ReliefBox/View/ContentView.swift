//
//  ContentView.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var llmEngine = LocalLLMEngine()
    @StateObject private var locationManager = LocationManager() // Initialize here

    var body: some View {
        ZStack {
            if llmEngine.isModelLoaded {
                HomeView(llmEngine: llmEngine)
                    .environmentObject(locationManager) // Pass to HomeView
                    .transition(.opacity)
            } else {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: llmEngine.isModelLoaded)
        .onChange(of: llmEngine.isModelLoaded) { isLoaded in
            if isLoaded {
                locationManager.requestLocationPermission() // Request location after splash
            }
        }
    }
}
