//
//  OCRProcessor.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import UIKit
import CoreGraphics
import Vision

final class OCRVisionProcessor: OCRProcessing {
    
    func process(_ image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRProcessorError.unknown
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation, options: [:])
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedStrings: Array<String> = observations.compactMap({ result in
                    result.topCandidates(1).first?.string
                })
                continuation.resume(returning: recognizedStrings)
            }
            request.revision = VNRecognizeTextRequestRevision3
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ko-KR", "en-US", "ja-JP"]
            request.usesLanguageCorrection = true
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

}
