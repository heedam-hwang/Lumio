import SwiftUI

struct BookCoverView: View {
    let coverImageData: Data?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            LumioColors.coverGradientStart,
                            LumioColors.coverGradientEnd
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(0.75, contentMode: .fit)

            if let coverImageData,
               let uiImage = UIImage(data: coverImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.75, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 20))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    Text("Lumio")
                        .font(LumioTypography.cardTitle)
                    Spacer()
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LumioColors.coverSpineBlue)
                            .frame(width: 26)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(LumioColors.coverSpineGold)
                            .frame(width: 26)
                    }
                    .frame(height: 84)
                }
                .foregroundStyle(LumioColors.coverText)
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(LumioColors.softCardStroke, lineWidth: 1)
        }
        .lumioShadow(LumioShadows.cover)
    }
}
