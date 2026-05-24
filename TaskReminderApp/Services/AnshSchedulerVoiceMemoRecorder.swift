import AVFoundation
import Foundation

@MainActor
final class AnshSchedulerVoiceMemoRecorder: NSObject, ObservableObject {
    static let maxRecordingSeconds: TimeInterval = 29

    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var outputURL: URL?
    private var elapsedTimer: Timer?

    func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws {
        guard !isRecording else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AnshSchedulerConstants.voiceMemoRecordingTempPrefix)\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        audioRecorder = recorder
        outputURL = url
        isRecording = true
        elapsedSeconds = 0
        startElapsedTimer()
    }

    func stopRecording() -> URL? {
        guard isRecording else { return outputURL }

        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return outputURL
    }

    func discardRecording() {
        if isRecording {
            audioRecorder?.stop()
        }
        audioRecorder = nil
        isRecording = false
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        if let outputURL {
            try? FileManager.default.removeItem(at: outputURL)
        }
        outputURL = nil
        elapsedSeconds = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.elapsedSeconds += 0.25
                if self.elapsedSeconds >= Self.maxRecordingSeconds {
                    _ = self.stopRecording()
                }
            }
        }
    }
}
