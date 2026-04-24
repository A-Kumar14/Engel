//
//  RecordingManager.swift
//  engel
//

import AVFoundation
import Foundation
import Observation

enum RecordingState: Equatable {
    case idle
    case permissionDenied
    case recording(secondsElapsed: Int)
    case processing
    case done(audioURL: URL)
    case failed(message: String)

    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.permissionDenied, .permissionDenied),
             (.processing, .processing):
            return true
        case let (.recording(a), .recording(b)):
            return a == b
        case let (.done(a), .done(b)):
            return a == b
        case let (.failed(a), .failed(b)):
            return a == b
        default:
            return false
        }
    }
}

@Observable
@MainActor
final class RecordingManager: NSObject {
    var state: RecordingState = .idle
    private(set) var secondsElapsed: Int = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?

    private static let maxDuration: Int = 30

    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            state = .failed(message: "Could not activate audio session.")
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.record()
            audioRecorder = recorder
            recordingURL = url
            secondsElapsed = 0
            state = .recording(secondsElapsed: 0)
            startTimer()
        } catch {
            state = .failed(message: "Could not start recording.")
        }
    }

    func stopRecording() -> URL? {
        stopTimer()
        audioRecorder?.stop()
        audioRecorder = nil

        let url = recordingURL
        recordingURL = nil
        return url
    }

    func reset() {
        stopTimer()
        audioRecorder?.stop()
        audioRecorder = nil
        recordingURL = nil
        secondsElapsed = 0
        state = .idle
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.secondsElapsed += 1
                self.state = .recording(secondsElapsed: self.secondsElapsed)

                if self.secondsElapsed >= Self.maxDuration {
                    self.autoStop()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func autoStop() {
        guard let url = stopRecording() else {
            state = .failed(message: "Recording file not found.")
            return
        }
        state = .done(audioURL: url)
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                state = .failed(message: "Recording was interrupted.")
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            state = .failed(message: error?.localizedDescription ?? "Encoding error.")
        }
    }
}
