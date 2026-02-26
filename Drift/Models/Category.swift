import Foundation

enum Category: String, Codable, CaseIterable, Identifiable, Hashable {
    // Wellness core
    case runClub = "run_club"
    case soundBath = "sound_bath"
    case breathwork
    case coldPlunge = "cold_plunge"
    case yoga
    case social
    case meditation
    case fitness
    case workshop

    // Adjacent wellness
    case hiking
    case cycling
    case outdoorFitness = "outdoor_fitness"
    case recovery

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
        case .hiking: return "Hiking"
        case .cycling: return "Cycling"
        case .outdoorFitness: return "Outdoor Fitness"
        case .recovery: return "Recovery"
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
        case .hiking: return "figure.hiking"
        case .cycling: return "figure.outdoor.cycle"
        case .outdoorFitness: return "figure.strengthtraining.functional"
        case .recovery: return "heart.circle.fill"
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
        case .hiking: return "#66BB6A"
        case .cycling: return "#42A5F5"
        case .outdoorFitness: return "#FFA726"
        case .recovery: return "#EC407A"
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
        case .hiking: return "hiking"
        case .cycling: return "cycling"
        case .outdoorFitness: return "outdoor-fitness"
        case .recovery: return "recovery"
        }
    }

    static let allCategories: [Category] = Category.allCases
}
