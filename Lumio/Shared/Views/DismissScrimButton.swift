import SwiftUI

struct DismissScrimButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }
}
