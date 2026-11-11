import AVFoundation
import Combine
import Foundation
import UIKit
import Vision

struct VisionScanResult {
    let detectedBarcode: String?
    let recognizedText: String
}

enum VisionScannerService {
    static func analyzeImage(_ uiImage: UIImage) async -> VisionScanResult {
        guard let cgImage = uiImage.cgImage else {
            return VisionScanResult(detectedBarcode: nil, recognizedText: "")
        }

        return await withCheckedContinuation { continuation in
            var foundBarcode: String?
            var foundLines: [String] = []

            let barcodeReq = VNDetectBarcodesRequest { req, _ in
                if let results = req.results as? [VNBarcodeObservation] {
                    foundBarcode = results.compactMap { $0.payloadStringValue }.first
                }
            }

            let textReq = VNRecognizeTextRequest { req, _ in
                if let results = req.results as? [VNRecognizedTextObservation] {
                    foundLines = results.compactMap { $0.topCandidates(1).first?.string }
                }
            }
            textReq.recognitionLevel = .accurate
            textReq.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([barcodeReq, textReq])

            continuation.resume(
                returning: VisionScanResult(
                    detectedBarcode: foundBarcode,
                    recognizedText: foundLines.joined(separator: ", ")
                )
            )
        }
    }
}
