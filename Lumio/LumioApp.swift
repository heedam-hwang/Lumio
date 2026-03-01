import SwiftData
import SwiftUI

@main
struct LumioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Book.self, Page.self, SentenceItem.self, VocabularyItem.self, SavedVocabulary.self])
    }
}
