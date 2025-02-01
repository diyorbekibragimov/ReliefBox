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
    private let baseURL = URL(string: "https://reliefbox.hasanbek.me/feed")!
    private let userDefaultsKey = "lastFeedVersion"
    
    private var lastVersion: Int64 {
        get { Int64(UserDefaults.standard.integer(forKey: userDefaultsKey)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: userDefaultsKey) }
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

    func fetchFeedUpdates(context: NSManagedObjectContext) {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "version_id", value: "\(lastVersion)")]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                return
            }
            
            switch httpResponse.statusCode {
            case 204:
                break // No content
                
            case 200:
                guard let data = data else {
                    print("Received empty response for 200 status")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(APIResponse.self, from: data)
                    self.processUpdates(response, context: context)
                } catch {
                    print("Decoding error: \(error)")
                }
                
            default:
                print("Unexpected status code: \(httpResponse.statusCode)")
            }
        }.resume()
    }

    private func processUpdates(_ response: APIResponse, context: NSManagedObjectContext) {
        context.performAndWait {
            let existingIDs = getExistingItemIDs(context: context)
            var maxVersionID = lastVersion // Start with current version
                    
            for update in response.updates {
                guard !existingIDs.contains(Int32(update.id)) else { continue }
                
                let newItem = FeedItem(context: context)
                newItem.id = Int32(update.id)
                newItem.type = update.type
                newItem.content = update.content
                newItem.timestamp = Date(timeIntervalSince1970: TimeInterval(update.created_at))
                
                showNotification(title: "New Update", body: update.content)
                
                // Track the highest version_id from updates
                maxVersionID = max(maxVersionID, Int64(update.version_id))
            }
            
            lastVersion = maxVersionID
    
            saveContext(context: context)
        }
    }

    private func getExistingItemIDs(context: NSManagedObjectContext) -> Set<Int32> {
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest()
        fetchRequest.propertiesToFetch = ["id"]
        
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
            print("Save error: \(error)")
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
}

// MARK: - API Response Models
struct APIResponse: Codable {
    let current_server_time: Int64
    let updates: [APIUpdate]
}

struct APIUpdate: Codable {
    let id: Int
    let content: String
    let type: String
    let version_id: Int64
    let created_at: Int64
}
