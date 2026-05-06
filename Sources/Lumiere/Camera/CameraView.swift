import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var session = CameraSession()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch session.permissionState {
            case .authorized:
                CameraPreviewView(session: session.session)
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) { hud }
            case .denied, .restricted:
                permissionDenied
            case .notDetermined:
                ProgressView().tint(.white)
            @unknown default:
                ProgressView().tint(.white)
            }
        }
        .task { await session.requestPermissionAndStart() }
        .onDisappear { session.stop() }
    }

    private var hud: some View {
        VStack(spacing: 8) {
            Text("Lumière Camera")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            Text("16.67 ms · 17.5 TOPS · Airy + Poisson")
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.bottom, 24)
    }

    private var permissionDenied: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.slash")
                .font(.largeTitle)
                .foregroundStyle(.white)
            Text("Camera access required")
                .foregroundStyle(.white)
                .font(.headline)
            Text("Enable in Settings → Privacy & Security → Camera")
                .foregroundStyle(.white.opacity(0.7))
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
