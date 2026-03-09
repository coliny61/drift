import Foundation

enum AppDestination: Hashable {
    case event(UUID)
    case organizer(UUID)
    case conversation(UUID)
}
