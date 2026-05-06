@preconcurrency import AVFoundation
import Combine

@MainActor
final class CameraSession: ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isRunning = false
    @Published private(set) var permissionState: AVAuthorizationStatus

    init() {
        permissionState = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermissionAndStart() async {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        if current == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionState = granted ? .authorized : .denied
        } else {
            permissionState = current
        }

        guard permissionState == .authorized else { return }
        configureAndStart()
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
        isRunning = false
    }

    private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .high

        if session.inputs.isEmpty,
           let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        if session.outputs.isEmpty {
            let output = AVCaptureVideoDataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        }

        session.commitConfiguration()
        session.startRunning()
        isRunning = true
    }
}
