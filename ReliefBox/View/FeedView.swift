//
//  FeedView.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 31/01/2025.
//
import SwiftUI
import CoreData

struct FeedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFilter: FeedItemType = .all
    @State private var showingAddItem = false
    
    @FetchRequest(
        entity: FeedItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedItem.timestamp, ascending: false)]
    ) private var allItems: FetchedResults<FeedItem>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Buttons
                HStack(spacing: 20) {
                    FilterButton(title: "All",
                               isSelected: selectedFilter == .all) {
                        selectedFilter = .all
                    }
                    FilterButton(title: "Actions",
                               isSelected: selectedFilter == .action) {
                        selectedFilter = .action
                    }
                    FilterButton(title: "Announcements",
                               isSelected: selectedFilter == .announcement) {
                        selectedFilter = .announcement
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Feed List
                List {
                    ForEach(filteredItems) { item in
                        FeedItemView(item: item)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .refreshable { fetchLatestItems() }
            }
            .onAppear {
                requestNotificationPermission()
                insertSampleDataIfNeeded()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Core Data Operations
    private var filteredItems: [FeedItem] {
        switch selectedFilter {
        case .all: return Array(allItems)
        case .action: return allItems.filter { $0.type == "action" }
        case .announcement: return allItems.filter { $0.type == "announcement" }
        }
    }
    
    private func fetchLatestItems() {
        // Replace with real API call later
        let mockData = APIManager.shared.mockAPICall()
        
        do {
            let response = try JSONDecoder().decode(FeedResponse.self, from: mockData)
            APIManager.shared.processItems(response.items, context: viewContext)
        } catch {
            print("Error processing mock data: \(error)")
        }
    }
    
    private func insertSampleDataIfNeeded() {
        guard allItems.isEmpty else { return }
        
        let sampleItems = [
            ("action", "Emergency Alert: Severe weather warning", Date().addingTimeInterval(-3600)),
            ("announcement", "New feature: Location sharing added", Date().addingTimeInterval(-7200)),
            ("action", "System Update: Security patches installed", Date().addingTimeInterval(-10800))
        ]
        
        sampleItems.forEach { type, content, timestamp in
            let newItem = FeedItem(context: viewContext)
            newItem.id = UUID()
            newItem.type = type
            newItem.content = content
            newItem.timestamp = timestamp
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving sample data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Feed Item View
struct FeedItemView: View {
    let item: FeedItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconForType
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content ?? "")
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)
                
                if let timestamp = item.timestamp {
                    Text(timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var iconForType: some View {
        ZStack {
            Circle()
                .fill(item.type == "action" ? Color.red : Color.blue)
                .frame(width: 28, height: 28)
            
            Image(systemName: item.type == "action" ? "exclamationmark.triangle" : "megaphone")
                .resizable()
                .scaledToFit()
                .frame(width: 14)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
}


// MARK: - Data Types
enum FeedItemType: String, CaseIterable {
    case all = "all"
    case action = "action"
    case announcement = "announcement"
}
