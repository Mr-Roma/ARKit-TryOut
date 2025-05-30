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
    ]
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showPermissionAlert = false
    
    // Define grid columns for LazyVGrid
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack{
            VStack{
                Text("Welcome to Vitato")
                
                NavigationLink(destination: ARTattooView()){
                    Text("Using AR")
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                NavigationLink(destination: ARTattooView() ){
                    Text("Using Image")
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
                HStack{
                    Text("Tattoo gallery")
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Input image")
                            .foregroundColor(.blue)
                    }
                   
                }
               
                
                ScrollView{
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(tattooImages, id: \.self) { tattooImage in
                            Image(tattooImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .border(Color.gray)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
    
 
    
   
}

#Preview {
    HomeView()
}
