import UIKit

/// Built-in task images bundled with Ansh's Scheduler.
enum AnshSchedulerPresetTaskImage: String, CaseIterable, Identifiable, Sendable {
    case birthday
    case wakeUp
    case sleep

    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .birthday: return "AnshPresetBirthday"
        case .wakeUp: return "AnshPresetWakeUp"
        case .sleep: return "AnshPresetSleep"
        }
    }

    var displayName: String {
        switch self {
        case .birthday: return "Birthday"
        case .wakeUp: return "Wake Up"
        case .sleep: return "Sleep"
        }
    }

    var uiImage: UIImage? {
        UIImage(named: assetName)
    }

    func pngData() -> Data? {
        uiImage?.pngData()
    }
}
