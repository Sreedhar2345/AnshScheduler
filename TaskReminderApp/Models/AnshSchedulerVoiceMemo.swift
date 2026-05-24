import Foundation

/// Identifies a voice memo attached to a task notification.
enum AnshSchedulerVoiceMemoSelection: Equatable, Hashable, Sendable {
    case none
    case preset(AnshSchedulerBundledVoiceMemo)
    case custom(UUID)

    var storageIdentifier: String? {
        switch self {
        case .none:
            return nil
        case .preset(let preset):
            return preset.storageID
        case .custom(let id):
            return AnshSchedulerConstants.customVoiceMemoStoragePrefix + id.uuidString
        }
    }

    init?(storageIdentifier: String?) {
        guard let storageIdentifier, !storageIdentifier.isEmpty else {
            self = .none
            return
        }
        if let preset = AnshSchedulerBundledVoiceMemo(storageID: storageIdentifier) {
            self = .preset(preset)
            return
        }
        if storageIdentifier.hasPrefix(AnshSchedulerConstants.customVoiceMemoStoragePrefix) {
            let rawID = String(
                storageIdentifier.dropFirst(AnshSchedulerConstants.customVoiceMemoStoragePrefix.count)
            )
            guard let uuid = UUID(uuidString: rawID) else { return nil }
            self = .custom(uuid)
            return
        }
        if storageIdentifier.hasPrefix(AnshSchedulerConstants.legacyCustomVoiceMemoStoragePrefix) {
            let rawID = String(
                storageIdentifier.dropFirst(AnshSchedulerConstants.legacyCustomVoiceMemoStoragePrefix.count)
            )
            guard let uuid = UUID(uuidString: rawID) else { return nil }
            self = .custom(uuid)
            return
        }
        return nil
    }
}

enum AnshSchedulerBundledVoiceMemo: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case wakeUp

    var id: String { rawValue }

    var storageID: String {
        AnshSchedulerConstants.presetVoiceMemoStoragePrefix + rawValue
    }

    init?(storageID: String) {
        if storageID.hasPrefix(AnshSchedulerConstants.presetVoiceMemoStoragePrefix) {
            let raw = String(storageID.dropFirst(AnshSchedulerConstants.presetVoiceMemoStoragePrefix.count))
            self.init(rawValue: raw)
            return
        }
        if storageID.hasPrefix(AnshSchedulerConstants.legacyPresetVoiceMemoStoragePrefix) {
            let raw = String(storageID.dropFirst(AnshSchedulerConstants.legacyPresetVoiceMemoStoragePrefix.count))
            self.init(rawValue: raw)
            return
        }
        return nil
    }

    var displayName: String {
        switch self {
        case .wakeUp: return "Wake Up"
        }
    }

    /// CAF filename in the app bundle (notification-compatible format).
    var notificationSoundFilename: String {
        switch self {
        case .wakeUp: return "WakeUp.caf"
        }
    }

    /// Original MP3 in the bundle for in-app preview/import reference.
    var bundledMP3ResourceName: String {
        switch self {
        case .wakeUp: return "Wake up"
        }
    }

    var bundledMP3FileExtension: String { "mp3" }
}

struct AnshSchedulerCustomVoiceMemo: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var displayName: String
    var notificationSoundFilename: String

    init(id: UUID = UUID(), displayName: String, notificationSoundFilename: String) {
        self.id = id
        self.displayName = displayName
        self.notificationSoundFilename = notificationSoundFilename
    }
}

enum AnshSchedulerVoiceMemoCatalog {
    static var bundledMemos: [AnshSchedulerBundledVoiceMemo] {
        AnshSchedulerBundledVoiceMemo.allCases
    }
}

struct AnshSchedulerVoiceMemoImportConfirmation: Identifiable, Equatable {
    let id = UUID()
    let memoName: String

    var message: String {
        "\"\(memoName)\" was saved and is ready to use when you create or edit a task."
    }
}
