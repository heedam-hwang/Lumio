import SwiftUI

struct BookCoverView: View {
    let coverImageData: Data?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.9), Color.yellow.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
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
                    .clipShape(.rect(cornerRadius: 18))
            } else {
                VStack(alignment: .trailing, spacing: 8) {
                    Spacer()
                    Image(systemName: "books.vertical.fill")
                        .font(.title.bold())
                }
                .foregroundStyle(.white)
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .clipShape(.rect(cornerRadius: 18))
    }
}
