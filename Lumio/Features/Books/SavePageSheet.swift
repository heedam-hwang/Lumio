import SwiftUI

struct SavePageSheet: View {
    let books: [Book]
    @Binding var pageTitle: String
    let onCancel: () -> Void
    let onSave: (BookClassificationMode, Book?, String) -> Void

    @State private var mode: BookClassificationMode = .unclassified
    @State private var selectedBookID: UUID?
    @State private var newBookTitle = ""

    private var selectedBook: Book? {
        guard let selectedBookID else { return nil }
        return books.first(where: { $0.id == selectedBookID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("페이지 이름") {
                    TextField("페이지 이름 (선택)", text: $pageTitle)

                    Text("입력하지 않으면 현재 시간을 기준으로 자동 생성됩니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("책 분류") {
                    Picker("저장 방식", selection: $mode) {
                        ForEach(BookClassificationMode.allCases) { value in
                            Text(value.title).tag(value)
                        }
                    }

                    if mode == .existing {
                        if books.isEmpty {
                            Text("선택 가능한 책이 없습니다. '분류하지 않음' 또는 '새 책 생성'을 사용하세요.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("책 선택", selection: $selectedBookID) {
                                Text("선택하세요").tag(UUID?.none)
                                ForEach(books) { book in
                                    Text(book.title).tag(UUID?.some(book.id))
                                }
                            }
                        }
                    }

                    if mode == .new {
                        TextField("새 책 이름", text: $newBookTitle)
                    }
                }
            }
            .navigationTitle("페이지 저장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(mode, selectedBook, newBookTitle)
                    }
                    .disabled(mode == .existing && books.isEmpty)
                }
            }
        }
    }
}
