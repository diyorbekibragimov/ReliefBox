//
//  OpenAIManager.swift
//  ReliefBox
//

import Foundation

class OpenAIManager: ObservableObject {
    static let shared = OpenAIManager()
    private let apiKey = "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"
    private let assistantId = "asst_6DVcukrsRlqpjLIQNzM9R0g1"
    private let baseURL = "https://api.openai.com/v1"
    
    private var threadId: String?
    private var session: URLSession?
    private var task: URLSessionDataTask?
    
    enum OpenAIError: LocalizedError {
        case noThreadId
        case invalidResponse
        case parsingError
        case networkError(Error)
        case apiError(code: Int, message: String)
        case threadCreationFailed
        case messageSubmissionFailed
        case runExecutionFailed
        
        var errorDescription: String? {
            switch self {
            case .noThreadId:
                return "No active conversation thread. Please create a thread first."
            case .invalidResponse:
                return "Received invalid response from server."
            case .parsingError:
                return "Failed to parse server response."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .apiError(let code, let message):
                return "API Error \(code): \(message)"
            case .threadCreationFailed:
                return "Failed to create new conversation thread."
            case .messageSubmissionFailed:
                return "Failed to submit message."
            case .runExecutionFailed:
                return "Failed to execute conversation."
            }
        }
    }
    
    // MARK: - Thread Management
    func createThread(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/threads") else {
            completion(.failure(OpenAIError.threadCreationFailed))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add required beta header
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        // Add empty JSON body as required by API
        request.httpBody = "{}".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(OpenAIError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                completion(.failure(OpenAIError.apiError(
                    code: httpResponse.statusCode,
                    message: "Thread creation failed: \(statusMessage)"
                )))
                return
            }
            
            guard let data = data else {
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            do {
                // Parse using proper JSONDecoder for consistency
                struct ThreadResponse: Decodable {
                    let id: String
                }
                
                let response = try JSONDecoder().decode(ThreadResponse.self, from: data)
                self.threadId = response.id
                completion(.success(response.id))
            } catch {
                completion(.failure(OpenAIError.parsingError))
            }
        }.resume()
    }

    
    // MARK: - Message Handling
    func addMessage(_ text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let threadId = threadId else {
            completion(.failure(OpenAIError.noThreadId))
            return
        }
        
        let url = URL(string: "\(baseURL)/threads/\(threadId)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        // Simplified request body structure according to API docs
        struct MessageRequest: Encodable {
            let role: String
            let content: String  // Direct string instead of array
        }
        
        let requestBody = MessageRequest(
            role: "user",
            content: text
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(requestBody)
            
            // For debugging, print the JSON being sent
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("Request JSON: \(jsonString)")
            }
        } catch {
            completion(.failure(OpenAIError.parsingError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(OpenAIError.networkError(error)))
                return
            }
            
            // Debugging: Print raw response
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage: String
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorInfo = json["error"] as? [String: Any] {
                    errorMessage = errorInfo["message"] as? String ?? "Unknown error"
                } else {
                    errorMessage = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                }
                
                completion(.failure(OpenAIError.apiError(
                    code: httpResponse.statusCode,
                    message: "Message submission failed: \(errorMessage)"
                )))
                return
            }
            
            completion(.success(()))
        }.resume()
    }
    
    func runThread(completion: @escaping (Result<String, Error>) -> Void) {
        guard let threadId = threadId else {
            completion(.failure(OpenAIError.noThreadId))
            return
        }
        
        let url = URL(string: "\(baseURL)/threads/\(threadId)/runs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta") // Add this header
        
        // Verify assistantId is correct
        let body: [String: Any] = [
            "assistant_id": "\(assistantId)", 
            "stream": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {

            completion(.failure(OpenAIError.parsingError))
            return
        }
        
        let sessionDelegate = StreamDelegate(completion: completion)
        let session = URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: nil)
        self.session = session
        
        task = session.dataTask(with: request)
        task?.resume()
    }
    
    func cancelRequest() {
        task?.cancel()
        session?.invalidateAndCancel()
    }
}

// MARK: - Stream Handling
private class StreamDelegate: NSObject, URLSessionDataDelegate {
    private var buffer = Data()
    private let completion: (Result<String, Error>) -> Void
    private let jsonDecoder = JSONDecoder()
    
    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        processBuffer()
    }
    
    private func processBuffer() {
        let delimiter = "data: ".data(using: .utf8)!
        
        while let range = buffer.range(of: delimiter) {
            let chunk = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            
            if !chunk.isEmpty {
                processChunk(chunk)
            }
        }
    }
    
    private func processChunk(_ chunk: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: chunk, options: []) as? [String: Any]
            guard let event = jsonObject?["event"] as? String,
                  event == "thread.message.delta",
                  let dataDict = jsonObject?["data"] as? [String: Any],
                  let delta = dataDict["delta"] as? [String: Any],
                  let content = delta["content"] as? [[String: Any]],
                  let textContent = content.first(where: { $0["type"] as? String == "text" }),
                  let text = textContent["text"] as? [String: Any],
                  let value = text["value"] as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.completion(.success(value))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion(.failure(error))
        }
    }
}
