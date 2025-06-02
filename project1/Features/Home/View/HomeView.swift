//
//  HomeView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//

import SwiftUI
import PhotosUI
import UIKit
import Photos

struct HomeView: View {
    
    @State private var tattooImages: [String] = [
        "tattoo1",
        "tattoo2",
        "tattoo3",
        "tattoo4",
        "tattoo5",
    ]
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showPermissionAlert = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Access the shared ARManager
    @ObservedObject var arManager = ARManager.shared
    
    // Define grid columns for LazyVGrid
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack{
            VStack{
                Text("Welcome to Vitato")
                    .font(.title)
                    .padding(.top)
                
                NavigationLink(destination: ARTattooView()){
                    Text("Using AR")
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                NavigationLink(destination: VisionTattooView() ){
                    Text("Using Image")
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
                HStack{
                    Text("Tattoo gallery")
                        .font(.headline)
                    
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Input image")
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            isProcessing = true
                            errorMessage = ""
                            showError = false
                            do {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    
                                    // Process the image to remove white background
                                    let processedImage = try ImageProcessingService.shared.removeWhiteColorSimple(from: image)
                                    
                                    await MainActor.run {
                                        arManager.addCustomImage(processedImage)
                                        isProcessing = false
                                    }
                                } else {
                                    await MainActor.run {
                                        errorMessage = "Failed to load image."
                                        showError = true
                                        isProcessing = false
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    errorMessage = "Image processing failed: \(error.localizedDescription)"
                                    showError = true
                                    isProcessing = false
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                if isProcessing {
                    ProgressView("Processing image...")
                        .padding()
                }
                
                ScrollView{
                    LazyVGrid(columns: columns, spacing: 20) {
                        // Display default tattoo images
                        ForEach(tattooImages, id: \.self) { tattooImage in
                            Image(tattooImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .border(Color.gray)
                                .onTapGesture {
                                    arManager.selectDefaultImage(name: tattooImage)
                                }
                        }
                        
                        // Display custom uploaded images from ARManager
                        ForEach(0..<arManager.customTattooImages.count, id: \.self) { index in
                            Image(uiImage: arManager.customTattooImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .border(Color.gray)
                                .onTapGesture {
                                    arManager.selectCustomImage(at: index)
                                }
                        }
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 12)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    HomeView()
}
