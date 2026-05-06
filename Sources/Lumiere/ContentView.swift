import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }

            StudioView()
                .tabItem {
                    Label("Studio", systemImage: "film")
                }
        }
    }
}

#Preview {
    ContentView()
}
