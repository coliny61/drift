import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: "FF6B35"))
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0A0A0A"))
    }
}
