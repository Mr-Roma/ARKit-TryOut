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
    @State private var colors: [Color] = [
        .green,
        .red,
        .blue
    ]
    
    @State private var tattooImages: [String] = [
        "tattoo1",
        "tattoo2",
        "tattoo3",
        "tattoo4",
        
    ]
    
    @State private var selectedImageIndex: Int = 0
    
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
                                    
                                    
                                    ForEach(Array(tattooImages.enumerated()), id: \.element) { index, tattoo in
                                        Button {
                                            selectedImageIndex = index
                                            ARManager.shared.actionStream.send(.placeTattoo(imageName: tattoo))
                                        } label: {
                                            Image(tattoo)
                                                .resizable()
                                                .scaledToFit()
                                                .cornerRadius(4)
                                                .frame(width: 120, height: 120)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(selectedImageIndex == index ? Color.blue : Color.clear, lineWidth: 3)
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
                                
                                NavigationLink(destination: TattooSummaryView(image: capturedImage ?? UIImage())){
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
