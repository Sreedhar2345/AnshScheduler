import AVFoundation
import Foundation

/// Plays task voice memos through the speaker, bypassing the silent switch while the app plays audio.
@MainActor
final class AnshSchedulerVoiceMemoPlaybackService {
    static let shared = AnshSchedulerVoiceMemoPlaybackService()

    private var player: AVAudioPlayer?

    private init() {}

    /// Preview playback from the task editor (explicit user action, not a scheduled reminder).
    func playVoiceMemo(for selection: AnshSchedulerVoiceMemoSelection) {
        guard selection != .none, let url = AnshSchedulerVoiceMemoService.playbackURL(for: selection) else {
            return
        }
        play(url: url)
    }

    /// Plays a voice memo only when `scheduledFireDate` matches the task's reminder time window.
    @discardableResult
    func playScheduledReminderVoiceMemo(
        voiceMemoStorageID: String?,
        fireKey: String,
        scheduledFireDate: Date
    ) -> Bool {
        guard isWithinScheduledFireWindow(scheduledFireDate) else {
            return false
        }

        guard let voiceMemoStorageID,
              !voiceMemoStorageID.isEmpty,
              let selection = AnshSchedulerVoiceMemoSelection(storageIdentifier: voiceMemoStorageID),
              selection != .none else {
            return false
        }

        guard AnshSchedulerReminderPlaybackDedup.shouldPlay(fireKey: fireKey) else {
            return false
        }

        guard let url = AnshSchedulerVoiceMemoService.playbackURL(for: selection) else {
            return false
        }

        play(url: url)
        return true
    }

    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func isWithinScheduledFireWindow(_ scheduledFireDate: Date) -> Bool {
        abs(scheduledFireDate.timeIntervalSinceNow)
            <= AnshSchedulerConstants.reminderVoiceMemoPlaybackWindowSeconds
    }

    private func play(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            try? session.overrideOutputAudioPort(.speaker)

            player?.stop()
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.volume = 1.0
            audioPlayer.prepareToPlay()
            guard audioPlayer.play() else { return }
            player = audioPlayer
        } catch {
            // Scheduled and preview playback fail quietly if audio cannot start.
        }
    }
}
