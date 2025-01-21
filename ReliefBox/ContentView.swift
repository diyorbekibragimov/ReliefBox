import SwiftUI
import ExyteChat

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        NavigationView {
            VStack {
                ChatView(messages: viewModel.messages) { draft in
                    viewModel.send(draft: draft)
                }
                .navigationTitle("ReliefBox") // Set the navigation bar title
                .navigationBarTitleDisplayMode(.inline) // Inline title display
                .padding()
            }
        }
    }
}
