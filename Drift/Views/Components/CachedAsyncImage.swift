import SwiftUI

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = true

    private static var cache: NSCache<NSURL, UIImage> {
        let cache = _imageCache
        return cache
    }

    init(url: URL?, contentMode: ContentMode = .fill, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else {
            isLoading = false
            return
        }

        // Check memory cache
        if let cached = Self.cache.object(forKey: url as NSURL) {
            self.image = cached
            isLoading = false
            return
        }

        // Check URL cache (disk)
        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let uiImage = UIImage(data: cachedResponse.data) {
            Self.cache.setObject(uiImage, forKey: url as NSURL)
            self.image = uiImage
            isLoading = false
            return
        }

        // Download
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let uiImage = UIImage(data: data) else { return }

            // Store in both caches
            let cachedResponse = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedResponse, for: request)
            Self.cache.setObject(uiImage, forKey: url as NSURL)

            await MainActor.run {
                self.image = uiImage
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// Shared cache instance — 100 MB limit, ~200 images
private let _imageCache: NSCache<NSURL, UIImage> = {
    let cache = NSCache<NSURL, UIImage>()
    cache.countLimit = 200
    cache.totalCostLimit = 100 * 1024 * 1024
    return cache
}()
