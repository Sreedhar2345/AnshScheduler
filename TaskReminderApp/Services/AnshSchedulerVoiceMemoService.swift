import AVFoundation
import Foundation
import UniformTypeIdentifiers
import UserNotifications

enum AnshSchedulerVoiceMemoService {
    private static let customMemosDefaultsKey =
        AnshSchedulerConstants.bundleIdentifier + ".customVoiceMemos.v1"

    private static var preferences: UserDefaults {
        UserDefaults(suiteName: AnshSchedulerConstants.userDefaultsSuiteName) ?? .standard
    }

    static func customVoiceMemos() -> [AnshSchedulerCustomVoiceMemo] {
        guard let data = preferences.data(forKey: customMemosDefaultsKey),
              let decoded = try? JSONDecoder().decode([AnshSchedulerCustomVoiceMemo].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveCustomVoiceMemos(_ memos: [AnshSchedulerCustomVoiceMemo]) {
        guard let data = try? JSONEncoder().encode(memos) else { return }
        preferences.set(data, forKey: customMemosDefaultsKey)
    }

    static func deleteCustomVoiceMemo(id: UUID) {
        var memos = customVoiceMemos()
        guard let index = memos.firstIndex(where: { $0.id == id }) else { return }
        let memo = memos[index]
        memos.remove(at: index)
        saveCustomVoiceMemos(memos)

        if let cafURL = try? customSoundsDirectoryURL().appendingPathComponent(memo.notificationSoundFilename) {
            try? FileManager.default.removeItem(at: cafURL)
        }
        if let libraryURL = try? librarySoundsDirectoryURL().appendingPathComponent(memo.notificationSoundFilename) {
            try? FileManager.default.removeItem(at: libraryURL)
        }
    }

    static func displayName(for selection: AnshSchedulerVoiceMemoSelection) -> String? {
        switch selection {
        case .none:
            return nil
        case .preset(let preset):
            return preset.displayName
        case .custom(let id):
            return customVoiceMemos().first(where: { $0.id == id })?.displayName
        }
    }

    static func notificationSound(for selection: AnshSchedulerVoiceMemoSelection) -> UNNotificationSound {
        switch selection {
        case .none:
            return .default
        case .preset(let preset):
            return UNNotificationSound(named: UNNotificationSoundName(preset.notificationSoundFilename))
        case .custom(let id):
            guard let memo = customVoiceMemos().first(where: { $0.id == id }) else {
                return .default
            }
            installCustomSoundInLibraryIfNeeded(filename: memo.notificationSoundFilename)
            return UNNotificationSound(named: UNNotificationSoundName(memo.notificationSoundFilename))
        }
    }

    static func notificationSoundFilename(for selection: AnshSchedulerVoiceMemoSelection) -> String? {
        switch selection {
        case .none:
            return nil
        case .preset(let preset):
            return preset.notificationSoundFilename
        case .custom(let id):
            return customVoiceMemos().first(where: { $0.id == id })?.notificationSoundFilename
        }
    }

    static func cafDestinationURL(filename: String) throws -> URL {
        try customSoundsDirectoryURL().appendingPathComponent(filename)
    }

    @discardableResult
    static func registerImportedMemo(
        id: UUID,
        displayName: String,
        notificationSoundFilename: String
    ) -> AnshSchedulerCustomVoiceMemo {
        installCustomSoundInLibraryIfNeeded(filename: notificationSoundFilename)

        var memos = customVoiceMemos()
        let memo = AnshSchedulerCustomVoiceMemo(
            id: id,
            displayName: displayName,
            notificationSoundFilename: notificationSoundFilename
        )
        memos.append(memo)
        saveCustomVoiceMemos(memos)
        return memo
    }

    static func bundledMP3URL(for preset: AnshSchedulerBundledVoiceMemo) -> URL? {
        Bundle.main.url(
            forResource: preset.bundledMP3ResourceName,
            withExtension: preset.bundledMP3FileExtension,
            subdirectory: "VoiceMemos"
        )
    }

    static func previewURL(for selection: AnshSchedulerVoiceMemoSelection) -> URL? {
        switch selection {
        case .none:
            return nil
        case .preset(let preset):
            return bundledMP3URL(for: preset)
        case .custom(let id):
            guard let memo = customVoiceMemos().first(where: { $0.id == id }) else { return nil }
            return try? customSoundsDirectoryURL().appendingPathComponent(memo.notificationSoundFilename)
        }
    }

    private static func customSoundsDirectoryURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport.appendingPathComponent("VoiceMemos", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func librarySoundsDirectoryURL() throws -> URL {
        let library = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let sounds = library.appendingPathComponent("Sounds", isDirectory: true)
        try FileManager.default.createDirectory(at: sounds, withIntermediateDirectories: true)
        return sounds
    }

    static func prepareAllCustomSoundsForNotifications() {
        for memo in customVoiceMemos() {
            installCustomSoundInLibraryIfNeeded(filename: memo.notificationSoundFilename)
        }
    }

    static func installCustomSoundInLibraryIfNeeded(filename: String) {
        guard let source = try? customSoundsDirectoryURL().appendingPathComponent(filename),
              FileManager.default.fileExists(atPath: source.path) else { return }
        guard let destination = try? librarySoundsDirectoryURL().appendingPathComponent(filename) else { return }
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.copyItem(at: source, to: destination)
    }

    nonisolated static func convertAudioToNotificationCAF(sourceURL: URL, destinationURL: URL) throws {
        try AnshSchedulerVoiceMemoAudioConverter.convertToNotificationCAF(
            sourceURL: sourceURL,
            destinationURL: destinationURL
        )
    }
}

enum AnshSchedulerVoiceMemoError: LocalizedError {
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Could not prepare this audio file for reminders."
        }
    }
}
