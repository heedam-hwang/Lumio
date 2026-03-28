import SwiftUI

struct LoadingOverlayView: View {
    let title: String

    var body: some View {
        ZStack {
            LumioColors.scrim
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
