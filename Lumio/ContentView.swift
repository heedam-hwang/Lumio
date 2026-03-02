import PhotosUI
import SwiftData
import SwiftUI
import UIKit

private enum BookClassificationMode: String, CaseIterable, Identifiable {
    case unclassified
    case existing
    case new

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unclassified:
            return "분류하지 않음"
        case .existing:
            return "기존 책 선택"
        case .new:
            return "새 책 생성"
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("홈", systemImage: "house")
            }

            NavigationStack {
                VocabularyView()
            }
            .tabItem {
                Label("단어장", systemImage: "book")
            }
        }
    }
}

private struct HomeView: View {
    private static let unclassifiedBookTitle = "분류되지 않음"

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Book.title)]) private var books: [Book]

    @State private var showUploadSourceMenu = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var pendingImageData: Data?
    @State private var showSavePageSheet = false

    @State private var editingBook: Book?
    @State private var editingBookTitle = ""
    @State private var showBookRenameAlert = false
    @State private var persistenceErrorMessage: String?
    @State private var showPersistenceErrorAlert = false

    @State private var isAnalyzingUpload = false
    @State private var uploadErrorMessage: String?
    @State private var showUploadErrorAlert = false
    @State private var customPageTitle = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if books.isEmpty {
                    ContentUnavailableView {
                        Label("아직 등록된 책이 없습니다", systemImage: "book.closed")
                    } description: {
                        Text("오른쪽 아래 업로드 버튼으로 책 페이지를 추가해 보세요.")
                    }
                } else {
                    List(books) { book in
                        NavigationLink {
                            BookPagesView(book: book)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.headline)
                                Text("페이지 \(book.pages.count)개")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityHint("선택하면 책의 페이지 목록으로 이동합니다.")
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("이름 변경") {
                                editingBook = book
                                editingBookTitle = book.title
                                showBookRenameAlert = true
                            }
                            .tint(.blue)
                        }
                    }
                    .listStyle(.plain)
                }
            }

            if showUploadSourceMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showUploadSourceMenu = false
                    }
                    .zIndex(1)

                UploadSourceMenuView(
                    onCameraTap: {
                        showUploadSourceMenu = false
                        showCamera = true
                    },
                    onPhotoTap: {
                        showUploadSourceMenu = false
                        showPhotoPicker = true
                    }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 86)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(2)
            }

            Button {
                showUploadSourceMenu.toggle()
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("책 페이지 업로드")
            .accessibilityHint("카메라 또는 포토 라이브러리에서 책 페이지를 추가합니다.")
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .disabled(isAnalyzingUpload)
            .zIndex(3)
        }
        .navigationTitle("책 목록")
        .overlay {
            if isAnalyzingUpload {
                LoadingOverlayView(title: "문장/단어 감지 중")
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            prepareImageForSave(data)
                        }
                    } else {
                        await MainActor.run {
                            uploadErrorMessage = "선택한 사진을 읽을 수 없습니다."
                            showUploadErrorAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        uploadErrorMessage = "사진 불러오기에 실패했습니다. 다시 시도해 주세요."
                        showUploadErrorAlert = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { imageData in
                prepareImageForSave(imageData)
            }
            // Ensure camera UI occupies full screen without inheriting clipped safe-area layout.
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSavePageSheet, onDismiss: {
            pendingImageData = nil
            selectedPhotoItem = nil
            customPageTitle = ""
        }) {
            SavePageSheet(
                books: books,
                pageTitle: $customPageTitle,
                onCancel: {
                    showSavePageSheet = false
                },
                onSave: { mode, selectedBook, newBookTitle in
                    showSavePageSheet = false
                    Task {
                        await createPageAndAnalyze(
                            mode: mode,
                            selectedBook: selectedBook,
                            newBookTitle: newBookTitle,
                            pageTitle: customPageTitle
                        )
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .alert("책 이름 변경", isPresented: $showBookRenameAlert) {
            TextField("책 이름", text: $editingBookTitle)
            Button("취소", role: .cancel) {}
            Button("저장") {
                let trimmed = editingBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, let editingBook else { return }
                editingBook.title = trimmed
                do {
                    try modelContext.save()
                } catch {
                    persistenceErrorMessage = "책 이름 저장에 실패했습니다."
                    showPersistenceErrorAlert = true
                }
            }
        } message: {
            Text("홈 화면의 책 분류 이름을 수정합니다.")
        }
        .alert("저장 실패", isPresented: $showPersistenceErrorAlert, actions: {
            Button("확인", role: .cancel) {}
        }, message: {
            Text(persistenceErrorMessage ?? "데이터 저장에 실패했습니다.")
        })
        .alert("OCR 처리 실패", isPresented: $showUploadErrorAlert, actions: {
            Button("확인", role: .cancel) {}
        }, message: {
            Text(uploadErrorMessage ?? "문장/단어 감지에 실패했습니다.")
        })
    }

    private func prepareImageForSave(_ imageData: Data) {
        pendingImageData = imageData
        showSavePageSheet = true
    }

    @MainActor
    private func createPageAndAnalyze(
        mode: BookClassificationMode,
        selectedBook: Book?,
        newBookTitle: String,
        pageTitle: String
    ) async {
        guard let imageData = pendingImageData else { return }

        isAnalyzingUpload = true
        defer {
            isAnalyzingUpload = false
            pendingImageData = nil
            selectedPhotoItem = nil
        }

        let targetBook = resolveTargetBook(
            mode: mode,
            selectedBook: selectedBook,
            newBookTitle: newBookTitle
        )

        let page = Page(
            title: resolvedPageTitle(input: pageTitle),
            createdAt: Date(),
            imageData: imageData,
            book: targetBook
        )
        modelContext.insert(page)

        do {
            try modelContext.save()
            try await PageTextAnalyzer.analyzeIfNeeded(page: page, context: modelContext)
        } catch {
            uploadErrorMessage = error.localizedDescription
            showUploadErrorAlert = true
        }
    }

    private func resolveTargetBook(mode: BookClassificationMode, selectedBook: Book?, newBookTitle: String) -> Book {
        switch mode {
        case .existing:
            if let selectedBook {
                return selectedBook
            }
            return fetchOrCreateUnclassifiedBook()

        case .new:
            let trimmed = newBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                return fetchOrCreateUnclassifiedBook()
            }

            let createdBook = Book(title: trimmed)
            modelContext.insert(createdBook)
            return createdBook

        case .unclassified:
            return fetchOrCreateUnclassifiedBook()
        }
    }

    private func fetchOrCreateUnclassifiedBook() -> Book {
        let descriptor = FetchDescriptor<Book>(predicate: #Predicate { book in
            book.title == "분류되지 않음"
        })

        if let existingBook = try? modelContext.fetch(descriptor).first {
            return existingBook
        }

        let defaultBook = Book(title: HomeView.unclassifiedBookTitle)
        modelContext.insert(defaultBook)
        return defaultBook
    }

    private func makeDefaultPageTitle(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "페이지 \(formatter.string(from: date))"
    }

    private func resolvedPageTitle(input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? makeDefaultPageTitle() : trimmed
    }
}

private struct BookPagesView: View {
    @Environment(\.modelContext) private var modelContext
    let book: Book

    @State private var editingPage: Page?
    @State private var editingPageTitle = ""
    @State private var showPageRenameAlert = false
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false

    private var sortedPages: [Page] {
        book.pages.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        Group {
            if sortedPages.isEmpty {
                ContentUnavailableView {
                    Label("등록된 페이지가 없습니다", systemImage: "doc")
                } description: {
                    Text("홈에서 업로드 버튼을 눌러 페이지를 추가해 보세요.")
                }
            } else {
                List(sortedPages) { page in
                    NavigationLink {
                        PageDetailView(page: page)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(page.title ?? "제목 없음")
                                .font(.headline)
                            Text(page.createdAt.formatted(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .accessibilityHint("선택하면 페이지 상세 화면으로 이동합니다.")
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("제목 변경") {
                            editingPage = page
                            editingPageTitle = page.title ?? ""
                            showPageRenameAlert = true
                        }
                        .tint(.blue)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(book.title)
        .alert("페이지 제목 변경", isPresented: $showPageRenameAlert) {
            TextField("페이지 제목", text: $editingPageTitle)
            Button("취소", role: .cancel) {}
            Button("저장") {
                guard let editingPage else { return }
                let trimmed = editingPageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                editingPage.title = trimmed.isEmpty ? nil : trimmed
                do {
                    try modelContext.save()
                } catch {
                    saveErrorMessage = "페이지 제목 저장에 실패했습니다."
                    showSaveErrorAlert = true
                }
            }
        } message: {
            Text("페이지 목록에서 보이는 제목을 수정합니다.")
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert, actions: {
            Button("확인", role: .cancel) {}
        }, message: {
            Text(saveErrorMessage ?? "데이터 저장에 실패했습니다.")
        })
    }
}

private struct PageDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SavedVocabulary.word)]) private var savedWords: [SavedVocabulary]
    let page: Page

    @State private var selectedSentenceID: UUID?
    @State private var selectedWordText: String?
    @State private var selectedSentenceForSheet: SentenceItem?
    @State private var selectedWordForSheet: VocabularyItem?
    @State private var isAnalyzing = false
    @State private var analyzeErrorMessage: String?
    @State private var showAnalyzeErrorAlert = false
    @State private var showImagePreview = false
    @State private var pageTitleDraft = ""
    @State private var showPageRenameAlert = false
    @State private var saveErrorMessage: String?
    @State private var showSaveErrorAlert = false

    private var sortedSentences: [SentenceItem] {
        page.sentences.sorted { $0.order < $1.order }
    }

    private var savedWordSet: Set<String> {
        Set(savedWords.map { $0.word.lowercased() })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader

                sentenceSection
            }
            .padding(20)
        }
        .navigationTitle("페이지")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isAnalyzing {
                LoadingOverlayView(title: "문장/단어 감지 중")
            }
        }
        .task(id: page.id) {
            await ensureDetectionDataIfNeeded()
        }
        .alert("OCR 처리 실패", isPresented: $showAnalyzeErrorAlert, actions: {
            Button("확인", role: .cancel) {}
        }, message: {
            Text(analyzeErrorMessage ?? "문장/단어 감지에 실패했습니다.")
        })
        .sheet(item: $selectedSentenceForSheet) { sentence in
            SentenceLookupSheet(sentence: sentence)
                .presentationDetents([.fraction(0.5), .large])
        }
        .sheet(item: $selectedWordForSheet) { word in
            WordLookupSheet(word: word)
            .presentationDetents([.fraction(0.5), .large])
        }
        .fullScreenCover(isPresented: $showImagePreview) {
            imagePreviewSheet
        }
        .alert("페이지 제목 변경", isPresented: $showPageRenameAlert) {
            TextField("페이지 제목", text: $pageTitleDraft)
            Button("취소", role: .cancel) {}
            Button("저장") {
                let trimmed = pageTitleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                page.title = trimmed.isEmpty ? nil : trimmed
                do {
                    try modelContext.save()
                } catch {
                    saveErrorMessage = "페이지 제목 저장에 실패했습니다."
                    showSaveErrorAlert = true
                }
            }
        } message: {
            Text("페이지 이름을 수정할 수 있습니다.")
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert, actions: {
            Button("확인", role: .cancel) {}
        }, message: {
            Text(saveErrorMessage ?? "데이터 저장에 실패했습니다.")
        })
    }

    private var pageHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            if let data = page.imageData, let uiImage = UIImage(data: data) {
                Button {
                    showImagePreview = true
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("원본 이미지 확대 보기")
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(page.title ?? "제목 없음")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Button {
                        pageTitleDraft = page.title ?? ""
                        showPageRenameAlert = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("페이지 이름 수정")
                }
                Text(page.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var imagePreviewSheet: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let data = page.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 84)
            }
            Button {
                showImagePreview = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding()
            }
        }
    }

    private var sentenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("문장")
                .font(.headline)

            if sortedSentences.isEmpty {
                if page.isTextAnalyzed {
                    Text("감지된 문장이 없습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("문장 데이터를 준비 중입니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(sortedSentences) { sentence in
                    SentenceRowView(
                        sentence: sentence,
                        isSelected: selectedSentenceID == sentence.id,
                        selectedWordText: selectedWordText,
                        savedWords: savedWordSet,
                        onSentenceTap: {
                            selectedSentenceID = sentence.id
                            selectedSentenceForSheet = sentence
                        },
                        onWordTap: { tappedWord in
                            selectedWordText = tappedWord
                            selectedWordForSheet = VocabularyItem(word: tappedWord)
                        }
                    )
                }
            }
        }
    }

    @MainActor
    private func ensureDetectionDataIfNeeded() async {
        if page.isTextAnalyzed {
            return
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            try await PageTextAnalyzer.analyzeIfNeeded(page: page, context: modelContext)
        } catch {
            analyzeErrorMessage = error.localizedDescription
            showAnalyzeErrorAlert = true
        }
    }
}

private struct SentenceRowView: View {
    let sentence: SentenceItem
    let isSelected: Bool
    let selectedWordText: String?
    let savedWords: Set<String>
    let onSentenceTap: () -> Void
    let onWordTap: (String) -> Void

    private var tokens: [SentenceToken] {
        SentenceToken.build(from: sentence.text)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                onSentenceTap()
            } label: {
                Text("\(sentence.order)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)

            FlowWrapLayout(spacing: 4, lineSpacing: 6) {
                ForEach(tokens) { token in
                    if token.isWord {
                        Button {
                            onWordTap(token.normalized)
                        } label: {
                            Text(token.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(backgroundColor(for: token.normalized))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, token.trailingSpacing)
                    } else {
                        Text(token.text)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.trailing, token.trailingSpacing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
        )
    }

    private func backgroundColor(for word: String) -> Color {
        if savedWords.contains(word) {
            return .yellow.opacity(0.55)
        }
        if selectedWordText == word {
            return Color.accentColor.opacity(0.2)
        }
        return .clear
    }
}

private struct SentenceToken: Identifiable {
    let id = UUID()
    let text: String
    let isWord: Bool
    let normalized: String
    let trailingSpacing: CGFloat

    static func build(from sentence: String) -> [SentenceToken] {
        guard let regex = try? NSRegularExpression(pattern: #"[A-Za-z]+(?:'[A-Za-z]+)?|[^A-Za-z\s]+"#) else {
            return []
        }

        let nsSentence = sentence as NSString
        let range = NSRange(location: 0, length: nsSentence.length)
        let matches = regex.matches(in: sentence, range: range)

        return matches.map { match in
            let token = nsSentence.substring(with: match.range)
            let isWord = token.range(of: #"[A-Za-z]+"#, options: .regularExpression) != nil
            let spacing: CGFloat = token.range(of: #"[,.!?;:]"#, options: .regularExpression) != nil ? 2 : 4
            return SentenceToken(
                text: token,
                isWord: isWord,
                normalized: token.lowercased(),
                trailingSpacing: spacing
            )
        }
    }
}

private struct FlowWrapLayout: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 6

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + lineSpacing
                rowHeight = 0
            }
            maxX = max(maxX, currentX + size.width)
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: maxX, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + lineSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

private struct UploadSourceMenuView: View {
    let onCameraTap: () -> Void
    let onPhotoTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                onCameraTap()
            } label: {
                Label("카메라", systemImage: "camera")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            .buttonStyle(.plain)

            Button {
                onPhotoTap()
            } label: {
                Label("포토 라이브러리", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 4)
        .frame(width: 230)
    }
}

private struct SavePageSheet: View {
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
                    Button("취소") {
                        onCancel()
                    }
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

private struct LoadingOverlayView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct VocabularyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SavedVocabulary.createdAt, order: .reverse)]) private var savedWords: [SavedVocabulary]
    @State private var unbookmarkingWordIDs = Set<UUID>()

    var body: some View {
        Group {
            if savedWords.isEmpty {
                ContentUnavailableView {
                    Label("단어장이 비어 있습니다", systemImage: "text.book.closed")
                } description: {
                    Text("단어 조회 화면에서 북마크를 눌러 단어를 저장해 보세요.")
                }
            } else {
                List(savedWords) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.word)
                                .font(.headline)
                            Button {
                                SpeechService.shared.speak(text: item.word)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                            }
                            .accessibilityLabel("\(item.word) 발음 듣기")
                            .padding(.leading, 6)
                            Spacer(minLength: 0)
                            Button {
                                unbookmark(item)
                            } label: {
                                Image(systemName: unbookmarkingWordIDs.contains(item.id) ? "bookmark" : "bookmark.fill")
                            }
                            .disabled(unbookmarkingWordIDs.contains(item.id))
                            .accessibilityLabel("\(item.word) 북마크 해제")
                        }

                        if let meaning = item.meaning, !meaning.isEmpty {
                            Text(meaning)
                                .font(.body)
                        }

                        Text(item.createdAt.formatted(date: .numeric, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("단어장")
    }

    private func remove(_ item: SavedVocabulary) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func unbookmark(_ item: SavedVocabulary) {
        unbookmarkingWordIDs.insert(item.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            remove(item)
            unbookmarkingWordIDs.remove(item.id)
        }
    }
}

#Preview {
    ContentView()
}
