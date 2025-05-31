//
//  InputImageView.swift
//  project1
//
//  Created by Melki Jonathan Andara on 31/05/25.
//
import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins


struct InputImageView: View {
    @State private var image = UIImage(named: "tattoo1")!
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            
            Button("Remove background") {
                removeBackground()
            }
        }
        .padding()
    }
    
    private func createMask(from inputImage: CIImage) -> CIImage? {
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)
        
        do {
            try handler.perform([request])
            
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        
        return filter.outputImage!
    }
    
    private func convertToUIImage(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func removeBackground() {
        guard let inputImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return
        }
        
        Task {
            guard let maskImage = createMask(from: inputImage) else {
                print("Failed to create mask")
                return
            }
            
            let outputImage = applyMask(mask: maskImage, to: inputImage)
            let finalImage = convertToUIImage(ciImage: outputImage)
            
            image = finalImage
        }
    }
}





#Preview {
    InputImageView()
}
