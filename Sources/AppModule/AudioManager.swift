import Foundation
import AVFoundation
import SwiftUI
import UIKit

/// A singleton class to manage audio playback for sound effects and haptic feedback.
/// This class ensures that sounds and haptics are handled consistently throughout the app.
class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    private init() { }
    
    /// Plays a sound file from the main bundle.
    /// - Parameter sound: The name of the sound file (without extension).
    func playSound(_ sound: String) {
        guard soundEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: sound, withExtension: "mp3") else {
            print("Error: Could not find sound file \(sound).mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error: Could not play sound file \(sound).mp3. \(error.localizedDescription)")
        }
    }
    
    /// Provides haptic feedback to the user.
    /// - Parameter type: The type of haptic feedback to generate.
    func playHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    /// A combined method to play a sound and trigger haptic feedback.
    /// - Parameters:
    ///   - sound: The name of the sound file to play.
    ///   - haptic: The type of haptic feedback to generate.
    func feedback(sound: Sound, haptic: Haptic) {
        playSound(sound.rawValue)
        playHaptic(haptic.value)
    }
    
    /// Triggers haptic feedback without playing a sound.
    /// - Parameter haptic: The type of haptic feedback to generate.
    func hapticFeedback(_ haptic: Haptic) {
        guard hapticsEnabled else { return }
        playHaptic(haptic.value)
    }

    func playSuccess() {
        feedback(sound: .success, haptic: .success)
    }

    func haptic(_ type: Haptic) {
        guard hapticsEnabled else { return }
        switch type {
        case .success, .warning, .error:
            let generator = UINotificationFeedbackGenerator()
            switch type {
            case .success:
                generator.notificationOccurred(.success)
            case .warning:
                generator.notificationOccurred(.warning)
            case .error:
                generator.notificationOccurred(.error)
            default:
                break
            }
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

extension AudioManager {
    enum Sound: String {
        case tap = "tap"
        case light = "light"
        case success = "success"
        case timerStop = "timerStop"
        case timerStart = "timerStart"
    }
    
    enum Haptic {
        case light, medium, heavy, success, warning, error, selection
        
        var value: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .light: return .success
            case .medium: return .warning
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            default: return .success
            }
        }
    }
}
