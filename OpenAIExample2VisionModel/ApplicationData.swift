//
//  ApplicationData.swift
//  OpenAIExample
//
//  Created by Quanpeng Yang on 3/24/26.
//

import SwiftUI
import Observation

@Observable
class ApplicationData {
    var response: AttributedString = ""
    var prompt: String = ""
    var selectedImageData: Data?
    
    static let shared: ApplicationData = ApplicationData()
    
    private init() { }
    
    func sendPrompt() async {
        guard !prompt.isEmpty || selectedImageData != nil else { return }
        
        // Prepare multimodal user content (text + optional image)
        var userContent: [[String: String]] = []
        if !prompt.isEmpty {
            userContent.append([
                "type": "input_text",
                "text": prompt
            ])
        }
        
        if let selectedImageData {
            let base64Image = selectedImageData.base64EncodedString()
            userContent.append([
                "type": "input_image",
                "image_url": "data:image/jpeg;base64,\(base64Image)"
            ])
        }
        
        let input: [[String: Any]] = [
            [
                "role": "system",
                "content": [
                    [
                        "type": "input_text",
                        "text": "You are a friendly AI that likes to chat with the user. If an image is provided, describe and reason about it."
                    ]
                ]
            ],
            [
                "role": "user",
                "content": userContent
            ]
        ]
        
        let jsonbody: [String: Any] = [
            "model": "gpt-4.1-mini",
            "input": input,
            "store": false,
            "max_output_tokens": 2000
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonbody) else { return }
        
        // Prepare URL request
        let apikey = "Your_API_KEY" // You should replace it with your OpenAI API Key
        guard let url = URL(string: "https://api.openai.com/v1/responses") else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData
        urlRequest.addValue("Bearer \(apikey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send request and process response
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = urlResponse as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let chatresponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                    
                    // MainActor ensures UI updates happen on the main thread
                    await MainActor.run {
                        for item in chatresponse.output {
                            if item.type == "message", let contentParts = item.content {
                                for part in contentParts {
                                    if part.type == "output_text", let answer = part.text {
                                        var newResponse = AttributedString("\(answer)\n\n")
                                        newResponse.font = .system(size: 16, weight: .regular)
                                        response.append(newResponse)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    let errorText = String(data: data, encoding: .utf8) ?? "No additional information."
                    await MainActor.run {
                        response = AttributedString("Error \(httpResponse.statusCode): \(errorText)")
                    }
                }
            }
        } catch {
            await MainActor.run {
                response = AttributedString("Error accessing the API: \(error)")
            }
        }
        
        await MainActor.run {
            prompt = ""
            selectedImageData = nil
        }
    }
}
