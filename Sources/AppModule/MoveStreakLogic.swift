import SwiftUI
import UIKit
import AVFoundation
import UserNotifications
import Combine

// MARK: - View Models & Logic

/// StreakManager is the single source of truth for the app's data layer.
/// It coordinates streaks, points, history, onboarding state, and user preferences.
class StreakManager: ObservableObject {
    // Persistent state
    @AppStorage("streakDays") var streakDays: Int = 0 { didSet { objectWillChange.send() } }
    @AppStorage("totalPoints") var totalPoints: Int = 0 { didSet { objectWillChange.send() } }
    @AppStorage("lastActivityDate") var lastActivityDateString: String = "" { didSet { objectWillChange.send() } }
    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false { didSet { objectWillChange.send() } }
    @AppStorage("firstLaunchDate") var firstLaunchDateString: String = "" { didSet { objectWillChange.send() } }
    @AppStorage("historyJSON") var historyJSON: String = "{}"
    @AppStorage("minutesHistoryJSON") var minutesHistoryJSON: String = "{}"
    @AppStorage("userName") var userName: String = "Champion" { didSet { objectWillChange.send() } }
    @AppStorage("dailyChallengeJSON") var dailyChallengeJSON: String = "{}"
    @AppStorage("lastGraceUsed") var lastGraceUsedString: String = "" { didSet { objectWillChange.send() } }
    @AppStorage("unlockedBadgesJSON") var unlockedBadgesJSON: String = "[]"
    @AppStorage("activityStatsJSON") var activityStatsJSON: String = "{}"
    @AppStorage("lastChallengeDate") var lastChallengeDateString: String = ""
    
    // Hydration Tracker
    @AppStorage("waterIntake") var waterIntake: Int = 0 { didSet { objectWillChange.send() } }
    @AppStorage("waterGoal") var waterGoal: Int = 8 { didSet { objectWillChange.send() } }
    @AppStorage("lastWaterDate") var lastWaterDateString: String = ""
    @AppStorage("waterCheckInDate") var waterCheckInDateString: String = ""
    @AppStorage("waterPointsDate") var waterPointsDateString: String = ""
    @AppStorage("waterPointsAwardedCount") var waterPointsAwardedCount: Int = 0 { didSet { objectWillChange.send() } }
    @AppStorage("waterGoalBonusDate") var waterGoalBonusDateString: String = "" { didSet { objectWillChange.send() } }
    @AppStorage("lastStepsBonusDate") var lastStepsBonusDateString: String = ""
    
    // Avatar Storage
    @AppStorage("avatarIcon") var avatarIcon: String = "person.crop.circle.fill" { didSet { objectWillChange.send() } }
    @AppStorage("avatarColor") var avatarColorHex: String = "007AFF" { didSet { objectWillChange.send() } }
    
    // Difficulty Mode
    @AppStorage("difficultyMode") var difficultyModeString: String = "Beginner" { didSet { objectWillChange.send() } }
    
    // User Preferences
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true {
        didSet {
            objectWillChange.send()
            if notificationsEnabled {
                ensureNotificationsConfigured()
            } else {
                cancelNotifications()
            }
        }
    }
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true { didSet { objectWillChange.send() } }
    @AppStorage("soundEnabled") var soundEnabled: Bool = true {
        didSet {
            objectWillChange.send()
            if notificationsEnabled {
                scheduleNotifications()
            }
        }
    }
    @AppStorage("lastInsightShownDate") var lastInsightShownDateString: String = ""
    @AppStorage("lastDailyTipDate") var lastDailyTipDateString: String = ""
    
    // Published UI state
    @Published var badges: [Badge] = []
    @Published var activities: [Activity] = []
    @Published var completedActivityToday: Bool = false
    @Published var showConfetti: Bool = false
    @Published var dailyTip: String = ""
    @Published var selectedActivity: Activity? // For the detail sheet
    @Published var dailyChallenge: AppDailyChallenge?
    @Published var selectedBadge: Badge? // For detail view
    @Published var newlyUnlockedBadge: Badge? // For unlock celebration
    @Published var levelUpText: String? // For level up banner
    @Published var infoBannerText: String? // For informational banner (e.g., Grace Day)
    @Published var postActivityTip: EducationalTip?
    @Published var stepsToday: Int?
    @Published var showDailyChallengeComplete: Bool = false // For daily challenge celebration
    @Published var recommendedActivityID: UUID?
    
    private var stepCancellable: AnyCancellable?
    
    /// Human-friendly wellness tips, shown daily.
    let wellnessTips = [
        "4‑4‑4 breathing: inhale 4s • hold 4s • exhale 4s",
        "Drink a glass of water before coffee",
        "20‑20‑20 break: every 20 minutes, look 20 seconds at ~20 feet (6 m)",
        "5 minutes of morning mobility: neck, shoulders, hips",
        "Do 10 slow squats to wake up legs and circulation",
        "Walk 2 minutes after meals to support blood sugar",
        "Add a serving of vegetables at lunch or dinner",
        "Protein at breakfast helps keep energy steady",
        "Step goal: take a 5‑minute mini walk now",
        "Hydration: keep your bottle visible to remember to drink",
        "Back: squeeze shoulder blades 10 times, slow and controlled",
        "Posture: chin tuck (double‑chin) for 8 reps",
        "Wrists: gentle extensions and flexions for 30 seconds",
        "Calf stretch: 45 seconds per side (wall or step)",
        "Morning light: 10 minutes outdoors supports your body clock",
        "Sleep: screens off 30 minutes before bed",
        "Sleep: cool, dark room, short consistent routine",
        "Stress: longer exhale (e.g., 4s in, 6–8s out) for 2 minutes",
        "Single‑task: 10 minutes with no notifications",
        "Drink water before and after training",
        "Training: quality > quantity. Move well and slow",
        "Short on time: 3 minutes of plank (in chunks) still helps",
        "Core: 8 dead bugs per side, full control",
        "Back: glute bridge x12, hold 2s at the top",
        "Flexibility: stretch hips and hip flexors 45s per side",
        "Recovery: 5 minutes of breathing at the end of the day",
        "Mind: write down one good thing that happened today",
        "Nutrition: choose fruit as a snack when you can",
        "Salt: if you sweat a lot, replenish—but don’t overdo it",
        "Consistency: 70% is enough today. Tomorrow you’ll do more"
    ]
    
    // Date helpers
    private let calendar = Calendar.current
    static let df: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    init() {
        if firstLaunchDateString.isEmpty {
            firstLaunchDateString = normalizedDateString(for: Date())
        }

        stepCancellable = StepCounter.shared.$stepsToday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] steps in
                self?.stepsToday = steps
                if let s = steps {
                    self?.checkStepsBonus(s)
                }
            }
        
        refreshDailyTipIfNeeded()
        setupActivities()
        setupBadges()
        loadChallenge()
        checkDailyStatus()
        checkHydrationStatus()
        refreshDifficultyTier()
        refreshStepsToday()
        
        // Setup Notifications on launch
        if notificationsEnabled {
            ensureNotificationsConfigured()
        }
    }
    
    /// Persists any necessary state when the app transitions to background/inactive.
    /// Using @AppStorage means most state is persisted automatically, so this is a safe no-op.
    func persist() { }
    
    /// Returns the minutes history keyed by normalized date string ("yyyy-MM-dd").
    /// Used by CalendarHistoryView in ContentView.
    func getHistory() -> [String: Int] {
        loadMinutesHistory()
    }
    
    /// Returns aggregated activity stats (activity name -> completion count).
    /// Used by ActivityBreakdownView in ContentView.
    func getActivityStats() -> [String: Int] {
        loadActivityStats()
    }
    
    func completeOnboarding() {
        onboardingCompleted = true
        if firstLaunchDateString.isEmpty {
            firstLaunchDateString = normalizedDateString(for: Date())
        }
        generateDailyChallenge()
    }

    var memberSinceText: String {
        let joinDate = dateFromString(firstLaunchDateString) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return "Member since \(formatter.string(from: joinDate))"
    }

    func refreshStepsToday() {
        StepCounter.shared.refreshToday()
    }
    
    func startStepUpdates() {
        StepCounter.shared.startLiveUpdates()
    }
    
    func stopStepUpdates() {
        StepCounter.shared.stopLiveUpdates()
    }
    
    func refreshDailyTip() {
        let todayStr = normalizedDateString(for: Date())
        lastDailyTipDateString = todayStr
        dailyTip = TipEngine.shared.dailyTip(for: Date())?.body ?? (wellnessTips.randomElement() ?? dailyTip)
    }

    func refreshDailyTipIfNeeded() {
        let todayStr = normalizedDateString(for: Date())
        guard lastDailyTipDateString != todayStr || dailyTip.isEmpty else { return }
        lastDailyTipDateString = todayStr
        dailyTip = TipEngine.shared.dailyTip(for: Date())?.body ?? (wellnessTips.randomElement() ?? "Keep moving!")
    }

    var currentLevel: Int {
        (totalPoints / 50) + 1
    }

    var xpInCurrentLevel: Int {
        totalPoints % 50
    }
    
    var xpToNextLevel: Int {
        let remainder = totalPoints % 50
        return remainder == 0 ? 50 : (50 - remainder)
    }
    
    var progressToNextLevel: Double {
        Double(xpInCurrentLevel) / 50.0
    }
    
    var nextDifficultyName: String? {
        switch difficultyTier {
        case 0: return "Intermediate"
        case 1: return "Advanced"
        default: return nil
        }
    }

    var advancedInsightsUnlocked: Bool {
        currentLevel >= 5
    }
    
    var xpToUnlockAdvancedInsights: Int {
        let targetTotal = (5 - 1) * 50
        return max(0, targetTotal - totalPoints)
    }
    
    var progressToUnlockAdvancedInsights: Double {
        let startTotal = 0
        let targetTotal = (5 - 1) * 50
        let span = max(1, targetTotal - startTotal)
        let current = min(max(totalPoints - startTotal, 0), span)
        return Double(current) / Double(span)
    }
    
    var xpToNextDifficulty: Int? {
        guard let targetLevel = nextDifficultyTargetLevel else { return nil }
        let targetTotal = (targetLevel - 1) * 50
        return max(0, targetTotal - totalPoints)
    }
    
    var progressToNextDifficulty: Double? {
        guard let targetLevel = nextDifficultyTargetLevel,
              let startLevel = currentDifficultyStartLevel else { return nil }
        let startTotal = (startLevel - 1) * 50
        let targetTotal = (targetLevel - 1) * 50
        let span = max(1, targetTotal - startTotal)
        let current = min(max(totalPoints - startTotal, 0), span)
        return Double(current) / Double(span)
    }
    
    private var currentDifficultyStartLevel: Int? {
        switch difficultyTier {
        case 0: return 1
        case 1: return 4
        default: return 8
        }
    }
    
    private var nextDifficultyTargetLevel: Int? {
        switch difficultyTier {
        case 0: return 4
        case 1: return 8
        default: return nil
        }
    }
    
    private var difficultyTier: Int {
        switch currentLevel {
        case ...3: return 0
        case 4...7: return 1
        default: return 2
        }
    }
    
    func refreshDifficultyTier() {
        let newValue: String
        switch difficultyTier {
        case 0: newValue = "Beginner"
        case 1: newValue = "Intermediate"
        default: newValue = "Advanced"
        }
        if difficultyModeString != newValue {
            difficultyModeString = newValue
        }
    }

    func getCurrentWeekMinutesData() -> [(day: String, points: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }

        let minutesHistory = loadMinutesHistory()
        var dailyMinutes: [(day: String, points: Int)] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: weekInterval.start) else { continue }
            let dateString = StreakManager.df.string(from: date)
            let minutes = minutesHistory[dateString] ?? 0
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            dailyMinutes.append((day: dayName, points: minutes))
        }
        return dailyMinutes
    }
    
    /// Derived color from stored hex string.
    var avatarColor: Color {
        Color(hex: avatarColorHex)
    }
    
    /// Updates the avatar with a new icon and color.
    func updateAvatar(icon: String, colorHex: String) {
        avatarIcon = icon
        avatarColorHex = colorHex
        objectWillChange.send()
    }
    
    /// Resets user progress and returns the app to a fresh state.
    func resetProgress() {
        cancelNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        } else {
            let defaults = UserDefaults.standard
            for (key, _) in defaults.dictionaryRepresentation() {
                defaults.removeObject(forKey: key)
            }
            defaults.synchronize()
        }

        streakDays = 0
        totalPoints = 0
        lastActivityDateString = ""
        onboardingCompleted = false
        historyJSON = "{}"
        minutesHistoryJSON = "{}"
        dailyChallengeJSON = "{}"
        lastGraceUsedString = ""
        userName = "Champion"

        waterIntake = 0
        waterGoal = 8
        lastWaterDateString = ""
        waterCheckInDateString = ""
        waterPointsDateString = ""
        waterPointsAwardedCount = 0
        waterGoalBonusDateString = ""

        avatarIcon = "person.crop.circle.fill"
        avatarColorHex = "007AFF"

        difficultyModeString = "Beginner"

        notificationsEnabled = false
        hapticsEnabled = true
        soundEnabled = true
        lastInsightShownDateString = ""
        lastDailyTipDateString = ""

        badges = []
        activities = []
        completedActivityToday = false
        showConfetti = false
        selectedActivity = nil
        dailyChallenge = nil
        selectedBadge = nil
        newlyUnlockedBadge = nil
        levelUpText = nil
        infoBannerText = nil
        postActivityTip = nil
        stepsToday = nil

        setupActivities()
        setupBadges()
        generateDailyChallenge()
        dailyTip = wellnessTips.randomElement() ?? "Start fresh!"
        refreshDifficultyTier()
        objectWillChange.send()
    }
    
    /// Initializes the catalog of available activities.
    func setupActivities() {
        activities = [
            // Cardio (Aerobic)
            Activity(name_DE: "Walking", name: "Walking", icon: "figure.walk", colorHex: "34C759", description: "10 min brisk walk", duration: 600, xp: 5),
            Activity(name_DE: "Speed Walk", name: "Speed Walk", icon: "figure.walk.motion", colorHex: "34C759", description: "15 min fast pace", duration: 900, xp: 8),
            Activity(name_DE: "Trail Walk", name: "Trail Walk", icon: "figure.hiking", colorHex: "2ECC71", description: "20 min outdoors", duration: 1200, xp: 12),
            Activity(name_DE: "Running", name: "Running", icon: "figure.run", colorHex: "5856D6", description: "5 min jogging", duration: 300, xp: 10),
            Activity(name_DE: "Easy Run", name: "Easy Run", icon: "figure.run", colorHex: "5856D6", description: "15 min steady pace", duration: 900, xp: 16),
            Activity(name_DE: "Intervals", name: "Intervals", icon: "speedometer", colorHex: "6E56CF", description: "10 min run intervals", duration: 600, xp: 18),
            Activity(name_DE: "Sprints", name: "Sprints", icon: "bolt.fill", colorHex: "FF2D55", description: "6 x 20 sec sprint", duration: 240, xp: 14),
            Activity(name_DE: "Cycling", name: "Cycling", icon: "figure.outdoor.cycle", colorHex: "007AFF", description: "15 min ride", duration: 900, xp: 15),
            Activity(name_DE: "Spin Bike", name: "Spin Bike", icon: "bicycle", colorHex: "007AFF", description: "20 min indoor ride", duration: 1200, xp: 18),
            Activity(name_DE: "Elliptical", name: "Elliptical", icon: "figure.elliptical", colorHex: "0A84FF", description: "15 min low impact", duration: 900, xp: 14),
            Activity(name_DE: "Rowing", name: "Rowing", icon: "figure.rower", colorHex: "30B0C7", description: "10 min steady row", duration: 600, xp: 14),
            Activity(name_DE: "Stair Climb", name: "Stair Climb", icon: "figure.stair.stepper", colorHex: "FF9500", description: "8 min stairs", duration: 480, xp: 14),
            Activity(name_DE: "Jump Rope", name: "Jump Rope", icon: "figure.jumprope", colorHex: "FF9500", description: "3 min intense skipping", duration: 180, xp: 10),
            Activity(name_DE: "Jumping Jacks", name: "Jumping Jacks", icon: "figure.jumprope", colorHex: "FF9F0A", description: "5 min cardio burst", duration: 300, xp: 10),
            Activity(name_DE: "HIIT", name: "HIIT", icon: "flame.fill", colorHex: "FF3B30", description: "10 min full body HIIT", duration: 600, xp: 20),
            Activity(name_DE: "Swimming", name: "Swimming", icon: "figure.pool.swim", colorHex: "30B0C7", description: "20 min laps", duration: 1200, xp: 20),
            Activity(name_DE: "Open Water Swim", name: "Open Water Swim", icon: "figure.open.water.swim", colorHex: "32ADE6", description: "15 min relaxed swim", duration: 900, xp: 18),
            Activity(name_DE: "Shadow Boxing Cardio", name: "Shadow Boxing Cardio", icon: "figure.boxing", colorHex: "FF3B30", description: "8 min cardio combo", duration: 480, xp: 16),
            
            // Strength & Core
            Activity(name_DE: "Bodyweight", name: "Bodyweight", icon: "figure.strengthtraining.traditional", colorHex: "FF2D55", description: "Floor exercises", duration: 600, xp: 10),
            Activity(name_DE: "Push-ups", name: "Push-ups", icon: "figure.strengthtraining.traditional", colorHex: "FF2D55", description: "3 sets", duration: 300, xp: 10),
            Activity(name_DE: "Pull-ups", name: "Pull-ups", icon: "figure.strengthtraining.traditional", colorHex: "FF375F", description: "3 sets (assisted OK)", duration: 300, xp: 12),
            Activity(name_DE: "Dumbbells", name: "Dumbbells", icon: "dumbbell.fill", colorHex: "FF2D55", description: "15 min strength", duration: 900, xp: 18),
            Activity(name_DE: "Kettlebell", name: "Kettlebell", icon: "dumbbell.fill", colorHex: "FF6482", description: "10 min swings & squats", duration: 600, xp: 16),
            Activity(name_DE: "Resistance Band", name: "Resistance Band", icon: "figure.strengthtraining.functional", colorHex: "FF2D55", description: "12 min full body", duration: 720, xp: 14),
            Activity(name_DE: "Plank", name: "Plank", icon: "figure.core.training", colorHex: "5AC8FA", description: "2 min core hold", duration: 120, xp: 10),
            Activity(name_DE: "Side Plank", name: "Side Plank", icon: "figure.core.training", colorHex: "5AC8FA", description: "60 sec per side", duration: 120, xp: 10),
            Activity(name_DE: "Dead Bug", name: "Dead Bug", icon: "figure.core.training", colorHex: "64D2FF", description: "8 reps per side", duration: 240, xp: 8),
            Activity(name_DE: "Core Circuit", name: "Core Circuit", icon: "figure.core.training", colorHex: "64D2FF", description: "10 min core circuit", duration: 600, xp: 14),
            Activity(name_DE: "Squats", name: "Squats", icon: "figure.cross.training", colorHex: "AF52DE", description: "5 min leg workout", duration: 300, xp: 10),
            Activity(name_DE: "Lunges", name: "Lunges", icon: "figure.cross.training", colorHex: "AF52DE", description: "4 min alternating lunges", duration: 240, xp: 9),
            Activity(name_DE: "Glute Bridge", name: "Glute Bridge", icon: "figure.cross.training", colorHex: "BF5AF2", description: "3 sets glutes", duration: 360, xp: 10),
            Activity(name_DE: "Wall Sit", name: "Wall Sit", icon: "chair.fill", colorHex: "BF5AF2", description: "3 x 45 sec hold", duration: 180, xp: 10),
            Activity(name_DE: "Calisthenics", name: "Calisthenics", icon: "figure.cross.training", colorHex: "AF52DE", description: "15 min bodyweight circuit", duration: 900, xp: 18),
            Activity(name_DE: "Mountain Climbers", name: "Mountain Climbers", icon: "figure.cross.training", colorHex: "FF9500", description: "4 min cardio-core", duration: 240, xp: 10),
            Activity(name_DE: "Burpees", name: "Burpees", icon: "figure.cross.training", colorHex: "FF3B30", description: "3 min intense", duration: 180, xp: 12),
            Activity(name_DE: "Boxing", name: "Boxing", icon: "figure.boxing", colorHex: "FF3B30", description: "5 min shadow boxing", duration: 300, xp: 15),
            Activity(name_DE: "Kickboxing", name: "Kickboxing", icon: "figure.kickboxing", colorHex: "FF3B30", description: "10 min combos", duration: 600, xp: 18),
            Activity(name_DE: "Functional Training", name: "Functional Training", icon: "figure.strengthtraining.functional", colorHex: "FF2D55", description: "12 min full body", duration: 720, xp: 16),
            
            // Flexibility & Mind
            Activity(name_DE: "Stretching", name: "Stretching", icon: "figure.flexibility", colorHex: "FFCC00", description: "Full body stretch", duration: 300, xp: 5),
            Activity(name_DE: "Neck & Shoulders", name: "Neck & Shoulders", icon: "figure.flexibility", colorHex: "FFD60A", description: "5 min release", duration: 300, xp: 5),
            Activity(name_DE: "Hip Opener", name: "Hip Opener", icon: "figure.flexibility", colorHex: "FFD60A", description: "8 min mobility", duration: 480, xp: 7),
            Activity(name_DE: "Foam Rolling", name: "Foam Rolling", icon: "figure.flexibility", colorHex: "FFCC00", description: "10 min recovery", duration: 600, xp: 8),
            Activity(name_DE: "Yoga", name: "Yoga", icon: "figure.mind.and.body", colorHex: "A2845E", description: "10 min flow", duration: 600, xp: 10),
            Activity(name_DE: "Yoga - Power", name: "Yoga - Power", icon: "figure.mind.and.body", colorHex: "A2845E", description: "20 min flow", duration: 1200, xp: 18),
            Activity(name_DE: "Pilates", name: "Pilates", icon: "figure.pilates", colorHex: "A2845E", description: "15 min core & back", duration: 900, xp: 14),
            Activity(name_DE: "Tai Chi", name: "Tai Chi", icon: "figure.taichi", colorHex: "A2845E", description: "15 min gentle flow", duration: 900, xp: 12),
            Activity(name_DE: "Meditation", name: "Meditation", icon: "figure.mind.and.body", colorHex: "A2845E", description: "5 min mindfulness", duration: 300, xp: 5),
            Activity(name_DE: "Breathing", name: "Breathing", icon: "lungs.fill", colorHex: "5AC8FA", description: "3 min box breathing", duration: 180, xp: 5),
            
            // Sports
            Activity(name_DE: "Basketball", name: "Basketball", icon: "figure.basketball", colorHex: "FF9500", description: "20 min game", duration: 1200, xp: 20),
            Activity(name_DE: "Soccer", name: "Soccer", icon: "figure.soccer", colorHex: "34C759", description: "20 min game", duration: 1200, xp: 20),
            Activity(name_DE: "Tennis", name: "Tennis", icon: "figure.tennis", colorHex: "34C759", description: "20 min match", duration: 1200, xp: 18),
            Activity(name_DE: "Tanzen", name: "Dance", icon: "figure.dance", colorHex: "BF5AF2", description: "15 min fun", duration: 900, xp: 15),
            Activity(name_DE: "Golf", name: "Golf", icon: "figure.golf", colorHex: "34C759", description: "30 min driving range", duration: 1800, xp: 15),
            Activity(name_DE: "Martial Arts", name: "Martial Arts", icon: "figure.martial.arts", colorHex: "FF3B30", description: "20 min practice", duration: 1200, xp: 20),
            Activity(name_DE: "Climbing", name: "Climbing", icon: "figure.climbing", colorHex: "A2845E", description: "30 min bouldering", duration: 1800, xp: 22),
            Activity(name_DE: "Surfing", name: "Surfing", icon: "figure.surfing", colorHex: "32ADE6", description: "30 min session", duration: 1800, xp: 22),
            Activity(name_DE: "Skateboarding", name: "Skateboarding", icon: "figure.skating", colorHex: "FF9500", description: "20 min park", duration: 1200, xp: 18),
            Activity(name_DE: "Frisbee", name: "Frisbee", icon: "figure.disc.sports", colorHex: "007AFF", description: "15 min throwing", duration: 900, xp: 10),
            Activity(name_DE: "Volleyball", name: "Volleyball", icon: "figure.volleyball", colorHex: "FF9500", description: "20 min game", duration: 1200, xp: 18),
            Activity(name_DE: "Baseball", name: "Baseball", icon: "figure.baseball", colorHex: "007AFF", description: "20 min practice", duration: 1200, xp: 16),
            Activity(name_DE: "American Football", name: "American Football", icon: "figure.american.football", colorHex: "A2845E", description: "20 min drills", duration: 1200, xp: 18),
            Activity(name_DE: "Pickleball", name: "Pickleball", icon: "figure.pickleball", colorHex: "34C759", description: "20 min game", duration: 1200, xp: 18),
            Activity(name_DE: "Badminton", name: "Badminton", icon: "figure.badminton", colorHex: "BF5AF2", description: "20 min game", duration: 1200, xp: 16),
            Activity(name_DE: "Hockey", name: "Hockey", icon: "figure.hockey", colorHex: "007AFF", description: "20 min practice", duration: 1200, xp: 20),
            Activity(name_DE: "Handball", name: "Handball", icon: "figure.handball", colorHex: "FF9500", description: "20 min game", duration: 1200, xp: 20),
            Activity(name_DE: "Water Polo", name: "Water Polo", icon: "figure.water.fitness", colorHex: "32ADE6", description: "20 min game", duration: 1200, xp: 22),
            Activity(name_DE: "Sailing", name: "Sailing", icon: "sailboat.fill", colorHex: "32ADE6", description: "30 min on water", duration: 1800, xp: 15),
            Activity(name_DE: "Equestrian", name: "Equestrian", icon: "figure.equestrian.sports", colorHex: "A2845E", description: "30 min riding", duration: 1800, xp: 18),
            Activity(name_DE: "Fencing", name: "Fencing", icon: "figure.fencing", colorHex: "A2845E", description: "20 min bout", duration: 1200, xp: 18),
            Activity(name_DE: "Lacrosse", name: "Lacrosse", icon: "figure.lacrosse", colorHex: "FF9500", description: "20 min practice", duration: 1200, xp: 18),
            Activity(name_DE: "Rugby", name: "Rugby", icon: "figure.rugby", colorHex: "007AFF", description: "20 min practice", duration: 1200, xp: 20),
            Activity(name_DE: "Cricket", name: "Cricket", icon: "figure.cricket", colorHex: "34C759", description: "30 min practice", duration: 1800, xp: 16)
        ].sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Initializes the catalog of available badges.
    func setupBadges() {
        badges = [
            Badge(name: "First Steps", icon: "figure.walk", description: "Completed your first activity.", criteria: .firstActivity),
            Badge(name: "3-Day Streak", icon: "flame.fill", description: "Maintained a 3-day streak.", criteria: .streak(3)),
            Badge(name: "7-Day Streak", icon: "flame.fill", description: "Maintained a 7-day streak.", criteria: .streak(7)),
            Badge(name: "14-Day Streak", icon: "flame.fill", description: "Maintained a 14-day streak.", criteria: .streak(14)),
            Badge(name: "30-Day Streak", icon: "flame.fill", description: "Maintained a 30-day streak.", criteria: .streak(30)),
            Badge(name: "60-Day Streak", icon: "flame.fill", description: "Maintained a 60-day streak.", criteria: .streak(60)),
            Badge(name: "100-Day Streak", icon: "flame.fill", description: "Maintained a 100-day streak.", criteria: .streak(100)),
            Badge(name: "Perfect Week", icon: "calendar", description: "Completed an activity every day for a full week.", criteria: .perfectWeek),
            Badge(name: "Perfect Month", icon: "calendar", description: "Completed an activity every day for a full month.", criteria: .perfectMonth),
            Badge(name: "Point Collector", icon: "star.fill", description: "Earned 100 total points.", criteria: .points(100)),
            Badge(name: "Point Hoarder", icon: "star.fill", description: "Earned 500 total points.", criteria: .points(500)),
            Badge(name: "Point Tycoon", icon: "star.fill", description: "Earned 1000 total points.", criteria: .points(1000)),
            Badge(name: "Early Bird", icon: "sunrise.fill", description: "Completed an activity before 8 AM.", criteria: .timeOfDay(.morning)),
            Badge(name: "Night Owl", icon: "moon.fill", description: "Completed an activity after 9 PM.", criteria: .timeOfDay(.night)),
            Badge(name: "Weekend Warrior", icon: "sportscourt.fill", description: "Completed an activity on a Saturday or Sunday.", criteria: .weekendActivity),
            Badge(name: "Diversity", icon: "square.grid.2x2.fill", description: "Completed 5 different types of activities.", criteria: .activityCount(5)),
            Badge(name: "Explorer", icon: "square.grid.2x2.fill", description: "Completed 10 different types of activities.", criteria: .activityCount(10)),
            Badge(name: "Specialist", icon: "target", description: "Completed the same activity 10 times.", criteria: .specificActivityCount(10)),
            Badge(name: "Challenge Champion", icon: "bolt.fill", description: "Completed your first daily challenge.", criteria: .firstChallenge),
            Badge(name: "Challenge Conqueror", icon: "bolt.fill", description: "Completed 10 daily challenges.", criteria: .challengeCount(10)),
            Badge(name: "Hydration Hero", icon: "drop.fill", description: "Met your water goal for the first time.", criteria: .hydrationGoal),
            Badge(name: "Water Wizard", icon: "drop.fill", description: "Met your water goal 7 days in a row.", criteria: .hydrationStreak(7)),
            Badge(name: "Step Starter", icon: "figure.walk", description: "Reached 5,000 steps in a day.", criteria: .steps(5000)),
            Badge(name: "Step Superstar", icon: "figure.walk", description: "Reached 10,000 steps in a day.", criteria: .steps(10000)),
            Badge(name: "Level 5", icon: "arrow.up.circle.fill", description: "Reached Level 5.", criteria: .level(5)),
            Badge(name: "Level 10", icon: "arrow.up.circle.fill", description: "Reached Level 10.", criteria: .level(10)),
            Badge(name: "Level 20", icon: "arrow.up.circle.fill", description: "Reached Level 20.", criteria: .level(20))
        ].sorted { $0.name < $1.name }
        
        loadUnlockedBadges()
    }
    
    /// Checks the user's current status and updates streak, grace period, and other daily metrics.
    func checkDailyStatus() {
        let today = Date()
        let todayStr = normalizedDateString(for: today)
        
        // The streak flame is now tied to the daily challenge score
        completedActivityToday = (dailyChallenge?.currentPoints ?? 0) >= 50
        
        guard !lastActivityDateString.isEmpty else {
            return
        }
        
        let lastDate = dateFromString(lastActivityDateString) ?? Date.distantPast
        let daysSinceLast = daysBetween(lastDate, and: today)
        
        if daysSinceLast > 1 {
            let lastGraceDate = dateFromString(lastGraceUsedString)
            let todayStart = calendar.startOfDay(for: today)
            
            if let lastGrace = lastGraceDate, calendar.isDate(lastGrace, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: todayStart)!) {
                streakDays = 0
                infoBannerText = "Streak reset. Keep going!"
            } else {
                lastGraceUsedString = normalizedDateString(for: calendar.date(byAdding: .day, value: -1, to: today)!)
                infoBannerText = "Grace day used. Your streak is safe!"
            }
        }
        
        if lastChallengeDateString != todayStr {
            generateDailyChallenge()
        }
    }
    
    /// Records a completed activity, updates points and streak, and checks for badge unlocks.
    func completeActivity(_ activity: Activity, isQuickCheckIn: Bool = false, isTimeAttack: Bool = false) {
        let previousLevel = currentLevel
        let today = Date()
        let todayStr = normalizedDateString(for: today)
        
        totalPoints += activity.xp
        
        // Update daily challenge progress
        updateDailyChallengeProgress(newPoints: activity.xp)
        
        if lastActivityDateString.isEmpty {
            streakDays = 1
        } else {
            let lastDate = dateFromString(lastActivityDateString) ?? .distantPast
            let daysSince = daysBetween(lastDate, and: today)
            if daysSince == 1 {
                streakDays += 1
            } else if daysSince > 1 {
                streakDays = 1
            }
        }
        
        lastActivityDateString = todayStr
        completedActivityToday = true
        
        recordHistory(activity: activity, date: today)
        recordMinutes(activity: activity, date: today)
        updateActivityStats(activityName: activity.name)
        
        checkBadgeUnlocks(for: activity, at: today)
        
        if currentLevel > previousLevel {
            levelUpText = "Level Up! You're now Level \(currentLevel)"
            AudioManager.shared.feedback(sound: .success, haptic: .success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.levelUpText = nil
            }
        }
        
        if let challenge = dailyChallenge, challenge.activityName == activity.name, !challenge.isCompleted {
            completeDailyChallenge()
        }
        
        if let tip = TipEngine.shared.tipForActivity(name: activity.name) {
            postActivityTip = tip
        }
        
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showConfetti = false
        }
        
        objectWillChange.send()
    }
    
    /// Records activity history for the calendar view.
    private func recordHistory(activity: Activity, date: Date) {
        var history = loadHistory()
        let dateStr = normalizedDateString(for: date)
        
        if var dayHistory = history[dateStr] {
            dayHistory.append(activity.name)
            history[dateStr] = dayHistory
        } else {
            history[dateStr] = [activity.name]
        }
        
        saveHistory(history)
    }
    
    /// Records total minutes of activity for a given day.
    private func recordMinutes(activity: Activity, date: Date) {
        var minutesHistory = loadMinutesHistory()
        let dateStr = normalizedDateString(for: date)
        let minutes = Int(activity.duration / 60)
        
        minutesHistory[dateStr, default: 0] += minutes
        saveMinutesHistory(minutesHistory)
    }
    
    /// Updates statistics for a specific activity (e.g., how many times it's been completed).
    private func updateActivityStats(activityName: String) {
        var stats = loadActivityStats()
        stats[activityName, default: 0] += 1
        saveActivityStats(stats)
    }
    
    /// Checks all badge criteria and unlocks any that have been met.
    private func checkBadgeUnlocks(for activity: Activity, at completionTime: Date) {
        let locked = badges.filter { !$0.isUnlocked }
        
        for badge in locked {
            if badge.isEarned(by: self, activity: activity, at: completionTime) {
                unlockBadge(badge)
            }
        }
    }
    
    /// Marks a badge as unlocked and triggers a celebration.
    private func unlockBadge(_ badge: Badge) {
        if let index = badges.firstIndex(where: { $0.id == badge.id }) {
            badges[index].isUnlocked = true
            saveUnlockedBadges()
            
            newlyUnlockedBadge = badges[index]
            AudioManager.shared.feedback(sound: .success, haptic: .success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.newlyUnlockedBadge = nil
            }
        }
    }
    
    // MARK: - Hydration Methods
    
    /// Checks hydration status and resets intake if it's a new day.
    func checkHydrationStatus() {
        let todayStr = normalizedDateString(for: Date())
        if lastWaterDateString != todayStr {
            waterIntake = 0
            lastWaterDateString = todayStr
        }
        
        if waterCheckInDateString != todayStr {
            waterPointsAwardedCount = 0
        }
    }
    
    /// Adds a glass of water to the daily intake.
    func addWater() {
        let todayStr = normalizedDateString(for: Date())
        
        if lastWaterDateString != todayStr {
            waterIntake = 0
            lastWaterDateString = todayStr
        }
        
        // Check maximum limit of 15 glasses per day
        guard waterIntake < 15 else { return }
        
        waterIntake += 1
        
        if waterCheckInDateString != todayStr {
            waterPointsAwardedCount = 0
            waterCheckInDateString = todayStr
        }
        
        // Give 1 point for EVERY glass of water (no limit)
        totalPoints += 1
        waterPointsAwardedCount += 1
        // Update daily challenge progress for water points
        updateDailyChallengeProgress(newPoints: 1)
        
        if waterIntake >= waterGoal && waterGoalBonusDateString != todayStr {
            totalPoints += 5
            waterGoalBonusDateString = todayStr
            checkBadgeUnlocks(for: Activity(name_DE: "Hydration", name: "Hydration", icon: "", colorHex: "", description: "", duration: 0, xp: 0), at: Date())
            // Update daily challenge progress for hydration bonus
            updateDailyChallengeProgress(newPoints: 5)
        }
        
        objectWillChange.send()
    }
    
    /// Removes a glass of water from the daily intake.
    func removeWater() {
        let todayStr = normalizedDateString(for: Date())
        
        if lastWaterDateString != todayStr {
            waterIntake = 0
            lastWaterDateString = todayStr
        }
        
        guard waterIntake > 0 else { return }
        waterIntake -= 1
        
        if waterCheckInDateString != todayStr {
            waterPointsAwardedCount = 0
            waterCheckInDateString = todayStr
        }
        
        // Remove 1 point for each glass removed (no limit)
        totalPoints -= 1
        waterPointsAwardedCount -= 1
        // Update daily challenge progress for water points removal
        updateDailyChallengeProgress(newPoints: -1)
        
        if waterIntake < waterGoal && waterGoalBonusDateString == todayStr {
            totalPoints -= 5
            waterGoalBonusDateString = ""
            updateDailyChallengeProgress(newPoints: -5)
        }
        
        objectWillChange.send()
    }
    
    /// Skips today's hydration check-in without changing points.
    func skipHydrationCheckInToday() {
        let todayStr = normalizedDateString(for: Date())
        waterCheckInDateString = todayStr
        objectWillChange.send()
    }
    
    func setWaterIntakeForToday(_ glasses: Int) {
        let todayStr = normalizedDateString(for: Date())
        let desired = max(0, min(glasses, 15))
        
        if lastWaterDateString != todayStr {
            waterIntake = 0
            lastWaterDateString = todayStr
        }
        
        if waterCheckInDateString != todayStr {
            waterPointsAwardedCount = 0
            waterCheckInDateString = todayStr
        }
        
        // Give 1 point for each glass (no limit of 4)
        let delta = desired - waterPointsAwardedCount
        if delta != 0 {
            totalPoints += delta
            // Update daily challenge progress for water points change
            updateDailyChallengeProgress(newPoints: delta)
        }
        waterPointsAwardedCount = desired
        
        waterIntake = desired
        
        if waterIntake >= waterGoal && waterGoalBonusDateString != todayStr {
            totalPoints += 5
            waterGoalBonusDateString = todayStr
            checkBadgeUnlocks(for: Activity(name_DE: "Hydration", name: "Hydration", icon: "", colorHex: "", description: "", duration: 0, xp: 0), at: Date())
            // Update daily challenge progress for hydration bonus
            updateDailyChallengeProgress(newPoints: 5)
        } else if waterIntake < waterGoal && waterGoalBonusDateString == todayStr {
            // Remove hydration bonus if goal no longer met
            totalPoints -= 5
            waterGoalBonusDateString = ""
            // Update daily challenge progress for hydration bonus removal
            updateDailyChallengeProgress(newPoints: -5)
        }
        
        objectWillChange.send()
    }
    
    /// Calculates total points earned today from all sources (activities, water, steps)
    func calculateTodayPoints() -> Int {
        let todayStr = normalizedDateString(for: Date())
        var todayPoints = 0
        
        // Calculate points from today's activities
        let history = loadHistory()
        if let todayActivities = history[todayStr] {
            // Find each activity in the catalog and sum their XP
            for activityName in todayActivities {
                if let activity = activities.first(where: { $0.name == activityName }) {
                    todayPoints += activity.xp
                }
            }
        }
        
        // Add water points for today
        if waterCheckInDateString == todayStr {
            todayPoints += waterPointsAwardedCount // 1 point per glass of water
            
            // Add hydration bonus if achieved today
            if waterGoalBonusDateString == todayStr {
                todayPoints += 5
            }
        }
        
        // Add steps bonus if achieved today
        if lastStepsBonusDateString == todayStr {
            todayPoints += 10
        }
        
        return todayPoints
    }
    
    /// Updates the daily challenge progress with new points
    func updateDailyChallengeProgress(newPoints: Int) {
        guard var challenge = dailyChallenge else { return }
        
        let wasCompleted = challenge.isCompleted
        let updatedPoints = min(challenge.targetPoints, max(0, challenge.currentPoints + newPoints))
        challenge.currentPoints = updatedPoints
        
        if updatedPoints >= challenge.targetPoints {
            if !wasCompleted {
                challenge.isCompleted = true
                totalPoints += challenge.xpBonus
                showDailyChallengeComplete = true
                AudioManager.shared.feedback(sound: .success, haptic: .success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.showDailyChallengeComplete = false
                }
            }
        } else if wasCompleted {
            challenge.isCompleted = false
            totalPoints -= challenge.xpBonus
        }
        
        dailyChallenge = challenge
        saveChallenge(challenge)
        objectWillChange.send()
        
        // Refresh the daily status to update the streak flame
        checkDailyStatus()
    }
    
    // MARK: - Daily Challenge Methods
    
    /// Generates a new daily challenge for the user.
    func generateDailyChallenge() {
        let todayStr = normalizedDateString(for: Date())
        guard let randomActivity = activities.randomElement() else { return }
        
        // Calculate current daily points from today's activities
        let todayPoints = calculateTodayPoints()
        
        let challenge = AppDailyChallenge(
            activityName: randomActivity.name,
            activityIcon: randomActivity.icon,
            xpBonus: 20,
            date: todayStr,
            targetPoints: 50 // Set target to 50 points
        )
        
        // Update with today's current points
        var updatedChallenge = challenge
        updatedChallenge.currentPoints = todayPoints
        
        self.dailyChallenge = updatedChallenge
        lastChallengeDateString = todayStr
        saveChallenge(updatedChallenge)
    }
    
    /// Marks the daily challenge as completed and awards bonus points.
    func completeDailyChallenge() {
        guard var challenge = dailyChallenge, !challenge.isCompleted else { return }
        
        challenge.isCompleted = true
        totalPoints += challenge.xpBonus
        self.dailyChallenge = challenge
        saveChallenge(challenge)
        
        checkBadgeUnlocks(for: Activity(name_DE: "Daily Challenge", name: "Daily Challenge", icon: "", colorHex: "", description: "", duration: 0, xp: 0), at: Date())
        
        showDailyChallengeComplete = true
        AudioManager.shared.feedback(sound: .success, haptic: .success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showDailyChallengeComplete = false
        }
    }
    
    /// Loads the current daily challenge from storage.
    private func loadChallenge() {
        guard !dailyChallengeJSON.isEmpty,
              let data = dailyChallengeJSON.data(using: .utf8),
              let challenge = try? JSONDecoder().decode(AppDailyChallenge.self, from: data) else {
            generateDailyChallenge()
            return
        }
        
        let todayStr = normalizedDateString(for: Date())
        if challenge.date == todayStr {
            // Update challenge with current points
            var updatedChallenge = challenge
            updatedChallenge.currentPoints = calculateTodayPoints()
            
            self.dailyChallenge = updatedChallenge
            saveChallenge(updatedChallenge)
        } else {
            generateDailyChallenge()
        }
    }
    
    /// Saves the current daily challenge to storage.
    private func saveChallenge(_ challenge: AppDailyChallenge) {
        if let data = try? JSONEncoder().encode(challenge),
           let json = String(data: data, encoding: .utf8) {
            dailyChallengeJSON = json
        }
    }
    
    // MARK: - Steps Bonus
    
    /// Checks if the user has earned a step-based bonus.
    func checkStepsBonus(_ steps: Int) {
        let todayStr = normalizedDateString(for: Date())
        guard lastStepsBonusDateString != todayStr else { return }
        
        let bonusThreshold: Int
        switch difficultyModeString {
        case "Intermediate":
            bonusThreshold = 7500
        case "Advanced":
            bonusThreshold = 10000
        default:
            bonusThreshold = 5000
        }
        
        if steps >= bonusThreshold {
            totalPoints += 10
            lastStepsBonusDateString = todayStr
            infoBannerText = "+\(10) XP for hitting your step goal!"
            AudioManager.shared.feedback(sound: .success, haptic: .light)
            checkBadgeUnlocks(for: Activity(name_DE: "Steps", name: "Steps", icon: "", colorHex: "", description: "", duration: 0, xp: 0), at: Date())
            // Update daily challenge progress for steps bonus
            updateDailyChallengeProgress(newPoints: 10)
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadHistory() -> [String: [String]] {
        guard !historyJSON.isEmpty,
              let data = historyJSON.data(using: .utf8),
              let history = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return history
    }
    
    private func saveHistory(_ history: [String: [String]]) {
        if let data = try? JSONEncoder().encode(history),
           let json = String(data: data, encoding: .utf8) {
            historyJSON = json
        }
    }
    
    private func loadMinutesHistory() -> [String: Int] {
        guard !minutesHistoryJSON.isEmpty,
              let data = minutesHistoryJSON.data(using: .utf8),
              let history = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return history
    }
    
    private func saveMinutesHistory(_ history: [String: Int]) {
        if let data = try? JSONEncoder().encode(history),
           let json = String(data: data, encoding: .utf8) {
            minutesHistoryJSON = json
        }
    }
    
    private func loadUnlockedBadges() {
        guard !unlockedBadgesJSON.isEmpty,
              let data = unlockedBadgesJSON.data(using: .utf8),
              let unlockedIds = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return
        }
        
        for id in unlockedIds {
            if let index = badges.firstIndex(where: { $0.id == id }) {
                badges[index].isUnlocked = true
            }
        }
    }
    
    private func saveUnlockedBadges() {
        let unlockedIds = Set(badges.filter { $0.isUnlocked }.map { $0.id })
        if let data = try? JSONEncoder().encode(unlockedIds),
           let json = String(data: data, encoding: .utf8) {
            unlockedBadgesJSON = json
        }
    }
    
    func loadActivityStats() -> [String: Int] {
        guard !activityStatsJSON.isEmpty,
              let data = activityStatsJSON.data(using: .utf8),
              let stats = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return stats
    }
    
    private func saveActivityStats(_ stats: [String: Int]) {
        if let data = try? JSONEncoder().encode(stats),
           let json = String(data: data, encoding: .utf8) {
            activityStatsJSON = json
        }
    }
    
    // MARK: - Notification Management
    
    /// Ensures notifications are configured if the user has granted permission.
    func ensureNotificationsConfigured() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.scheduleNotifications()
                case .denied:
                    self.notificationsEnabled = false
                case .notDetermined:
                    self.requestNotificationPermission()
                @unknown default:
                    break
                }
            }
        }
    }
    
    /// Requests permission from the user to send notifications.
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if granted {
                    self.scheduleNotifications()
                }
            }
        }
    }
    
    /// Schedules daily reminder notifications.
    func scheduleNotifications() {
        guard notificationsEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "MoveStreak Reminder"
        content.body = "Don't forget to complete your activity today to keep your streak alive!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19 // 7 PM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancels all scheduled notifications.
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Date & Utility
    
    /// Normalizes a date to a "yyyy-MM-dd" string.
    private func normalizedDateString(for date: Date) -> String {
        StreakManager.df.string(from: date)
    }
    
    /// Converts a "yyyy-MM-dd" string to a Date object.
    private func dateFromString(_ dateString: String) -> Date? {
        StreakManager.df.date(from: dateString)
    }
    
    /// Calculates the number of days between two dates.
    private func daysBetween(_ start: Date, and end: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
    }
}

// MARK: - Data Models

/// Represents a single physical activity a user can perform.
public struct Activity: Identifiable, Codable {
    public var id = UUID()
    let name_DE: String?
    let name: String
    let icon: String
    let colorHex: String
    let description: String
    let duration: TimeInterval // in seconds
    let xp: Int
    
    var color: Color {
        Color(hex: colorHex)
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
    
    enum CodingKeys: String, CodingKey {
        case id, name_DE, name, icon, colorHex, description, duration, xp
    }

/// Represents an unlockable achievement.
public struct Badge: Identifiable, Codable, Hashable {
    public var id = UUID()
    let name: String
    let icon: String
    let description: String
    let criteria: BadgeCriteria
    var isUnlocked: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, description, criteria, isUnlocked
    }
    
    func isEarned(by manager: StreakManager, activity: Activity, at completionTime: Date) -> Bool {
        switch criteria {
        case .firstActivity:
            return true
        case .streak(let requiredDays):
            return manager.streakDays >= requiredDays
        case .points(let requiredPoints):
            return manager.totalPoints >= requiredPoints
        case .timeOfDay(let time):
            let hour = Calendar.current.component(.hour, from: completionTime)
            if time == .morning { return hour < 8 }
            if time == .night { return hour >= 21 }
            return false
        case .weekendActivity:
            let weekday = Calendar.current.component(.weekday, from: completionTime)
            return weekday == 1 || weekday == 7
        case .activityCount(let requiredCount):
            let stats = manager.loadActivityStats()
            return stats.keys.count >= requiredCount
        case .specificActivityCount(let requiredCount):
            let stats = manager.loadActivityStats()
            return (stats[activity.name] ?? 0) >= requiredCount
        case .firstChallenge:
            return activity.name == "Daily Challenge"
        case .challengeCount:
            // This needs to be tracked separately, perhaps in StreakManager
            return false
        case .hydrationGoal:
            return manager.waterIntake >= manager.waterGoal
        case .hydrationStreak:
            // This needs to be tracked separately
            return false
        case .steps(let requiredSteps):
            return (manager.stepsToday ?? 0) >= requiredSteps
        case .level(let requiredLevel):
            return manager.currentLevel >= requiredLevel
        case .perfectWeek, .perfectMonth:
            // More complex logic needed here, likely involving history analysis
            return false
        }
    }
}

/// Defines the criteria for earning a badge.
public enum BadgeCriteria: Codable, Hashable {
    case firstActivity
    case streak(Int)
    case points(Int)
    case timeOfDay(TimeCategory)
    case weekendActivity
    case activityCount(Int)
    case specificActivityCount(Int)
    case firstChallenge
    case challengeCount(Int)
    case hydrationGoal
    case hydrationStreak(Int)
    case steps(Int)
    case level(Int)
    case perfectWeek
    case perfectMonth
    
    public enum TimeCategory: Codable, Hashable {
        case morning, night
    }
}

/// Represents the user's daily challenge.
public struct AppDailyChallenge: Codable, Identifiable {
    public var id = UUID()
    let activityName: String
    let activityIcon: String
    let xpBonus: Int
    let date: String // "yyyy-MM-dd"
    var isCompleted: Bool = false
    var title: String = "Daily Challenge"
    var currentPoints: Int = 0
    var targetPoints: Int = 100
    
    var progress: Double {
        guard targetPoints > 0 else { return 0 }
        return Double(currentPoints) / Double(targetPoints)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, activityName, activityIcon, xpBonus, date, isCompleted, title, currentPoints, targetPoints
    }
}
