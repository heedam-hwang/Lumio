import SwiftUI

struct PageImagePreviewView: View {
    let imageData: Data?
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 84)
            }

            Button(action: onDismiss) {
                Label("닫기", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 28))
                    .foregroundStyle(LumioColors.elevatedCardSurface)
                    .padding()
            }
        }
    }
}
