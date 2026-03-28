import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("홈", systemImage: "house", value: .home) {
                HomeView()
            }

            Tab("단어장", systemImage: "book", value: .vocabulary) {
                NavigationStack {
                    VocabularyView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
