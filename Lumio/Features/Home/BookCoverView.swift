import SwiftUI

struct BookCoverView: View {
    let placeholderPaletteSeed: Int?
    let coverImageData: Data?

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(backgroundFill)
            .overlay {
                Group {
                    if let coverImageData,
                       let uiImage = UIImage(data: coverImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(18)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                }
                .clipped()
            }
            .frame(maxWidth: .infinity)
        .aspectRatio(0.75, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(LumioColors.softCardStroke, lineWidth: 1)
        }
        .lumioShadow(LumioShadows.cover)
    }

    private var backgroundFill: LinearGradient {
        let palette = placeholderPalette
        return LinearGradient(
            colors: [palette.start, palette.end],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var placeholderPalette: (start: Color, end: Color) {
        let palettes: [(Color, Color)] = [
            (Color(red: 238 / 255, green: 216 / 255, blue: 188 / 255), Color(red: 201 / 255, green: 167 / 255, blue: 132 / 255)),
            (Color(red: 214 / 255, green: 226 / 255, blue: 206 / 255), Color(red: 154 / 255, green: 182 / 255, blue: 149 / 255)),
            (Color(red: 220 / 255, green: 223 / 255, blue: 236 / 255), Color(red: 162 / 255, green: 171 / 255, blue: 205 / 255)),
            (Color(red: 241 / 255, green: 214 / 255, blue: 203 / 255), Color(red: 221 / 255, green: 164 / 255, blue: 143 / 255)),
            (Color(red: 230 / 255, green: 224 / 255, blue: 196 / 255), Color(red: 196 / 255, green: 182 / 255, blue: 129 / 255))
        ]
        let seed = placeholderPaletteSeed ?? 0
        let index = abs(seed) % palettes.count
        return palettes[index]
    }
}
