import AVFoundation
import Foundation
import UniformTypeIdentifiers
import UserNotifications

enum AnshSchedulerVoiceMemoService {
    private static var preferences: UserDefaults {
        AnshSchedulerPreferences.shared
    }

    static func customVoiceMemos() -> [AnshSchedulerCustomVoiceMemo] {
        migrateLegacyStorageIfNeeded()
        guard let data = preferences.data(forKey: AnshSchedulerConstants.customVoiceMemosStorageKey),
              let decoded = try? JSONDecoder().decode([AnshSchedulerCustomVoiceMemo].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveCustomVoiceMemos(_ memos: [AnshSchedulerCustomVoiceMemo]) {
        guard let data = try? JSONEncoder().encode(memos) else { return }
        preferences.set(data, forKey: AnshSchedulerConstants.customVoiceMemosStorageKey)
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
        ?? Bundle.main.url(
            forResource: preset.bundledMP3ResourceName,
            withExtension: preset.bundledMP3FileExtension
        )
    }

    static func previewURL(for selection: AnshSchedulerVoiceMemoSelection) -> URL? {
        playbackURL(for: selection)
    }

    /// URL for in-app playback (uses AVAudioSession playback to bypass silent mode).
    static func playbackURL(for selection: AnshSchedulerVoiceMemoSelection) -> URL? {
        switch selection {
        case .none:
            return nil
        case .preset(let preset):
            return bundledMP3URL(for: preset)
                ?? Bundle.main.url(forResource: preset.notificationSoundFilename, withExtension: nil)
        case .custom(let id):
            guard let memo = customVoiceMemos().first(where: { $0.id == id }) else { return nil }
            installCustomSoundInLibraryIfNeeded(filename: memo.notificationSoundFilename)
            if let libraryURL = try? librarySoundsDirectoryURL()
                .appendingPathComponent(memo.notificationSoundFilename),
               FileManager.default.fileExists(atPath: libraryURL.path) {
                return libraryURL
            }
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
        let directory = appSupport.appendingPathComponent(AnshSchedulerConstants.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(AnshSchedulerConstants.voiceMemosDirectoryName, isDirectory: true)
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
        migrateLegacyStorageIfNeeded()
        for preset in AnshSchedulerBundledVoiceMemo.allCases {
            installPresetSoundInLibraryIfNeeded(preset: preset)
        }
        for memo in customVoiceMemos() {
            installCustomSoundInLibraryIfNeeded(filename: memo.notificationSoundFilename)
        }
    }

    static func installPresetSoundInLibraryIfNeeded(preset: AnshSchedulerBundledVoiceMemo) {
        let filename = preset.notificationSoundFilename
        guard let source = Bundle.main.url(forResource: filename, withExtension: nil) else { return }
        guard let destination = try? librarySoundsDirectoryURL().appendingPathComponent(filename) else { return }
        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        try? FileManager.default.copyItem(at: source, to: destination)
    }

    /// One-time migration from pre-isolation voice memo paths and filenames.
    private static func migrateLegacyStorageIfNeeded() {
        guard !preferences.bool(forKey: AnshSchedulerConstants.legacyVoiceMemoStorageMigratedKey) else {
            return
        }

        migrateLegacyVoiceMemoDirectoryIfNeeded()
        migrateLegacyCAFFilenamesIfNeeded()
        preferences.set(true, forKey: AnshSchedulerConstants.legacyVoiceMemoStorageMigratedKey)
    }

    private static func migrateLegacyVoiceMemoDirectoryIfNeeded() {
        guard let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ),
              let newDirectory = try? customSoundsDirectoryURL() else {
            return
        }

        let oldDirectory = appSupport.appendingPathComponent(
            AnshSchedulerConstants.legacyVoiceMemosDirectoryName,
            isDirectory: true
        )
        guard FileManager.default.fileExists(atPath: oldDirectory.path),
              let files = try? FileManager.default.contentsOfDirectory(
                  at: oldDirectory,
                  includingPropertiesForKeys: nil
              ) else {
            return
        }

        for fileURL in files {
            let destination = newDirectory.appendingPathComponent(fileURL.lastPathComponent)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }
            try? FileManager.default.copyItem(at: fileURL, to: destination)
        }
    }

    private static func migrateLegacyCAFFilenamesIfNeeded() {
        guard let data = preferences.data(forKey: AnshSchedulerConstants.customVoiceMemosStorageKey),
              var memos = try? JSONDecoder().decode([AnshSchedulerCustomVoiceMemo].self, from: data) else {
            return
        }

        var changed = false
        for index in memos.indices {
            let filename = memos[index].notificationSoundFilename
            guard filename.hasPrefix(AnshSchedulerConstants.legacyVoiceMemoCAFFilePrefix) else { continue }

            let suffix = String(filename.dropFirst(AnshSchedulerConstants.legacyVoiceMemoCAFFilePrefix.count))
            let newFilename = AnshSchedulerConstants.voiceMemoCAFFilePrefix + suffix
            renameVoiceMemoFile(from: filename, to: newFilename)
            memos[index] = AnshSchedulerCustomVoiceMemo(
                id: memos[index].id,
                displayName: memos[index].displayName,
                notificationSoundFilename: newFilename
            )
            changed = true
        }

        if changed {
            saveCustomVoiceMemos(memos)
        }
    }

    private static func renameVoiceMemoFile(from oldFilename: String, to newFilename: String) {
        if let directory = try? customSoundsDirectoryURL() {
            let oldURL = directory.appendingPathComponent(oldFilename)
            let newURL = directory.appendingPathComponent(newFilename)
            if FileManager.default.fileExists(atPath: oldURL.path),
               !FileManager.default.fileExists(atPath: newURL.path) {
                try? FileManager.default.moveItem(at: oldURL, to: newURL)
            }
        }

        if let libraryDirectory = try? librarySoundsDirectoryURL() {
            let oldURL = libraryDirectory.appendingPathComponent(oldFilename)
            let newURL = libraryDirectory.appendingPathComponent(newFilename)
            if FileManager.default.fileExists(atPath: oldURL.path) {
                try? FileManager.default.removeItem(at: newURL)
                try? FileManager.default.moveItem(at: oldURL, to: newURL)
            }
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
