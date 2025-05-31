import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private init() {}
    
    private func createMask(from inputImage: CIImage) async -> CIImage? {
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)
        
        do {
            try handler.perform([request])
            
            if let result = request.results?.first {
                let mask = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
                return CIImage(cvPixelBuffer: mask)
            }
        } catch {
            print("Error creating mask: \(error)")
        }
        
        return nil
    }
    
    private func applyMask(mask: CIImage, to image: CIImage) -> CIImage? {
        let filter = CIFilter.blendWithMask()
        
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        
        return filter.outputImage
    }
    
    private func convertToUIImage(ciImage: CIImage) -> UIImage? {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to render CGImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func removeBackground(from image: UIImage) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidImage
        }
        
        guard let maskImage = await createMask(from: inputImage) else {
             throw ImageProcessingError.processingFailed
        }
        
        guard let outputImage = applyMask(mask: maskImage, to: inputImage) else {
             throw ImageProcessingError.processingFailed
        }
        
        guard let finalImage = convertToUIImage(ciImage: outputImage) else {
             throw ImageProcessingError.processingFailed
        }
        
        return finalImage
    }
    
    
    
    
}

enum ImageProcessingError: Error {
    case invalidImage
    case filterCreationFailed
    case processingFailed
} 
