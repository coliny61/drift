import Foundation

struct Event: Codable, Identifiable, Hashable {
    let id: UUID
    let organizerId: UUID
    let title: String
    let description: String
    let shortDescription: String
    let coverImageUrl: String?
    let category: String
    let tags: [String]
    let startTime: Date
    let endTime: Date
    let recurrenceRule: String?
    let locationName: String
    let locationAddress: String
    let locationLat: Double
    let locationLng: Double
    let neighborhood: String
    let maxCapacity: Int?
    let priceCents: Int
    let externalUrl: String?
    let isFeatured: Bool
    let rsvpCount: Int
    let status: String

    // Phase 2 fields
    var approvalStatus: String? = nil
    var featuredUntil: Date? = nil
    var sponsorLabel: String? = nil
    var submittedBy: UUID? = nil
    var city: String? = nil
    var ticketUrl: String? = nil

    // MARK: - Computed Properties

    var isFree: Bool {
        priceCents == 0
    }

    var priceFormatted: String {
        if isFree {
            return "Free"
        }
        let dollars = Double(priceCents) / 100.0
        return String(format: "$%.2f", dollars)
    }

    var categoryEnum: Category? {
        Category.allCases.first { $0.slug == category || $0.rawValue == category }
    }

    var isAlcoholFree: Bool {
        tags.contains("alcohol-free") || tags.contains("sober")
    }

    var isUpcoming: Bool {
        startTime > Date()
    }

    var isApproved: Bool {
        approvalStatus == "approved" || approvalStatus == nil
    }

    var isPending: Bool {
        approvalStatus == "pending"
    }

    var isRejected: Bool {
        approvalStatus == "rejected"
    }

    var isCurrentlyFeatured: Bool {
        guard isFeatured else { return false }
        if let until = featuredUntil {
            return until > Date()
        }
        return true
    }

    var sponsorDisplayLabel: String? {
        guard isCurrentlyFeatured else { return nil }
        if let label = sponsorLabel, !label.isEmpty {
            return "Sponsored by \(label)"
        }
        return "Featured"
    }

    /// Returns ticket URL if paid event, falls back to external URL
    var purchaseUrl: String? {
        if !isFree {
            return ticketUrl ?? externalUrl
        }
        return externalUrl
    }

    var isInCheckInWindow: Bool {
        let now = Date()
        let windowStart = startTime.addingTimeInterval(-30 * 60) // 30 min before
        let windowEnd = endTime.addingTimeInterval(30 * 60)       // 30 min after
        return now >= windowStart && now <= windowEnd
    }

    var hasEnded: Bool {
        endTime < Date()
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case organizerId = "organizer_id"
        case title
        case description
        case shortDescription = "short_description"
        case coverImageUrl = "cover_image_url"
        case category
        case tags
        case startTime = "start_time"
        case endTime = "end_time"
        case recurrenceRule = "recurrence_rule"
        case locationName = "location_name"
        case locationAddress = "location_address"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case neighborhood
        case maxCapacity = "max_capacity"
        case priceCents = "price_cents"
        case externalUrl = "external_url"
        case isFeatured = "is_featured"
        case rsvpCount = "rsvp_count"
        case status
        case approvalStatus = "approval_status"
        case featuredUntil = "featured_until"
        case sponsorLabel = "sponsor_label"
        case submittedBy = "submitted_by"
        case city
        case ticketUrl = "ticket_url"
    }
}
