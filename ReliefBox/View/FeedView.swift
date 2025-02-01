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
    @State private var selectedItem: FeedItem?
    
    @FetchRequest(
        entity: FeedItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FeedItem.timestamp, ascending: false)]
    ) private var allItems: FetchedResults<FeedItem>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Buttons
                HStack(spacing: 20) {
                    FilterButton(title: "All", isSelected: selectedFilter == .all) {
                        selectedFilter = .all
                    }
                    FilterButton(title: "Actions", isSelected: selectedFilter == .action) {
                        selectedFilter = .action
                    }
                    FilterButton(title: "Announcements", isSelected: selectedFilter == .announcement) {
                        selectedFilter = .announcement
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Feed List with Swipe-to-Delete
                List {
                    ForEach(filteredItems) { item in
                        FeedItemView(item: item) {
                            selectedItem = item
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
                .refreshable { fetchLatestItems() }
            }
            .sheet(item: $selectedItem) { item in
                DetailView(item: item)
            }
            .onAppear {
                requestNotificationPermission()
            }
        }
    }
    
    // MARK: - Deletion Logic
    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredItems[$0] }
        let deletedIDs = itemsToDelete.map { Int($0.id) }
        
        itemsToDelete.forEach { viewContext.delete($0) }
        
        do {
            try viewContext.save()
            updateDeletedIDs(with: deletedIDs)
        } catch {
            print("Deletion error: \(error.localizedDescription)")
        }
    }
    
    private func updateDeletedIDs(with newIDs: [Int]) {
        var currentIDs = UserDefaults.standard.array(forKey: "deletedItemIDs") as? [Int] ?? []
        currentIDs.append(contentsOf: newIDs)
        UserDefaults.standard.set(currentIDs, forKey: "deletedItemIDs")
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
        APIManager.shared.fetchFeedUpdates(context: viewContext)
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
}

// MARK: - Feed Item View (unchanged)
struct FeedItemView: View {
    let item: FeedItem
    var onTap: () -> Void
    
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
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private var iconForType: some View {
        ZStack {
            Circle()
                .fill(item.type == "action" ? Color.blue : Color.red)
                .frame(width: 28, height: 28)
            
            Image(systemName: item.type == "action" ? "bolt" : "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 14)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Detail View (unchanged)
struct DetailView: View {
    let item: FeedItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        iconForType
                        Text(item.type ?? "")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    
                    Text(item.content ?? "")
                        .font(.body)
                    
                    if let timestamp = item.timestamp {
                        Text("Posted \(timestamp.formatted(.dateTime.day().month().year().hour().minute()))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var iconForType: some View {
        ZStack {
            Circle()
                .fill(item.type == "action" ? Color.blue : Color.red)
                .frame(width: 28, height: 28)
            
            Image(systemName: item.type == "action" ? "bolt" : "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 14)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Filter Button Component (unchanged)
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

// MARK: - Data Types (unchanged)
enum FeedItemType: String, CaseIterable {
    case all = "all"
    case action = "action"
    case announcement = "announcement"
}
