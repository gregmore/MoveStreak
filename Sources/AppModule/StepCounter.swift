import Foundation

#if canImport(CoreMotion)
import CoreMotion
#endif

final class StepCounter: ObservableObject {
    static let shared = StepCounter()
    
    @Published private(set) var stepsToday: Int? = nil
    @Published private(set) var isAvailable: Bool = false
#if canImport(CoreMotion)
    @Published private(set) var authorizationStatus: CMAuthorizationStatus = .notDetermined
#endif
    
#if canImport(CoreMotion)
    private let pedometer = CMPedometer()
    private var isUpdating = false
#endif
    
    private init() {
#if canImport(CoreMotion)
        isAvailable = CMPedometer.isStepCountingAvailable()
        authorizationStatus = CMPedometer.authorizationStatus()
#else
        isAvailable = false
#endif
    }
    
    func refreshToday() {
#if canImport(CoreMotion)
        authorizationStatus = CMPedometer.authorizationStatus()
        guard isAvailable else {
            Task { @MainActor in
                self.stepsToday = nil
            }
            return
        }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = Date()
        
        pedometer.queryPedometerData(from: start, to: end) { [weak self] data, _ in
            guard let self else { return }
            Task { @MainActor in
                self.stepsToday = data?.numberOfSteps.intValue
            }
        }
#else
        Task { @MainActor in
            self.stepsToday = nil
        }
#endif
    }
    
    func startLiveUpdates() {
#if canImport(CoreMotion)
        authorizationStatus = CMPedometer.authorizationStatus()
        guard isAvailable, !isUpdating else { return }
        isUpdating = true
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            guard let self else { return }
            Task { @MainActor in
                self.stepsToday = data?.numberOfSteps.intValue
            }
        }
#endif
    }
    
    func stopLiveUpdates() {
#if canImport(CoreMotion)
        isUpdating = false
        pedometer.stopUpdates()
#endif
    }
}
