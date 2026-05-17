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

    @discardableResult
    static func importCustomVoiceMemo(from sourceURL: URL, preferredName: String?) throws -> AnshSchedulerCustomVoiceMemo {
        let id = UUID()
        let cafFilename = "ansh-voice-\(id.uuidString).caf"
        let displayName = preferredName ?? sourceURL.deletingPathExtension().lastPathComponent

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let cafURL = try customSoundsDirectoryURL().appendingPathComponent(cafFilename)
        try convertAudioToNotificationCAF(sourceURL: sourceURL, destinationURL: cafURL)
        installCustomSoundInLibraryIfNeeded(filename: cafFilename)

        var memos = customVoiceMemos()
        let memo = AnshSchedulerCustomVoiceMemo(
            id: id,
            displayName: displayName,
            notificationSoundFilename: cafFilename
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

    private static func installCustomSoundInLibraryIfNeeded(filename: String) {
        guard let source = try? customSoundsDirectoryURL().appendingPathComponent(filename),
              FileManager.default.fileExists(atPath: source.path) else { return }
        guard let destination = try? librarySoundsDirectoryURL().appendingPathComponent(filename) else { return }
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.copyItem(at: source, to: destination)
    }

    private static func convertAudioToNotificationCAF(sourceURL: URL, destinationURL: URL) throws {
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: min(sourceFile.fileFormat.sampleRate, 48_000),
            channels: 1,
            interleaved: true
        )!
        let maxFrames = AVAudioFramePosition(48_000 * 29)
        let framesToRead = min(AVAudioFrameCount(sourceFile.length), AVAudioFrameCount(maxFrames))

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToRead) else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        try sourceFile.read(into: buffer, frameCount: framesToRead)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        let output = try AVAudioFile(forWriting: destinationURL, settings: format.settings)
        try output.write(from: buffer)
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
