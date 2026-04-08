import SwiftUI

struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var cameraVM: CameraViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraPreview(session: cameraVM.session)
                .edgesIgnoringSafeArea(.all)

            Button(action: {
                cameraVM.stopSession()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding([.top, .leading], 30)
            }
        }
        .onAppear {
            cameraVM.startSession()
        }
        .onDisappear {
            cameraVM.stopSession()
        }
    }
}
