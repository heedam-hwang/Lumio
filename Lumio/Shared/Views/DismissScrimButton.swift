import SwiftUI

struct DismissScrimButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LumioColors.tapScrim
                .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }
}
