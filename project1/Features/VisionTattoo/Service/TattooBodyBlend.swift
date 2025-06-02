//
//  TattooBodyBlend.swift
//  project1
//
//  Created by Melki Jonathan Andara on 02/06/25.
//
import CoreML
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class TattooBodyBlend {
    static let shared = TattooBodyBlend()
    private init() {}
    
    func createMask(inputImage: CIImage) -> CIImage? {
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
    
    func blendImages(bodyImage: CIImage, tattooImage: CIImage, mask: CIImage) -> CIImage? {
        let context = CIContext()
        let filter = CIFilter.blendWithBlueMask()
        
        filter.inputImage = tattooImage
        filter.backgroundImage = bodyImage
        filter.maskImage = mask
        
        guard let outputImage = filter.outputImage else { return nil }
        return outputImage
    }
}
