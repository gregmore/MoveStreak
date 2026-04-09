import Foundation
import CoreHaptics

final class HapticsEngine {
    static let shared = HapticsEngine()
    
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    
    func prepare() -> Bool {
        guard supportsHaptics else { return false }
        if engine != nil { return true }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] _ in
                self?.engine = nil
            }
            engine?.resetHandler = { [weak self] in
                self?.engine = nil
                _ = self?.prepare()
            }
            try engine?.start()
            return true
        } catch {
            engine = nil
            return false
        }
    }
    
    func playTap() -> Bool {
        playTransient(intensity: 0.35, sharpness: 0.75)
    }
    
    func playSuccess() -> Bool {
        guard supportsHaptics else { return false }
        guard prepare() else { return false }
        let events: [CHHapticEvent] = [
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.55),
                .init(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0.0),
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 0.8),
                .init(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: 0.12),
            .init(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: 1.0),
                .init(parameterID: .hapticSharpness, value: 0.7)
            ], relativeTime: 0.26)
        ]
        return playPattern(events: events, duration: 0.35)
    }
    
    func playHeavy() -> Bool {
        playTransient(intensity: 0.9, sharpness: 0.35)
    }
    
    private func playTransient(intensity: Float, sharpness: Float) -> Bool {
        guard supportsHaptics else { return false }
        guard prepare() else { return false }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        return playPattern(events: [event], duration: 0.1)
    }
    
    private func playPattern(events: [CHHapticEvent], duration: TimeInterval) -> Bool {
        guard supportsHaptics else { return false }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                _ = self
            }
            return true
        } catch {
            return false
        }
    }
}
