//
//  CustomARViewRepresentable.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//

import SwiftUI
import ARKit

struct CustomARViewRepresentable: UIViewRepresentable {
    var onCapture: ((UIImage) -> Void)?
 
    func makeUIView(context: Context) -> CustomARView {
        let arView = CustomARView()
        arView.onCapture = onCapture
        return arView
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) { }
}
