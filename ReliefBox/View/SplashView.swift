//
//  SplashView.swift
//  ReliefBox
//
//  Created by Hasan Hakimjanov on 22/01/2025.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Simple white background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                
                // Logo
                Image("MedicalKit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .padding(.bottom, 8)

                // Title
                Text("ReliefBox")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                // Loading indicator
                ProgressView("Loading...")
                    .padding(.bottom, 50)
            }
        }
    }
}
