import Foundation

enum EventCacheService {
    private static let fileName = "drift_events_cache.json"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func save(_ events: [Event]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("EventCacheService: failed to save — \(error)")
        }
    }

    static func load() -> [Event]? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Event].self, from: data)
        } catch {
            print("EventCacheService: failed to load — \(error)")
            return nil
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
