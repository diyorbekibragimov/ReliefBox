//
//  APIManager.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 01/02/2025.
//

import Foundation
import CoreData
import UserNotifications

class APIManager {
    static let shared = APIManager()
    private var timer: Timer?
    private let apiURL = URL(string: "https://reliefbox.hasanbek.me/feed")!
    private let userDefaultsKey = "lastFeedVersion"
        
    private var lastVersion: Int64 {
        get {
            Int64(UserDefaults.standard.integer(forKey: userDefaultsKey))
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: userDefaultsKey)
        }
    }
    
    func startPolling(context: NSManagedObjectContext) {
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchFeedUpdates(context: context)
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchFeedUpdates(context: NSManagedObjectContext) {
        var request = URLRequest(url: apiURL)
        request.addValue("\(lastVersion)", forHTTPHeaderField: "X-Version")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(FeedResponse.self, from: data)
                
                if response.version > self.lastVersion {
                    self.lastVersion = response.version
                    self.processItems(response.items, context: context)
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
    
    func processItems(_ items: [FeedItemData], context: NSManagedObjectContext) {
        context.performAndWait {
            let existingIDs = getExistingItemIDs(context: context)
            var hasNewItems = false
            
            for itemData in items {
                guard let itemUUID = UUID(uuidString: itemData.id) else {
                    print("Invalid UUID format: \(itemData.id)")
                    continue
                }
                
                guard !existingIDs.contains(itemUUID) else { continue }
                
                let newItem = FeedItem(context: context)
                newItem.id = itemUUID
                newItem.type = itemData.type
                newItem.content = itemData.content
                newItem.timestamp = Date()
                
                showNotification(title: "New Update", body: itemData.content)
                hasNewItems = true
            }
            
            if hasNewItems {
                // Only update version if we actually got new items
                lastVersion += 1
            }
            
            saveContext(context: context)
        }
    }
    
    private func getExistingItemIDs(context: NSManagedObjectContext) -> Set<UUID> {
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest()
        fetchRequest.resultType = .managedObjectIDResultType
        
        do {
            let results = try context.fetch(fetchRequest)
            return Set(results.compactMap { $0.id })
        } catch {
            print("Error fetching existing IDs: \(error)")
            return []
        }
    }
    
    private func saveContext(context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
            context.rollback()
        }
    }
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func mockAPICall() -> Data {
       let mockResponse = FeedResponse(
           version: lastVersion + 1,
           items: [
               FeedItemData(
                   id: UUID().uuidString,
                   type: "action",
                   content: "New mock alert - Pull to refresh worked!"
               )
           ]
       )
       return try! JSONEncoder().encode(mockResponse)
   }
}

struct FeedResponse: Codable {
    let version: Int64
    let items: [FeedItemData]
}

struct FeedItemData: Codable {
    let id: String
    let type: String
    let content: String
}

