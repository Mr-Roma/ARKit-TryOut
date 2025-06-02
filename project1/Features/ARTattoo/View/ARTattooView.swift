//
//  ARTattooView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//

import SwiftUI
import UIKit
import ARKit


struct ARTattooView: View {
    
    @ObservedObject var arManager = ARManager.shared // Observe ARManager
    
    @State private var tattooImages: [String] = [
        "tattoo1",
        "tattoo2",
        "tattoo3",
        "tattoo4",
        "tattoo5",
        
    ]
    
    @State private var isCameraButtonClicked: Bool = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        CustomARViewRepresentable(onCapture: { image in
            capturedImage = image
            isCameraButtonClicked.toggle()
        })
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                
                VStack(spacing: 16) {
                    
                    if(!isCameraButtonClicked){
                        VStack(alignment: .leading){
                            Button {
                                ARManager.shared.actionStream.send(.removeAllAnchors)
                            } label: {
                                Image(systemName: "trash")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .padding(8)
                                    .background(.regularMaterial)
                                    .cornerRadius(12)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    
                                    // Display default tattoo images
                                    ForEach(Array(tattooImages.enumerated()), id: \.element) { index, tattooName in
                                        Button {
                                            // Select the default image in ARManager
                                            arManager.selectDefaultImage(name: tattooName)
                                            // Send action to place the currently selected image
                                            ARManager.shared.actionStream.send(.placeTattoo)
                                        } label: {
                                            Image(tattooName)
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(4)
                                                .frame(width: 120, height: 120)
                                                .overlay(
                                                    // Highlight the selected image
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(arManager.selectedTattooImage == UIImage(named: tattooName) ? Color.blue : Color.clear, lineWidth: 3)
                                                )
                                        }
                                    }
                                    
                                    // Display custom uploaded images
                                    ForEach(0..<arManager.customTattooImages.count, id: \.self) { index in
                                        let customImage = arManager.customTattooImages[index]
                                        Button {
                                            // Select the custom image in ARManager
                                            arManager.selectCustomImage(at: index)
                                            // Send action to place the currently selected image
                                            ARManager.shared.actionStream.send(.placeTattoo)
                                        } label: {
                                            Image(uiImage: customImage)
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(4)
                                                .frame(width: 120, height: 120)
                                                .overlay(
                                                    // Highlight the selected image
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(arManager.selectedTattooImage == customImage ? Color.blue : Color.clear, lineWidth: 3)
                                                )
                                        }
                                    }
                            }
                                
                            }
                        } .padding(.horizontal, 16)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                ARManager.shared.actionStream.send(.captureScreenshot)
                            }){
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 30))
                                    )
                            }
                            Spacer()
                        }
                    }
                    
                    else{
                        VStack(spacing: 20) {
                            if let capturedImage = capturedImage {
                                Image(uiImage: capturedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 400)
                                    .cornerRadius(16)
                                    .shadow(radius: 5)
                                    .padding(.horizontal)
                            }
                            
                            HStack(spacing: 30) {
                                Button(action: {
                                    isCameraButtonClicked.toggle()
                                }){
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Retake")
                                    }
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.gray.opacity(0.8))
                                    .cornerRadius(12)
                                }
                                
                                Spacer()
                                
                                // Ensure capturedImage is not nil before navigating
                                if let capturedImage = capturedImage {
                                    NavigationLink(destination: TattooSummaryView(image: capturedImage)){
                                       Text("Done")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(Color.blue)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
    }
}


#Preview {
    ARTattooView()
}
