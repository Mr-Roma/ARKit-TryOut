//
//  ShowingTattooView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 02/06/25.
//

import SwiftUI

struct ShowingTattooView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var arManager = ARManager.shared
    @Binding var activeMode: EditMode?
    @State private var tattooImages: [String] = [
        "tattoo1",
        "tattoo2",
        "tattoo3",
        "tattoo4",
        "tattoo5",
    ]
    // Define grid columns for LazyVGrid
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
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
                            activeMode = .move
                            dismiss()
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
                            activeMode = .move
                            dismiss()
                        }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ShowingTattooView(activeMode: .constant(nil))
}
