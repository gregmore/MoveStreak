import Foundation

enum L10n {
    private static func s(_ key: String) -> String {
        en[key] ?? key
    }
    
    private static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: s(key), locale: Locale.current, arguments: args)
    }
    
    static var tabToday: String { s("tab.today") }
    static var tabDifficulty: String { s("tab.difficulty") }
    static var tabProfile: String { s("tab.profile") }
    static var navAppTitle: String { s("nav.appTitle") }
    
    static var settingsTitle: String { s("settings.title") }
    
    static var welcomeSubtitle: String { s("welcome.subtitle") }
    static var welcomeTagline: String { s("welcome.tagline") }
    static var welcomeNameLabel: String { s("welcome.nameLabel") }
    static var welcomeNamePlaceholder: String { s("welcome.namePlaceholder") }
    static var welcomeContinue: String { s("welcome.continue") }
    static var welcomeNotificationsTitle: String { s("welcome.notifications.title") }
    static var welcomeNotificationsBody: String { s("welcome.notifications.body") }
    static var welcomeNotificationsEnable: String { s("welcome.notifications.enable") }
    static var welcomeNotificationsSkip: String { s("welcome.notifications.skip") }
    static var welcomePrivacyNote: String { s("welcome.privacyNote") }
    
    static var commonDone: String { s("common.done") }
    
    static var welcomeIntroWhyTitle: String { s("welcome.intro.why.title") }
    static var welcomeIntroWhyBody: String { s("welcome.intro.why.body") }
    static var welcomeIntroTechTitle: String { s("welcome.intro.tech.title") }
    static var welcomeIntroTechBody: String { s("welcome.intro.tech.body") }
    
    static var homeHealthTipsTitle: String { s("home.healthTips.title") }
    static var homeHealthTipsSubtitle: String { s("home.healthTips.subtitle") }
    static var homeHealthTipsA11yLabel: String { s("home.healthTips.a11y.label") }
    static var homeHealthTipsA11yHint: String { s("home.healthTips.a11y.hint") }
    
    static var wellnessTipTitle: String { s("wellnessTip.title") }
    
    static var hydrationTitle: String { s("hydration.title") }
    static func hydrationValue(current: Int, goal: Int) -> String { f("hydration.value", current, goal) }
    static var hydrationCheckIn: String { s("hydration.checkIn") }
    static var hydrationEditA11yLabel: String { s("hydration.edit.a11y.label") }
    static var hydrationEditA11yHint: String { s("hydration.edit.a11y.hint") }
    static var hydrationRemoveOne: String { s("hydration.removeOne") }
    static var hydrationRemoveOneHint: String { s("hydration.removeOne.hint") }
    static var hydrationAddOne: String { s("hydration.addOne") }
    static var hydrationAddOneHint: String { s("hydration.addOne.hint") }
    static var hydrationGoalReached: String { s("hydration.goalReached") }
    static var hydrationPrompt: String { s("hydration.prompt") }
    static var hydrationGoalReachedA11y: String { s("hydration.goalReached.a11y") }
    static var hydrationCardA11yHint: String { s("hydration.card.a11y.hint") }
    static var hydrationA11yAddAction: String { s("hydration.a11y.addAction") }
    static var hydrationA11yRemoveAction: String { s("hydration.a11y.removeAction") }
    
    static var chartsWeeklyTitle: String { s("charts.weekly.title") }
    static var chartsWeeklySubtitle: String { s("charts.weekly.subtitle") }
    static var chartsWeeklyA11yLabel: String { s("charts.weekly.a11y.label") }
    static var chartsWeeklyA11yHint: String { s("charts.weekly.a11y.hint") }
    
    static var profileTitle: String { s("profile.title") }
    static var profileAchievements: String { s("profile.achievements") }
    static var profileSeeAll: String { s("profile.seeAll") }
    static var profileSettings: String { s("profile.settings") }
    static var profileFooter: String { s("profile.footer") }
    static var profileCurrentStreak: String { s("profile.currentStreak") }
    static var profileTotalXP: String { s("profile.totalXP") }
    static var profileDaysUnit: String { s("profile.daysUnit") }
    static var profilePointsUnit: String { s("profile.pointsUnit") }
    static var profileAdvancedStatsTitle: String { s("profile.advancedStats.title") }
    static var profileAdvancedStatsUnlockHint: String { s("profile.advancedStats.unlockHint") }
    static var profileAdvancedStatsLevel5: String { s("profile.advancedStats.level5") }
    static func profileAdvancedStatsMissingXP(_ xp: Int) -> String { f("profile.advancedStats.missingXP", xp) }
    static func profileLevel(_ level: Int) -> String { f("profile.level", level) }
    
    // Difficulty screen
    static var difficultyTitle: String { s("difficulty.title") }
    static var difficultySubtitle: String { s("difficulty.subtitle") }
    static var difficultyCurrentLabel: String { s("difficulty.current.label") }
    static var difficultyNextGoal: String { s("difficulty.nextGoal") }
    static var difficultyTowards: String { s("difficulty.towards") }
    static var difficultyNextLevel: String { s("difficulty.nextLevel") }
    static func difficultyXPToReach(_ xp: Int, _ mode: String) -> String { f("difficulty.xpToReach", xp, mode) }
    static func difficultyXPToNextLevel(_ xp: Int) -> String { f("difficulty.xpToNextLevel", xp) }
    static var difficultyHowItWorks: String { s("difficulty.howItWorks") }
    static var difficultyProTip: String { s("difficulty.proTip") }
    static var difficultyProTipBody: String { s("difficulty.proTip.body") }
    static var difficultyTipLabel: String { s("difficulty.tipLabel") }
    
    // Activity selection
    static var chooseWorkout: String { s("activity.chooseWorkout") }
    static var recommendedForYou: String { s("activity.recommendedForYou") }
    static var startWorkout: String { s("activity.startWorkout") }
    static func browseCatalog(_ count: Int) -> String { f("activity.browseCatalog", count) }
    static func activityXP(_ xp: Int) -> String { f("activity.xp", xp) }
    static var recommendedBadge: String { s("activity.recommended") }
    
    // Quick log
    static var quickLogTitle: String { s("quickLog.title") }
    static var quickLogMessage: String { s("quickLog.message") }
    static var quickLogButton: String { s("quickLog.button") }
    static var cancelButton: String { s("common.cancel") }
    
    // Settings
    static var settingsProfile: String { s("settings.profile") }
    static var settingsCustomizeAvatar: String { s("settings.customizeAvatar") }
    static var settingsPreferences: String { s("settings.preferences") }
    static var settingsData: String { s("settings.data") }
    static var settingsDeleteTitle: String { s("settings.delete.title") }
    static var settingsDeleteMessage: String { s("settings.delete.message") }
    static var settingsDeleteButton: String { s("settings.delete.button") }
    
    // Stats
    static var statsTitle: String { s("stats.title") }
    static var statsCompleted: String { s("stats.completed") }
    static var statsToday: String { s("stats.today") }
    static var statsWeekly: String { s("stats.weekly") }
    static func statsMinGoal(_ min: Int) -> String { f("stats.minGoal", min) }
    static func statsTotal(_ total: Int, _ avg: Int) -> String { f("stats.total", total, avg) }
    static var statsWeeklyActivity: String { s("stats.weeklyActivity") }
    static var statsWeeklyHint: String { s("stats.weeklyHint") }
    static func statsLevelXP(_ level: Int, _ xp: Int) -> String { f("stats.levelXP", level, xp) }
    
    // Badges
    static var badgeUnlocked: String { s("badge.unlocked") }
    static var badgeAwesome: String { s("badge.awesome") }
    static var badgeClose: String { s("badge.close") }
    
    // Timer
    static var timerStayFocused: String { s("timer.stayFocused") }
    static var timerReset: String { s("timer.reset") }
    static var timerAudio: String { s("timer.audio") }
    static var timerComplete: String { s("timer.complete") }
    static var timerLevelUp: String { s("timer.levelUp") }
    static var timerNewLevel: String { s("timer.newLevel") }
    static var timerCongrats: String { s("timer.congrats") }
    static var timerKeepGoing: String { s("timer.keepGoing") }
    
    // Health Tips
    static var healthTipsTitle: String { s("healthTips.title") }
    static var todayBadge: String { s("healthTips.today") }
    static var categoriesTitle: String { s("healthTips.categories") }
    
    // About screen
    static var aboutTitle: String { s("about.title") }
    static func aboutVersion(_ version: String, _ build: String) -> String { f("about.version", version, build) }
    static var aboutDescription: String { s("about.description") }
    static func aboutStreak(_ days: Int) -> String { f("about.streak", days) }
    static func aboutXP(_ xp: Int) -> String { f("about.xp", xp) }
    static func aboutLevel(_ level: Int) -> String { f("about.level", level) }
    static var aboutQuickStart: String { s("about.quickStart") }
    static var aboutOpenToday: String { s("about.openToday") }
    static var aboutOpenTodayDesc: String { s("about.openToday.desc") }
    static var aboutTrackWater: String { s("about.trackWater") }
    static var aboutTrackWaterDesc: String { s("about.trackWater.desc") }
    static var aboutCheckDifficulty: String { s("about.checkDifficulty") }
    static var aboutCheckDifficultyDesc: String { s("about.checkDifficulty.desc") }
    static var aboutFeatures: String { s("about.features") }
    static var aboutGuidedActivities: String { s("about.guidedActivities") }
    static var aboutGuidedActivitiesDesc: String { s("about.guidedActivities.desc") }
    static var aboutStreakProgress: String { s("about.streakProgress") }
    static var aboutStreakProgressDesc: String { s("about.streakProgress.desc") }
    static var aboutWellness: String { s("about.wellness") }
    static var aboutWellnessDesc: String { s("about.wellness.desc") }
    static var aboutPrivacy: String { s("about.privacy") }
    static var aboutOnDevice: String { s("about.onDevice") }
    static var aboutOnDeviceDesc: String { s("about.onDevice.desc") }
    static var aboutNoLogin: String { s("about.noLogin") }
    static var aboutNoLoginDesc: String { s("about.noLogin.desc") }
    static var aboutLocalStorage: String { s("about.localStorage") }
    static var aboutLocalStorageDesc: String { s("about.localStorage.desc") }
    static var aboutNotifications: String { s("about.notifications") }
    static var aboutAppSetting: String { s("about.appSetting") }
    static var aboutIOSPermission: String { s("about.iosPermission") }
    static var aboutOpenSettings: String { s("about.openSettings") }
    static var aboutPreferences: String { s("about.preferences") }
    static var aboutSounds: String { s("about.sounds") }
    static var aboutHaptics: String { s("about.haptics") }
    static var aboutSupport: String { s("about.support") }
    static var aboutSupportDesc: String { s("about.support.desc") }
    static var aboutCopyInfo: String { s("about.copyInfo") }
    static var aboutInfoCopied: String { s("about.infoCopied") }
    static var aboutActive: String { s("about.active") }
    static var aboutInactive: String { s("about.inactive") }
    static var aboutAuthorized: String { s("about.authorized") }
    static var aboutProvisional: String { s("about.provisional") }
    static var aboutEphemeral: String { s("about.ephemeral") }
    static var aboutDenied: String { s("about.denied") }
    static var aboutNotDetermined: String { s("about.notDetermined") }
    static var aboutUnknown: String { s("about.unknown") }
    
    private static let en: [String: String] = [
        "nav.appTitle": "MoveStreak",
        "tab.today": "Today",
        "tab.difficulty": "Difficulty",
        "tab.profile": "Profile",
        "settings.title": "Settings",
        "welcome.intro.why.title": "Why it exists",
        "welcome.intro.why.body": "MoveStreak helps fight sedentary study habits: small steps, every day.",
        "welcome.intro.tech.title": "Apple tech",
        "welcome.intro.tech.body": "Sensors (CoreMotion), native charts (Swift Charts), and Shortcuts (App Intents).",
        "welcome.subtitle": "Welcome to",
        "welcome.tagline": "A focused, active companion for your day.",
        "welcome.nameLabel": "Name",
        "welcome.namePlaceholder": "Enter your name",
        "welcome.continue": "Continue",
        "welcome.notifications.title": "Enable smart reminders",
        "welcome.notifications.body": "Turn on reminders to protect your streak. Confirm in the next system prompt.",
        "welcome.notifications.enable": "Enable",
        "welcome.notifications.skip": "Skip",
        "welcome.privacyNote": "Your name stays on device.",
        "common.done": "Done",
        "common.cancel": "Cancel",
        "home.healthTips.title": "Health Guidance",
        "home.healthTips.subtitle": "Discover routines for sleep, posture, and focus",
        "home.healthTips.a11y.label": "Health Guidance",
        "home.healthTips.a11y.hint": "Explore wellness categories",
        "wellnessTip.title": "Tip of the day",
        "hydration.checkIn": "Check-in",
        "hydration.edit.a11y.label": "Edit hydration",
        "hydration.edit.a11y.hint": "Opens hydration check-in",
        "charts.weekly.title": "Weekly minutes",
        "charts.weekly.subtitle": "Last 7 days",
        "profile.advancedStats.title": "Advanced stats",
        "profile.advancedStats.unlockHint": "Unlock to view weekly charts, calendar, and activity breakdown.",
        "profile.advancedStats.level5": "Level 5",
        "profile.advancedStats.missingXP": "Missing %d XP",
        "profile.level": "Level %d",
        "profile.achievements": "Achievements",
        "profile.seeAll": "See all",
        "profile.settings": "Settings",
        "profile.footer": "MoveStreak • Built with SwiftUI",
        "profile.title": "Profile",
        "hydration.title": "Hydration",
        "hydration.removeOne": "Remove one glass",
        "hydration.removeOne.hint": "Decreases the count by one glass",
        "hydration.addOne": "Add one glass",
        "hydration.addOne.hint": "Increases the count by one glass",
        "hydration.goalReached": "Goal reached!",
        "hydration.prompt": "Drink some water",
        "hydration.goalReached.a11y": "Goal reached",
        "hydration.value": "%d of %d glasses",
        "hydration.card.a11y.hint": "Swipe up or down to adjust.",
        "hydration.a11y.addAction": "Add a glass",
        "hydration.a11y.removeAction": "Remove a glass",
        "charts.weekly.a11y.label": "Weekly minutes chart",
        "charts.weekly.a11y.hint": "Shows minutes completed for each of the last 7 days.",
        "profile.currentStreak": "Current streak",
        "profile.totalXP": "Total XP",
        "profile.daysUnit": "DAYS",
        "profile.pointsUnit": "POINTS",
        
        // Difficulty screen
        "difficulty.title": "Difficulty",
        "difficulty.subtitle": "Adapts automatically to your level",
        "difficulty.current.label": "CURRENT DIFFICULTY",
        "difficulty.nextGoal": "Next goal",
        "difficulty.towards": "Towards %@",
        "difficulty.nextLevel": "Next level",
        "difficulty.xpToReach": "%d XP to reach %@",
        "difficulty.xpToNextLevel": "%d XP to the next level",
        "difficulty.howItWorks": "How it works",
        "difficulty.proTip": "Pro tip",
        "difficulty.proTip.body": "As you level up, difficulty increases automatically—no settings to tweak.",
        "difficulty.tipLabel": "Tip",
        
        // Activity selection
        "activity.chooseWorkout": "Choose a workout",
        "activity.recommendedForYou": "Recommended for you",
        "activity.startWorkout": "Start workout",
        "activity.browseCatalog": "Browse catalog (%d)",
        "activity.xp": "+%d XP",
        "activity.recommended": "RECOMMENDED",
        
        // Quick log
        "quickLog.title": "Quick log",
        "quickLog.message": "Already did it? Log it now for 50% of the points.",
        "quickLog.button": "Log",
        
        // Settings
        "settings.profile": "Profile",
        "settings.customizeAvatar": "Customize avatar",
        "settings.preferences": "Preferences",
        "settings.data": "Data",
        "settings.delete.title": "Delete user data?",
        "settings.delete.message": "This can't be undone. All progress and XP will be permanently lost. Continue?",
        "settings.delete.button": "Delete everything",
        
        // Stats
        "stats.title": "Stats",
        "stats.completed": "Completed",
        "stats.today": "Today",
        "stats.weekly": "WEEKLY",
        "stats.minGoal": "%d min goal",
        "stats.total": "%d min total • %d min/day",
        "stats.weeklyActivity": "Weekly activity",
        "stats.weeklyHint": "Bars above the dotted line indicate you reached your daily target.",
        "stats.levelXP": "Level %d",
        
        // Badges
        "badge.unlocked": "NEW BADGE UNLOCKED!",
        "badge.awesome": "Awesome!",
        "badge.close": "Close",
        
        // Timer
        "timer.stayFocused": "Stay focused",
        "timer.reset": "Reset",
        "timer.audio": "Audio",
        "timer.complete": "Complete session",
        "timer.levelUp": "LEVEL UP!",
        "timer.newLevel": "New level",
        "timer.congrats": "Congrats!",
        "timer.keepGoing": "Keep going",
        
        // Health Tips
        "healthTips.title": "Health tips",
        "healthTips.today": "TODAY",
        "healthTips.categories": "Categories",
        
        // About screen
        "about.title": "About",
        "about.version": "Version %@ (%@)",
        "about.description": "Small steps every day. Helps you build consistency with quick activities, clear goals, and rewards.",
        "about.streak": "Streak: %d days",
        "about.xp": "XP: %d",
        "about.level": "Level: %d",
        "about.quickStart": "Quick start",
        "about.openToday": "Open Today",
        "about.openToday.desc": "Choose an activity and earn XP",
        "about.trackWater": "Track water",
        "about.trackWater.desc": "Every glass is worth points",
        "about.checkDifficulty": "Check Difficulty",
        "about.checkDifficulty.desc": "Adapts to your level",
        "about.features": "What's inside",
        "about.guidedActivities": "Guided activities",
        "about.guidedActivities.desc": "Simple timers and quick routines",
        "about.streakProgress": "Streak and progress",
        "about.streakProgress.desc": "Levels, badges, and goals",
        "about.wellness": "Wellness",
        "about.wellness.desc": "Water, tips, and support",
        "about.privacy": "Privacy, simple",
        "about.onDevice": "Only on your iPhone",
        "about.onDevice.desc": "Data stays on device",
        "about.noLogin": "No login",
        "about.noLogin.desc": "No account or email needed",
        "about.localStorage": "Local storage",
        "about.localStorage.desc": "No third-party cloud",
        "about.notifications": "Notifications",
        "about.appSetting": "In-app setting",
        "about.iosPermission": "iOS permission",
        "about.openSettings": "Open iOS Settings",
        "about.preferences": "Preferences",
        "about.sounds": "Sounds",
        "about.haptics": "Haptic feedback",
        "about.support": "Help",
        "about.support.desc": "If something goes wrong: close and reopen the app. If needed, you can reset data from Settings.",
        "about.copyInfo": "Copy app info",
        "about.infoCopied": "Info copied",
        "about.active": "Active",
        "about.inactive": "Inactive",
        "about.authorized": "Authorized",
        "about.provisional": "Authorized (silent)",
        "about.ephemeral": "Temporary",
        "about.denied": "Denied",
        "about.notDetermined": "Not requested",
        "about.unknown": "Unknown"
    ]
}
