import Foundation

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case nature
    case water
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nature:
            return "Nature"
        case .water:
            return "Water"
        case .personal:
            return "Personal"
        }
    }
}
