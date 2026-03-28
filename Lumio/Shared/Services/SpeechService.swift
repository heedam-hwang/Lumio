import AVFAudio
import Foundation

struct AudioGuidanceAlert: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class SpeechService {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(text: String, language: String = "en-US") {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    func audioGuidanceMessage() -> String? {
        let session = AVAudioSession.sharedInstance()
        let isVolumeOff = session.outputVolume <= 0.001
        let isMuted: Bool

        if #available(iOS 26.0, *) {
            isMuted = session.isOutputMuted
        } else {
            isMuted = false
        }

        guard isMuted || isVolumeOff else { return nil }
        return "소리가 꺼져 있습니다. 무음 모드나 볼륨 설정을 확인해 주세요."
    }

    func speakIfAvailable(text: String, language: String = "en-US") -> AudioGuidanceAlert? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        if let message = audioGuidanceMessage() {
            return AudioGuidanceAlert(message: message)
        }

        speak(text: text, language: language)
        return nil
    }
}
