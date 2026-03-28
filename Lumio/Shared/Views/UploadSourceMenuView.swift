import SwiftUI

struct UploadSourceMenuView: View {
    let onCameraTap: () -> Void
    let onPhotoTap: () -> Void
    let isCameraAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onCameraTap) {
                Label("카메라", systemImage: "camera")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(LumioTypography.menuLabel)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LumioColors.systemSecondarySurface)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isCameraAvailable)

            Button(action: onPhotoTap) {
                Label("포토 라이브러리", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(LumioTypography.menuLabel)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LumioColors.systemSecondarySurface)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .lumioShadow(LumioShadows.menu)
        .frame(width: 230)
    }
}
