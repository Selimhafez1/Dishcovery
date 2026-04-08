import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Get current window scene
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let connection = uiView.videoPreviewLayer.connection {

            // Get the current interface orientation (no optional unwrapping needed)
            let interfaceOrientation = scene.interfaceOrientation

            // Convert UIInterfaceOrientation to AVCaptureVideoOrientation
            let videoOrientation: AVCaptureVideoOrientation
            switch interfaceOrientation {
            case .portrait: videoOrientation = .portrait
            case .landscapeLeft: videoOrientation = .landscapeRight
            case .landscapeRight: videoOrientation = .landscapeLeft
            case .portraitUpsideDown: videoOrientation = .portraitUpsideDown
            default: videoOrientation = .portrait
            }

            // Update video orientation
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = videoOrientation
            }
        }
    }


}


