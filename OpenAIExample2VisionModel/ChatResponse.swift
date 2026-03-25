//
//  ChatResponse.swift
//  OpenAIExample
//
//  Created by Quanpeng Yang on 3/24/26.
//

import SwiftUI

struct ChatResponse: Codable {
    let output: [OutputItem]

    struct OutputItem: Codable {
        let id: String
        let type: String
        let status: String?
        let content: [ContentPart]?
        let role: String?

        struct ContentPart: Codable {
            let type: String
            let text: String?
        }
    }
}
