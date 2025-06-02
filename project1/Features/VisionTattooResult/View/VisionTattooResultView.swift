//
//  VisionTattooResultView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 02/06/25.
//

import SwiftUI

struct VisionTattooResultView: View {
    let resultImage: UIImage
    
    var body: some View {
        VStack {
            Image(uiImage: resultImage)
                .resizable()
                .scaledToFit()
                .padding()
            
            Button(action: {
                // Save image to photo library
                UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil)
            }) {
                Text("Save to Photos")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Blended Result")
    }
}

#Preview {
    VisionTattooResultView(resultImage: UIImage(systemName: "photo")!)
}


