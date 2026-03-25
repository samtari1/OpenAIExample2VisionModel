//
//  ContentView.swift
//  OpenAIExample
//
//  Created by Quanpeng Yang on 3/24/26.
//

import SwiftUI
import PhotosUI
import UIKit

struct ContentView: View {
    @State private var appData = ApplicationData.shared
    @State private var position = ScrollPosition(idType: String.self)
    @State private var inProgress: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: Image?

    var body: some View {
        VStack {
            ScrollView {
                Text(appData.response)
                    .padding()
                    .textSelection(.enabled)
                    .id("textID")
            }
            .frame(minWidth: 350, maxWidth: .infinity, minHeight: 300, alignment: .leading)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scrollPosition($position)

            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            }
            
            HStack {
                TextField("Insert Prompt", text: $appData.prompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(inProgress)

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Image", systemImage: "photo")
                }
                .disabled(inProgress)
                
                Button("Send") {
                    inProgress = true
                    Task {
                        if !appData.prompt.isEmpty || appData.selectedImageData != nil {
                            // Insert prompt in chat box with bold formatting
                            if !appData.prompt.isEmpty {
                                var newPrompt = AttributedString("\(appData.prompt)\n\n")
                                newPrompt.font = .system(size: 16, weight: .bold)
                                appData.response.append(newPrompt)
                            }

                            if appData.selectedImageData != nil {
                                var imageTag = AttributedString("[Image attached]\n\n")
                                imageTag.font = .system(size: 14, weight: .semibold)
                                appData.response.append(imageTag)
                            }
                            
                            // Send prompt to model
                            await appData.sendPrompt()
                            selectedItem = nil
                            selectedImage = nil
                            inProgress = false
                        } else {
                            inProgress = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inProgress || (appData.prompt.isEmpty && appData.selectedImageData == nil))
            }
        }
        .padding()
        .onChange(of: selectedItem) {
            Task {
                guard let selectedItem else {
                    appData.selectedImageData = nil
                    selectedImage = nil
                    return
                }

                if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                    appData.selectedImageData = data
                    if let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                    } else {
                        selectedImage = nil
                    }
                } else {
                    appData.selectedImageData = nil
                    selectedImage = nil
                }
            }
        }
        // Automatically scroll to the bottom when the AI response updates
        .onChange(of: appData.response) {
            position.scrollTo(edge: .bottom)
        }
    }
}
