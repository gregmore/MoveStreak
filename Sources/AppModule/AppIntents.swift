import Foundation
import AppIntents

enum AppIntentKeys {
    static let totalPoints = "totalPoints"
    static let dailyChallengeJSON = "dailyChallengeJSON"
    
    static let waterIntake = "waterIntake"
    static let waterGoal = "waterGoal"
    static let lastWaterDate = "lastWaterDate"
    static let waterCheckInDate = "waterCheckInDate"
    static let waterPointsDate = "waterPointsDate"
    static let waterPointsAwardedCount = "waterPointsAwardedCount"
    static let waterGoalBonusDate = "waterGoalBonusDate"
}

struct AppDateKey {
    static func todayString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.string(from: Date())
    }
}

struct IntentDailyChallenge: Codable {
    var id = UUID()
    var title: String
    var targetPoints: Int
    var currentPoints: Int
    var isCompleted: Bool
}

enum HydrationStore {
    static func applyDelta(glasses delta: Int) -> (current: Int, goal: Int) {
        let defaults = UserDefaults.standard
        let today = AppDateKey.todayString()
        
        let goal = max(1, defaults.integer(forKey: AppIntentKeys.waterGoal))
        var intake = defaults.integer(forKey: AppIntentKeys.waterIntake)
        
        let lastWaterDate = defaults.string(forKey: AppIntentKeys.lastWaterDate) ?? ""
        if lastWaterDate != today {
            intake = 0
            defaults.set(today, forKey: AppIntentKeys.lastWaterDate)
        }
        
        let pointsDate = defaults.string(forKey: AppIntentKeys.waterPointsDate) ?? ""
        if pointsDate != today {
            defaults.set(today, forKey: AppIntentKeys.waterPointsDate)
            defaults.set(0, forKey: AppIntentKeys.waterPointsAwardedCount)
            defaults.set("", forKey: AppIntentKeys.waterGoalBonusDate)
        }
        
        let clamped = min(max(0, intake + delta), 15)
        defaults.set(clamped, forKey: AppIntentKeys.waterIntake)
        defaults.set(today, forKey: AppIntentKeys.waterCheckInDate)
        
        reconcileHydrationPoints(today: today, goal: goal, currentIntake: clamped)
        
        return (clamped, goal)
    }
    
    private static func reconcileHydrationPoints(today: String, goal: Int, currentIntake: Int) {
        let defaults = UserDefaults.standard
        
        let awarded = defaults.integer(forKey: AppIntentKeys.waterPointsAwardedCount)
        let deltaGlasses = currentIntake - awarded
        if deltaGlasses != 0 {
            defaults.set(currentIntake, forKey: AppIntentKeys.waterPointsAwardedCount)
            let newTotal = max(0, defaults.integer(forKey: AppIntentKeys.totalPoints) + deltaGlasses)
            defaults.set(newTotal, forKey: AppIntentKeys.totalPoints)
            updateChallengeProgress(points: deltaGlasses)
        }
        
        let bonusDate = defaults.string(forKey: AppIntentKeys.waterGoalBonusDate) ?? ""
        if currentIntake >= goal, bonusDate != today {
            defaults.set(today, forKey: AppIntentKeys.waterGoalBonusDate)
            let newTotal = max(0, defaults.integer(forKey: AppIntentKeys.totalPoints) + 5)
            defaults.set(newTotal, forKey: AppIntentKeys.totalPoints)
            updateChallengeProgress(points: 5)
        } else if currentIntake < goal, bonusDate == today {
            defaults.set("", forKey: AppIntentKeys.waterGoalBonusDate)
            let newTotal = max(0, defaults.integer(forKey: AppIntentKeys.totalPoints) - 5)
            defaults.set(newTotal, forKey: AppIntentKeys.totalPoints)
            updateChallengeProgress(points: -5)
        }
    }
    
    private static func updateChallengeProgress(points: Int) {
        let defaults = UserDefaults.standard
        guard let json = defaults.string(forKey: AppIntentKeys.dailyChallengeJSON),
              let data = json.data(using: .utf8),
              var challenge = try? JSONDecoder().decode(IntentDailyChallenge.self, from: data) else { return }
        
        let wasCompleted = challenge.isCompleted
        let updatedPoints = min(challenge.targetPoints, max(0, challenge.currentPoints + points))
        challenge.currentPoints = updatedPoints
        
        if updatedPoints >= challenge.targetPoints {
            if !wasCompleted {
                challenge.isCompleted = true
                let newTotal = max(0, defaults.integer(forKey: AppIntentKeys.totalPoints) + 20)
                defaults.set(newTotal, forKey: AppIntentKeys.totalPoints)
            }
        } else if wasCompleted {
            challenge.isCompleted = false
            let newTotal = max(0, defaults.integer(forKey: AppIntentKeys.totalPoints) - 20)
            defaults.set(newTotal, forKey: AppIntentKeys.totalPoints)
        }
        
        if let newData = try? JSONEncoder().encode(challenge),
           let newString = String(data: newData, encoding: .utf8) {
            defaults.set(newString, forKey: AppIntentKeys.dailyChallengeJSON)
        }
    }
}

struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Add water"
    static var description = IntentDescription("Log one or more glasses of water in MoveStreak.")
    
    @Parameter(title: "Glasses", default: 1)
    var glasses: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$glasses) glasses")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = HydrationStore.applyDelta(glasses: max(1, glasses))
        return .result(dialog: "Done. Hydration: \(result.current) of \(result.goal).")
    }
}

struct RemoveWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Remove water"
    static var description = IntentDescription("Adjust hydration by removing one or more glasses.")
    
    @Parameter(title: "Glasses", default: 1)
    var glasses: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$glasses) glasses")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = HydrationStore.applyDelta(glasses: -max(1, glasses))
        return .result(dialog: "OK. Hydration: \(result.current) of \(result.goal).")
    }
}

struct MoveStreakShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        let add = AppShortcut(
            intent: AddWaterIntent(),
            phrases: [
                "Add water with \(.applicationName)",
                "I drank water in \(.applicationName)",
                "Log water in \(.applicationName)"
            ],
            shortTitle: "Add water",
            systemImageName: "drop.fill"
        )
        
        let remove = AppShortcut(
            intent: RemoveWaterIntent(),
            phrases: [
                "Remove water with \(.applicationName)",
                "Adjust water in \(.applicationName)"
            ],
            shortTitle: "Remove water",
            systemImageName: "minus.circle"
        )
        
        return [add, remove]
    }
}
