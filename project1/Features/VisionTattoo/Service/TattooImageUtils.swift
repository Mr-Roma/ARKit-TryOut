import SwiftUI
import CoreImage
import UIKit

class TattooImageUtils {
    static let shared = TattooImageUtils()
    private init() {}
    
   
    
    func convertCIImageToUIImage(_ ciImage: CIImage) -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func performBlending(bodyImage: UIImage?, tattooImage: UIImage?) -> UIImage? {
        guard let bodyImage = bodyImage,
              let tattooImage = tattooImage,
              let bodyCIImage = CIImage(image: bodyImage),
              let tattooCIImage = CIImage(image: tattooImage) else { return nil }
        
        // First create the mask
        if let mask = TattooBodyBlend.shared.createMask(inputImage: tattooCIImage) {
            // Then blend the images using the mask
            if let blendedResult = TattooBodyBlend.shared.blendImages(
                bodyImage: bodyCIImage,
                tattooImage: tattooCIImage,
                mask: mask
            ) {
                return convertCIImageToUIImage(blendedResult)
            }
        }
        return nil
    }
} 
