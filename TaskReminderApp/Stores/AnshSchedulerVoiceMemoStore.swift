import Foundation

@MainActor
final class AnshSchedulerVoiceMemoStore: ObservableObject {
    @Published private(set) var customMemos: [AnshSchedulerCustomVoiceMemo] = []
    @Published private(set) var isImporting = false
    @Published var lastImportError: String?
    @Published var importSuccessConfirmation: AnshSchedulerVoiceMemoImportConfirmation?

    init() {
        reload()
    }

    func reload() {
        customMemos = AnshSchedulerVoiceMemoService.customVoiceMemos()
        AnshSchedulerVoiceMemoService.prepareAllCustomSoundsForNotifications()
    }

    @discardableResult
    func importVoiceMemo(from url: URL, preferredName: String? = nil) async -> Bool {
        isImporting = true
        lastImportError = nil
        importSuccessConfirmation = nil
        defer { isImporting = false }

        let displayName = Self.resolvedDisplayName(url: url, preferredName: preferredName)
        let memoID = UUID()
        let cafFilename = "\(AnshSchedulerConstants.voiceMemoCAFFilePrefix)\(memoID.uuidString).caf"

        let stagingURL: URL
        do {
            stagingURL = try Self.copyToStagingURL(from: url)
        } catch {
            lastImportError = error.localizedDescription
            return false
        }

        do {
            let cafURL = try AnshSchedulerVoiceMemoService.cafDestinationURL(filename: cafFilename)
            try AnshSchedulerVoiceMemoAudioConverter.convertToNotificationCAF(
                sourceURL: stagingURL,
                destinationURL: cafURL
            )
            try? FileManager.default.removeItem(at: stagingURL)

            AnshSchedulerVoiceMemoService.registerImportedMemo(
                id: memoID,
                displayName: displayName,
                notificationSoundFilename: cafFilename
            )
            reload()
            importSuccessConfirmation = AnshSchedulerVoiceMemoImportConfirmation(memoName: displayName)
            return true
        } catch {
            try? FileManager.default.removeItem(at: stagingURL)
            lastImportError = error.localizedDescription
            return false
        }
    }

    func clearImportSuccessConfirmation() {
        importSuccessConfirmation = nil
    }

    func deleteVoiceMemo(id: UUID) {
        AnshSchedulerVoiceMemoService.deleteCustomVoiceMemo(id: id)
        reload()
    }

    private static func copyToStagingURL(from sourceURL: URL) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(AnshSchedulerConstants.voiceMemoImportTempDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let fileExtension = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let stagingURL = tempDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension(fileExtension)

        if FileManager.default.fileExists(atPath: stagingURL.path) {
            try FileManager.default.removeItem(at: stagingURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: stagingURL)
        return stagingURL
    }

    private static func resolvedDisplayName(url: URL, preferredName: String?) -> String {
        let trimmed = preferredName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return url.deletingPathExtension().lastPathComponent
    }
}
