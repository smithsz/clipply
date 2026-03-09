import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.on.clipboard")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Clipply is running in the menu bar")
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
