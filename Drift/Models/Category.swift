import Foundation

enum Category: String, Codable, CaseIterable, Identifiable, Hashable {
    case runClub = "run_club"
    case soundBath = "sound_bath"
    case breathwork
    case coldPlunge = "cold_plunge"
    case yoga
    case social
    case meditation
    case fitness
    case workshop

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .runClub: return "Run Club"
        case .soundBath: return "Sound Bath"
        case .breathwork: return "Breathwork"
        case .coldPlunge: return "Cold Plunge"
        case .yoga: return "Yoga"
        case .social: return "Social"
        case .meditation: return "Meditation"
        case .fitness: return "Fitness"
        case .workshop: return "Workshop"
        }
    }

    var icon: String {
        switch self {
        case .runClub: return "figure.run"
        case .soundBath: return "waveform"
        case .breathwork: return "wind"
        case .coldPlunge: return "snowflake"
        case .yoga: return "figure.mind.and.body"
        case .social: return "person.3.fill"
        case .meditation: return "brain.head.profile"
        case .fitness: return "dumbbell.fill"
        case .workshop: return "lightbulb.fill"
        }
    }

    var color: String {
        switch self {
        case .runClub: return "#FF6B35"
        case .soundBath: return "#7B68EE"
        case .breathwork: return "#00CED1"
        case .coldPlunge: return "#4FC3F7"
        case .yoga: return "#FF8A65"
        case .social: return "#FFD54F"
        case .meditation: return "#81C784"
        case .fitness: return "#EF5350"
        case .workshop: return "#BA68C8"
        }
    }

    var slug: String {
        switch self {
        case .runClub: return "run-club"
        case .soundBath: return "sound-bath"
        case .breathwork: return "breathwork"
        case .coldPlunge: return "cold-plunge"
        case .yoga: return "yoga"
        case .social: return "social"
        case .meditation: return "meditation"
        case .fitness: return "fitness"
        case .workshop: return "workshop"
        }
    }

    static let allCategories: [Category] = Category.allCases
}
