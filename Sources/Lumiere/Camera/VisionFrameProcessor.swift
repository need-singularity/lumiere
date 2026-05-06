@preconcurrency import Vision
@preconcurrency import CoreML
import CoreVideo
import Foundation

/// Generic Core ML inference wrapper for image-input models. Wraps any
/// `MLModel` via Vision's `VNCoreMLRequest` for automatic crop+scale
/// preprocessing to the model's input shape.
///
/// In mk1 the pixel buffer passes through unchanged — observations are
/// recorded for downstream logic (filter selection, segmentation mask,
/// identity embedding). Output-substitution (rendering the model's
/// processed image back into the buffer) arrives at:
///   • camera.cond.2 — real-time filter inference (Stage A → B → C path)
///   • parallel_self.cond.2 — Mirror SD v3 + InstantID + LoRA pipeline
///
/// `VNCoreMLRequest` is not thread-safe across calls, so a fresh
/// request is constructed per frame; only the immutable `VNCoreMLModel`
/// is reused.
final class VisionFrameProcessor: FrameProcessor, @unchecked Sendable {
    private let visionModel: VNCoreMLModel
    private let cropAndScale: VNImageCropAndScaleOption
    private var lastObservations: [VNObservation] = []
    private let observationLock = NSLock()

    init(model: MLModel, cropAndScale: VNImageCropAndScaleOption = .centerCrop) throws {
        self.visionModel = try VNCoreMLModel(for: model)
        self.cropAndScale = cropAndScale
    }

    func process(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = cropAndScale

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            if let results = request.results {
                observationLock.lock()
                lastObservations = results
                observationLock.unlock()
            }
        } catch {
            // Single-frame inference failure should not kill the pipeline —
            // FrameTimingRecorder still observes a sample, which is honest
            // accounting for F-CFA-MVP-1 latency p95 measurements.
        }
        return pixelBuffer
    }

    var observations: [VNObservation] {
        observationLock.lock()
        defer { observationLock.unlock() }
        return lastObservations
    }
}
