import CoreML
import Vision
import UIKit

class TattooAnalysisService {
    static let shared = TattooAnalysisService()
    private init() {}
    
    func analyzeTattoo(image: UIImage, completion: @escaping (Result<TattooAnalysis, Error>) -> Void) {
        guard let model = try? vitatoML() else {
            completion(.failure(NSError(domain: "TattooAnalysis", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load ML model"])))
            return
        }
        
        guard let pixelBuffer = image.toCVPixelBuffer() else {
            completion(.failure(NSError(domain: "TattooAnalysis", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to pixel buffer"])))
            return
        }
        
        do {
            let prediction = try model.prediction(image: pixelBuffer)
            
            // Get the most likely body part and its probability
            let sortedPredictions = prediction.targetProbability.sorted { $0.value > $1.value }
            guard let mostLikelyPrediction = sortedPredictions.first else {
                throw NSError(domain: "TattooAnalysis", code: -3, userInfo: [NSLocalizedDescriptionKey: "No predictions available"])
            }
            
            let analysis = TattooAnalysis(
                bodyPart: mostLikelyPrediction.key,
                confidence: mostLikelyPrediction.value,
                allPredictions: prediction.targetProbability
            )
            completion(.success(analysis))
        } catch {
            completion(.failure(error))
        }
    }
}

struct TattooAnalysis {
    let bodyPart: String
    let confidence: Double
    let allPredictions: [String: Double]
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(size.width),
                                       Int(size.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                              width: Int(size.width),
                              height: Int(size.height),
                              bitsPerComponent: 8,
                              bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(cgImage!, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
} 
