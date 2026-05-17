import AVFoundation
import Foundation

/// Converts uploaded audio into a notification-compatible CAF.
enum AnshSchedulerVoiceMemoAudioConverter {
    private static let maxDurationSeconds: Double = 29

    nonisolated static func convertToNotificationCAF(
        sourceURL: URL,
        destinationURL: URL
    ) throws {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        let sourceFile = try AVAudioFile(forReading: sourceURL)
        guard sourceFile.length > 0 else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        let outputSampleRate = resolvedSampleRate(sourceFile.fileFormat.sampleRate)
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: outputSampleRate,
            channels: 1,
            interleaved: true
        ) else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        let maxInputFrames = AVAudioFramePosition(outputSampleRate * maxDurationSeconds)
        let framesToRead = min(sourceFile.length, maxInputFrames)
        guard framesToRead > 0, framesToRead <= AVAudioFrameCount.max else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        let inputFrameCount = AVAudioFrameCount(framesToRead)
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFile.processingFormat,
            frameCapacity: inputFrameCount
        ) else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        try sourceFile.read(into: inputBuffer, frameCount: inputFrameCount)
        guard inputBuffer.frameLength > 0 else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        let outputFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: outputFormat.settings,
            commonFormat: outputFormat.commonFormat,
            interleaved: outputFormat.isInterleaved
        )

        if sourceFile.processingFormat.isEqual(outputFormat) {
            try outputFile.write(from: inputBuffer)
        } else {
            try writeConvertedBuffer(
                inputBuffer: inputBuffer,
                outputFile: outputFile,
                inputFormat: sourceFile.processingFormat,
                outputFormat: outputFormat
            )
        }

        guard outputFile.length > 0 else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }
    }

    private nonisolated static func resolvedSampleRate(_ sourceRate: Double) -> Double {
        guard sourceRate.isFinite, sourceRate > 0 else { return 44_100 }
        return min(sourceRate, 48_000)
    }

    private nonisolated static func writeConvertedBuffer(
        inputBuffer: AVAudioPCMBuffer,
        outputFile: AVAudioFile,
        inputFormat: AVAudioFormat,
        outputFormat: AVAudioFormat
    ) throws {
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1_024
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: max(outputCapacity, 1_024)
        ) else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        var didProvideInput = false
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        var conversionError: NSError?
        _ = converter.convert(
            to: outputBuffer,
            error: &conversionError,
            withInputFrom: inputBlock
        )

        if let conversionError {
            throw conversionError
        }

        guard outputBuffer.frameLength > 0 else {
            throw AnshSchedulerVoiceMemoError.conversionFailed
        }

        try outputFile.write(from: outputBuffer)
    }
}
