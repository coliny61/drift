import SwiftUI

struct OrganizerLogoView: View {
    let organizer: Organizer
    var size: CGFloat = 48

    var body: some View {
        if let logoUrl = organizer.logoUrl, let url = URL(string: logoUrl) {
            CachedAsyncImage(url: url) {
                placeholder
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityLabel("Logo of \(organizer.name)")
            .accessibilityAddTraits(.isImage)
        } else {
            placeholder
                .accessibilityLabel("Logo of \(organizer.name)")
                .accessibilityAddTraits(.isImage)
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppConstants.Colors.accent.opacity(0.3), AppConstants.Colors.accent.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(String(organizer.name.prefix(1)))
                    .font(size > 60 ? .title : .headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppConstants.Colors.accent)
            }
    }
}
