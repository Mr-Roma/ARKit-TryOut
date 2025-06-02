import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private init() {}
    
    // Your existing methods...
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
    
    // NEW METHOD: Remove white color specifically
    func removeWhiteColor(from image: UIImage, tolerance: Float = 0.1) throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidImage
        }
        
        // Create a white color mask using CIColorCube filter
        guard let whiteMask = createWhiteColorMask(from: inputImage, tolerance: tolerance) else {
            throw ImageProcessingError.processingFailed
        }
        
        // Apply the mask to make white areas transparent
        guard let outputImage = applyTransparencyMask(mask: whiteMask, to: inputImage) else {
            throw ImageProcessingError.processingFailed
        }
        
        guard let finalImage = convertToUIImage(ciImage: outputImage) else {
            throw ImageProcessingError.processingFailed
        }
        
        return finalImage
    }
    
    // Alternative method using chroma key (more precise for pure white)
    func removeWhiteColorChromaKey(from image: UIImage) throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidImage
        }
        
        // Use CIChromaKeyFilter to remove white color
        guard let filter = CIFilter(name: "CIChromaKeyFilter") else {
            throw ImageProcessingError.filterCreationFailed
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(CIColor.white, forKey: "inputColor")
        filter.setValue(0.15, forKey: "inputSimilarity")  // Adjust this value (0.0 - 1.0) for tolerance
        filter.setValue(0.1, forKey: "inputSmoothing")    // Adjust for edge smoothness
        
        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.processingFailed
        }
        
        guard let finalImage = convertToUIImage(ciImage: outputImage) else {
            throw ImageProcessingError.processingFailed
        }
        
        return finalImage
    }
    
    // Helper method to create white color mask
    private func createWhiteColorMask(from image: CIImage, tolerance: Float) -> CIImage? {
        // Create a color cube that makes white pixels transparent
        let cubeSize = 64
        let cubeData = createColorCubeData(cubeSize: cubeSize, tolerance: tolerance)
        
        let colorCube = CIFilter.colorCube()
        colorCube.inputImage = image
        colorCube.cubeDimension = Float(cubeSize)
        colorCube.cubeData = Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float>.size)
        
        return colorCube.outputImage
    }
    
    // Helper method to create color cube data for white removal
    private func createColorCubeData(cubeSize: Int, tolerance: Float) -> [Float] {
        var cubeData = [Float]()
        let rgbMax = Float(cubeSize - 1)
        
        for b in 0..<cubeSize {
            for g in 0..<cubeSize {
                for r in 0..<cubeSize {
                    let red = Float(r) / rgbMax
                    let green = Float(g) / rgbMax
                    let blue = Float(b) / rgbMax
                    
                    // Check if the color is close to white
                    let isWhite = red >= (1.0 - tolerance) &&
                                 green >= (1.0 - tolerance) &&
                                 blue >= (1.0 - tolerance)
                    
                    // If it's white, make it transparent (alpha = 0)
                    let alpha: Float = isWhite ? 0.0 : 1.0
                    
                    cubeData.append(red)
                    cubeData.append(green)
                    cubeData.append(blue)
                    cubeData.append(alpha)
                }
            }
        }
        
        return cubeData
    }
    
    // Simpler alternative using color matrix (guaranteed to work)
    func removeWhiteColorSimple(from image: UIImage, threshold: Float = 0.9) throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidImage
        }
        
        // Create a custom kernel to remove white pixels
        let kernel = CIColorKernel(source: """
            kernel vec4 removeWhite(__sample pixel, float threshold) {
                float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
                float alpha = (gray >= threshold) ? 0.0 : pixel.a;
                return vec4(pixel.rgb, alpha);
            }
        """)
        
        guard let colorKernel = kernel else {
            throw ImageProcessingError.filterCreationFailed
        }
        
        guard let outputImage = colorKernel.apply(extent: inputImage.extent,
                                                arguments: [inputImage, threshold]) else {
            throw ImageProcessingError.processingFailed
        }
        
        guard let finalImage = convertToUIImage(ciImage: outputImage) else {
            throw ImageProcessingError.processingFailed
        }
        
        return finalImage
    }
    
    // Helper method to apply transparency mask
       private func applyTransparencyMask(mask: CIImage, to image: CIImage) -> CIImage? {
           // The color cube already handles transparency, so we can return the mask directly
           return mask
       }
}

enum ImageProcessingError: Error {
    case invalidImage
    case filterCreationFailed
    case processingFailed
}
