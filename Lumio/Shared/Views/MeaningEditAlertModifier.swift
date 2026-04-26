import SwiftUI

struct MeaningEditAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var draft: String
    let onSave: () -> Void

    func body(content: Content) -> some View {
        content.alert("뜻 수정", isPresented: $isPresented) {
            TextField("뜻", text: $draft, axis: .vertical)
            Button("취소", role: .cancel) {}
            Button("저장", action: onSave)
        } message: {
            Text("번역 결과가 어색하면 직접 수정해 저장할 수 있습니다.")
        }
    }
}

extension View {
    func meaningEditAlert(
        isPresented: Binding<Bool>,
        draft: Binding<String>,
        onSave: @escaping () -> Void
    ) -> some View {
        modifier(
            MeaningEditAlertModifier(
                isPresented: isPresented,
                draft: draft,
                onSave: onSave
            )
        )
    }
}
