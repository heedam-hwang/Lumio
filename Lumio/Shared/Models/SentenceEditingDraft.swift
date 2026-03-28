import Foundation

struct SentenceEditingDraft: Identifiable {
    let id: UUID
    var text: String

    init(sentence: SentenceItem) {
        id = sentence.id
        text = sentence.text
    }
}
