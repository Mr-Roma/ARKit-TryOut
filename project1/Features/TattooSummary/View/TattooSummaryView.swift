//
//  TattooSummaryView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//

import SwiftUI
import UIKit
import Photos

struct TattooSummaryView: View {
    let image: UIImage
    @State private var analysis: TattooAnalysis?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    
    @State private var isShowingSheet = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                
                // Analysis Results
                if isLoading {
                    ProgressView("Analyzing tattoo...")
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if let analysis = analysis {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Analysis Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Most likely prediction
                        HStack(alignment: .top) {
                            Text("Most Likely Body Part:")
                                .fontWeight(.medium)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(analysis.bodyPart)
                                    .font(.title3)
                                Text("Confidence: \(String(format: "%.1f%%", analysis.confidence * 100))")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom,40)
                        
                        // Pain Level Information
                        if let painLevel = PainLevelModel.painLevels[analysis.bodyPart.lowercased()] {
                            VStack(alignment: .leading, spacing: 8) {
                                
                                HStack{
                                    Text("Pain Level")
                                        .font(.headline)
                                    Spacer()
                                    Button(action: {
                                        isShowingSheet.toggle()
                                    }){
                                        Text("See detail")
                                    }
                                    .sheet(isPresented: $isShowingSheet) {
                                                VStack {
                                                    Text("Pain level")
                                                        .font(.title)
                                                        .padding(50)
                                                    Image("maleBody").resizable()
                                                        .scaledToFit().frame(width: 400, height: 400)
                                                    Button("Dismiss",
                                                           action: { isShowingSheet.toggle() })
                                                }
                                            }
                                }
                           
                                
                                
                                Text(painLevel.description)
                                    .font(.title3)
                               
                                Text(painLevel.details)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: saveToGallery) {
                        Label("Save to Gallery", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    
                }
            }
            .padding()
        }
        .navigationTitle("Tattoo Summary")
        .onAppear {
            analyzeTattoo()
        }
        .alert("Save to Gallery", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private func analyzeTattoo() {
        isLoading = true
        errorMessage = nil
        
        TattooAnalysisService.shared.analyzeTattoo(image: image) { result in
            isLoading = false
            
            switch result {
            case .success(let analysis):
                self.analysis = analysis
            case .failure(let error):
                self.errorMessage = "Analysis failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveToGallery() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    saveAlertMessage = "Image saved successfully to your photo library!"
                    showSaveAlert = true
                } else {
                    saveAlertMessage = "Please allow access to your photo library in Settings to save the image."
                    showSaveAlert = true
                }
            }
        }
    }
}

#Preview {
    TattooSummaryView(image: UIImage(systemName: "photo")!)
}

