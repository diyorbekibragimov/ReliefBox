//
//  ProfileView.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 31/01/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var llmEngine: LocalLLMEngine
    @State private var selectedTab: Int = 0
    @State private var navigateToSettings: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with back button
                ZStack {
                    // Leading Back Button (Chat View only)
                    HStack {
                        if selectedTab == 1 {
                            Button(action: {
                                withAnimation {
                                    selectedTab = 0 // Return to Home
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.leading, 16)
                            }
                        }
                        Spacer()
                    }
                    
                    // Centered Title
                    HStack(spacing: 8) {
                        Spacer()
                        HStack(spacing: 8) {
                            Image("MedicalKit")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            Text("ReliefBox")
                                .font(.title)
                                .bold()
                        }
                        Spacer()
                    }
                    
                    // Trailing Settings Button
                    HStack {
                        Spacer()
                        Button(action: { navigateToSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                                .padding(.trailing, 16)
                                .padding(.top, -4)
                        }
                    }
                }
                .padding()
                .frame(height: 60)

                // Main Content
                VStack(spacing: 0) {
                    switch selectedTab {
                    case 0: FeedView()
                    case 1: ChatView(llmEngine: llmEngine)
                    case 2: MedPointsView()
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Navigation Bar
                if selectedTab != 1 {
                    ZStack {
                        CurvedTabBarShape()
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: -2)
                            .frame(height: 90)
                            
                        HStack {
                            Spacer()
                            Button(action: { selectedTab = 0 }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "house.fill")
                                    Text("Home").font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(selectedTab == 0 ? .blue : .gray)
                            }
                            Spacer()
                            Spacer().frame(width: 70)
                            Spacer()
                            Button(action: { selectedTab = 2 }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "cross.case.fill")
                                    Text("MedPoints").font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(selectedTab == 2 ? .blue : .gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                            
                        Button(action: { selectedTab = 1 }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 70, height: 70)
                                    .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 3)
                                Image(systemName: "message.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(y: -20)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
        }
    }
}

// Custom Shape for Curved Bottom Navigation Bar
struct CurvedTabBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerWidth = rect.width / 2
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY)) // Start at top-left corner
        
        path.addLine(to: CGPoint(x: centerWidth - 50, y: rect.minY)) // Line to start of curve
        
        path.addQuadCurve(
            to: CGPoint(x: centerWidth + 50, y: rect.minY),
            control: CGPoint(x: centerWidth, y: rect.minY - 35) // Adjusted control point for shallower curve dip
        )
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) // Line to top-right corner
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Line to bottom-right corner
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Line to bottom-left corner
        
        path.closeSubpath() // Close the path
        
        return path
    }
}

