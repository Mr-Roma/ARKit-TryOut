//
//  ARManager.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//

import Combine
import SwiftUI
import UIKit // Import UIKit for UIImage

class ARManager: ObservableObject { // Make it ObservableObject
    static let shared = ARManager()
    private init() { }
    
    var actionStream = PassthroughSubject<ARAction, Never>()
    
    @Published var customTattooImages: [UIImage] = [] // Published property for custom images
    @Published var selectedTattooImage: UIImage? = nil // Published property for selected image
    
    // Method to add a custom image
    func addCustomImage(_ image: UIImage) {
        customTattooImages.append(image)
    }
    
    // Method to select a custom image by index (optional, can also set selectedTattooImage directly)
    func selectCustomImage(at index: Int) {
        if index < customTattooImages.count {
            selectedTattooImage = customTattooImages[index]
        } else {
            selectedTattooImage = nil // Or handle out of bounds as needed
        }
    }
    
    // Method to select a default image by name
    func selectDefaultImage(name: String) {
         if let image = UIImage(named: name) {
             selectedTattooImage = image
         } else {
             selectedTattooImage = nil // Handle case where named image doesn't exist
         }
    }
}

