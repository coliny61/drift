import SwiftUI

struct PrimaryButtonView: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppConstants.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppConstants.Colors.accent.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }
}
