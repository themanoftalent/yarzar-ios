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

final class CameraBarcodeScanner: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isRunning = false
    @Published var lastDetectedBarcode: String?
    @Published var statusText: String = ""

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "yarzar.ios.camera.barcode")
    private var lastScanTime: Date = .distantPast

    func start() {
        guard !isRunning else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureAndStart()
                    } else {
                        self?.statusText = L("Camera permission was not granted.")
                    }
                }
            }
        default:
            statusText = L("Camera access is disabled in System Settings.")
        }
    }

    func stop() {
        guard isRunning else { return }
        queue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }

    private func configureAndStart() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                    ?? AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.statusText = L("No camera device available.")
                }
                return
            }
            self.session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.queue)
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
            }
            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.isRunning = true
                self.statusText = L("Hold an EAN-13 / UPC barcode in front of the camera…")
            }
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard Date().timeIntervalSince(lastScanTime) > 0.6,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastScanTime = Date()

        let req = VNDetectBarcodesRequest { [weak self] request, _ in
            guard let results = request.results as? [VNBarcodeObservation],
                  let payload = results.compactMap({ $0.payloadStringValue }).first else { return }
            DispatchQueue.main.async {
                self?.lastDetectedBarcode = payload
                self?.stop()
            }
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([req])
    }
}
