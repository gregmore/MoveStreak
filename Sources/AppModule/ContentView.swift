import SwiftUI
import UIKit
import AVFoundation
import Charts

// MARK: - Main Content View
/// Root container view for the application.
/// Hosts the main pages and presents onboarding when needed.
struct ContentView: View {
    @StateObject private var manager = StreakManager()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showHydrationCheckIn = false
    @State private var showDailyTipSheet = false
    @AppStorage("lastDailyTipSheetShownDate") private var lastDailyTipSheetShownDateString: String = ""
    @State private var selectedTab = 0
    @State private var tabOffset: CGFloat = 0 // Continuous offset from 0.0 to 2.0
    @State private var isDraggingPager = false
    @State private var isRootTabBarHidden = false
    @State private var tabHapticsArmed = false
    
    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background
                .ignoresSafeArea()
            
            InstagramPager3(selectedIndex: $selectedTab, tabOffset: $tabOffset, isDragging: $isDraggingPager, isRootTabBarHidden: $isRootTabBarHidden) {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    DailyActivityView(manager: manager, showHydrationCheckIn: $showHydrationCheckIn, showDailyTipSheet: $showDailyTipSheet, isRootTabBarHidden: $isRootTabBarHidden)
                }
            } page1: {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    ChallengesView(manager: manager)
                }
            } page2: {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    ProfileView(manager: manager)
                }
            }
            
            if manager.showDailyChallengeComplete {
                DailyChallengeCompletionSheet(manager: manager)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isRootTabBarHidden {
                GlassBottomTabBar(selectedIndex: $selectedTab, tabOffset: $tabOffset)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !manager.onboardingCompleted },
            set: { _ in }
        )) {
            WelcomeView(manager: manager)
        }
        .onAppear {
            manager.refreshStepsToday()
            manager.startStepUpdates()
            presentDailyTipIfNeeded()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                manager.refreshStepsToday()
                manager.startStepUpdates()
                presentDailyTipIfNeeded()
            } else {
                manager.stopStepUpdates()
                manager.persist()
            }
        }
        .onChange(of: manager.onboardingCompleted) { oldState, completed in
            let wasCompleted = oldState
            guard completed else { return }
            if !wasCompleted {
                selectedTab = 0
                isRootTabBarHidden = false
                lastDailyTipSheetShownDateString = StreakManager.df.string(from: Date())
                showDailyTipSheet = false
                return
            }
            manager.refreshStepsToday()
            presentDailyTipIfNeeded()
        }
        .onChange(of: selectedTab) { oldTab, newValue in
            if tabHapticsArmed {
                AudioManager.shared.feedback(sound: .tap, haptic: .light)
            } else {
                tabHapticsArmed = true
            }
            presentDailyTipIfNeeded()
        }
        .sheet(isPresented: $showHydrationCheckIn) {
            HydrationCheckInSheet(manager: manager)
        }
        .sheet(isPresented: $showDailyTipSheet, onDismiss: markDailyTipSeen) {
            EducationalTipSheet(tip: TipEngine.shared.dailyTip(for: Date()) ?? EducationalTip(id: "daily_fallback", title: L10n.wellnessTipTitle, body: manager.dailyTip, tags: [])) {
                showDailyTipSheet = false
            }
        }

    }
    
    private func updateHydrationCheckInPresentation() {}
    
    private func presentDailyTipIfNeeded() {
        guard selectedTab == 0 else { return }
        guard manager.onboardingCompleted else { return }
        guard !showHydrationCheckIn else { return }
        guard !showDailyTipSheet else { return }
        guard manager.postActivityTip == nil else { return }
        
        let today = StreakManager.df.string(from: Date())
        guard lastDailyTipSheetShownDateString != today else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard selectedTab == 0 else { return }
            guard manager.onboardingCompleted else { return }
            guard !showHydrationCheckIn else { return }
            guard !showDailyTipSheet else { return }
            guard manager.postActivityTip == nil else { return }
            
            // Disabilitato l'apertura automatica del tip del giorno
            // showDailyTipSheet = true
        }
    }
    
    private func markDailyTipSeen() {
        lastDailyTipSheetShownDateString = StreakManager.df.string(from: Date())
    }
}

// MARK: - Instagram Style Pager

private struct InstagramPager3<Page0: View, Page1: View, Page2: View>: View {
    @Binding var selectedIndex: Int
    @Binding var tabOffset: CGFloat
    @Binding var isDragging: Bool
    @Binding var isRootTabBarHidden: Bool
    
    @ViewBuilder let page0: () -> Page0
    @ViewBuilder let page1: () -> Page1
    @ViewBuilder let page2: () -> Page2
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            HStack(spacing: 0) {
                page0().frame(width: width)
                page1().frame(width: width)
                page2().frame(width: width)
            }
            .offset(x: -tabOffset * width)
            .contentShape(Rectangle())
            .onChange(of: selectedIndex) { oldIndex, newValue in
                if !isDragging {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        tabOffset = CGFloat(newValue)
                    }
                }
            }
        }
    }
}

private struct GlassBottomTabBar: View {
    @Binding var selectedIndex: Int
    @Binding var tabOffset: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let height: CGFloat = 64 // Slightly taller for a more premium feel
            let padding: CGFloat = 6
            let segmentWidth = max(1, (totalWidth - (padding * 2)) / 3)
            let clampedHighlightX = min(2 * segmentWidth, max(0, tabOffset * segmentWidth))
            
            ZStack(alignment: .leading) {
                // Main Glass Background
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.cardStroke.opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 12)
                
                // Animated Premium Highlight
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.15),
                                Color.blue.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: segmentWidth, height: height - (padding * 2))
                    .padding(padding)
                    .offset(x: clampedHighlightX)
                
                // Content Layer
                HStack(spacing: 0) {
                    tabLabel(title: L10n.tabToday, icon: "figure.walk", activeIcon: "figure.walk.circle.fill", index: 0)
                    tabLabel(title: L10n.tabDifficulty, icon: "trophy", activeIcon: "trophy.fill", index: 1)
                    tabLabel(title: L10n.tabProfile, icon: "person", activeIcon: "person.fill", index: 2)
                }
                .padding(padding)
            }
            .frame(height: height)
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let locationX = value.location.x - padding
                        let progress = locationX / segmentWidth - 0.5
                        let clampedProgress = min(2, max(0, progress))
                        tabOffset = clampedProgress
                    }
                    .onEnded { value in
                        let targetIndex = Int(tabOffset.rounded())
                        let finalizedIndex = min(2, max(0, targetIndex))
                        
                        let speed = abs(value.velocity.width)
                        let animateResponse = speed > 500 ? 0.25 : 0.35
                        
                        withAnimation(.spring(response: animateResponse, dampingFraction: 0.82)) {
                            tabOffset = CGFloat(finalizedIndex)
                            selectedIndex = finalizedIndex
                        }
                        
                        AudioManager.shared.feedback(sound: .tap, haptic: .light)
                    }
            )
        }
        .frame(height: 64)
    }
    
    private func tabLabel(title: String, icon: String, activeIcon: String, index: Int) -> some View {
        let isActive = selectedIndex == index
        
        return VStack(spacing: 4) {
            Image(systemName: isActive ? activeIcon : icon)
                .font(.system(size: 18, weight: isActive ? .bold : .medium))
                .foregroundStyle(isActive ? Color.blue : Color.secondary.opacity(0.8))
                .symbolEffect(.bounce, value: isActive)
            
            Text(title)
                .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .rounded))
                .foregroundStyle(isActive ? Color.blue : Color.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectedIndex = index
                tabOffset = CGFloat(index)
            }
            AudioManager.shared.feedback(sound: .tap, haptic: .light)
        }
    }
}

// MARK: - View Models & Logic
// Moved to MoveStreakLogic.swift

struct ChallengesView: View {
    @ObservedObject var manager: StreakManager
    @State private var showProTip = false
    
    let modes = [
        ("Beginner", "Start easy: lighter goals and more tolerance.", "leaf.fill", Color.green, "Levels 1–3"),
        ("Intermediate", "Balanced challenge: higher goals and faster progression.", "flame.fill", Color.orange, "Levels 4–7"),
        ("Advanced", "High challenge: tougher goals and less room for error.", "bolt.fill", Color.purple, "Level 8+")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.difficultyTitle)
                                    .appTitle()
                                Text(L10n.difficultySubtitle)
                                    .appBody()
                            }
                            
                            Spacer()
                            
                            // Pro Tip Button
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    showProTip.toggle()
                                }
                                AudioManager.shared.feedback(sound: .tap, haptic: .light)
                            } label: {
                                Image(systemName: showProTip ? "lightbulb.fill" : "lightbulb")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(showProTip ? .white : .yellow)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        ZStack {
                                            if showProTip {
                                                Color.yellow
                                            } else {
                                                Color.yellow.opacity(0.12)
                                            }
                                        }
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.yellow.opacity(showProTip ? 0.3 : 0), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        if showProTip {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.difficultyProTip)
                                        .appHeadline()
                                    Text(L10n.difficultyProTipBody)
                                        .appBody()
                                }
                                
                                Spacer()
                                
                                CopyButton(text: L10n.difficultyProTipBody, color: .yellow)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Active Mode Banner
                        ZStack {
                            LinearGradient(colors: [getModeColor(manager.difficultyModeString).opacity(0.8), getModeColor(manager.difficultyModeString)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.difficultyCurrentLabel)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(manager.difficultyModeString)
                                        .font(.title)
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                    
                                    Text("Level \(manager.currentLevel)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                Spacer()
                                Image(systemName: getModeIcon(manager.difficultyModeString))
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(24)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous))
                        .shadow(color: AppTheme.shadow(getModeColor(manager.difficultyModeString), intensity: 0.18), radius: 14, x: 0, y: 10)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(L10n.difficultyNextGoal)
                                    .appHeadline()
                                Spacer()
                                if let next = manager.nextDifficultyName {
                                    Text("Towards \(next)")
                                        .appPill(color: getModeColor(next))
                                } else {
                                    Text(L10n.difficultyNextLevel)
                                        .appPill(color: .blue)
                                }
                            }
                            
                            if let next = manager.nextDifficultyName,
                               let remaining = manager.xpToNextDifficulty,
                               let progress = manager.progressToNextDifficulty {
                                Text(L10n.difficultyXPToReach(remaining, next))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ProgressView(value: progress)
                                    .tint(getModeColor(next))
                            } else {
                                Text(L10n.difficultyXPToNextLevel(manager.xpToNextLevel))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ProgressView(value: manager.progressToNextLevel)
                                    .tint(.blue)
                            }
                        }
                        .appCard(accent: manager.nextDifficultyName.map { getModeColor($0) } ?? .blue)
                        .padding(.horizontal)
                        
                        // Mode Selection Grid
                        VStack(alignment: .leading, spacing: 16) {
                            Text(L10n.difficultyHowItWorks)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 14) {
                                ForEach(modes, id: \.0) { mode in
                                    ModeCard(
                                        title: mode.0,
                                        description: mode.1,
                                        icon: mode.2,
                                        color: mode.3,
                                        range: mode.4,
                                        isSelected: manager.difficultyModeString == mode.0
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
    
    func getModeIcon(_ name: String) -> String {
        modes.first(where: { $0.0 == name })?.2 ?? "leaf.fill"
    }
    
    func getModeColor(_ name: String) -> Color {
        modes.first(where: { $0.0 == name })?.3 ?? .green
    }
}

struct ModeCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let range: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(range)
                    .appPill(color: .secondary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appHeadline()
                Text(description)
                    .appBody()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .top)
        .appCard(accent: isSelected ? .blue : nil)
    }
}

// MARK: - Shop View Removed




struct ActivitiesListView: View {
    @ObservedObject var manager: StreakManager
    @Binding var isRootTabBarHidden: Bool
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if manager.recommendedActivityID != nil {
                        Text(L10n.recommendedForYou)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(manager.activities) { activity in
                            ActivityCard(
                                activity: activity,
                                manager: manager,
                                isRecommended: activity.id == manager.recommendedActivityID
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
        .navigationBarTitle(L10n.chooseWorkout)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $manager.selectedActivity) { activity in
            ProTimerView(activity: activity, manager: manager)
        }
        .onAppear {
            isRootTabBarHidden = true
        }
    }
}

struct DailyActivityView: View {
    @ObservedObject var manager: StreakManager
    @Binding var showHydrationCheckIn: Bool
    @Binding var showDailyTipSheet: Bool
    @Binding var isRootTabBarHidden: Bool
    
    // Time-based Greeting Logic
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hi"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.cardBackground
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Header
                    HStack {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(manager.completedActivityToday ? "Great!" : "\(greeting), \(manager.userName)")
                                .appTitle()
                                .minimumScaleFactor(0.7)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text(manager.completedActivityToday ? "You crushed it today." : "Ready to move?")
                                .appBody()
                        }
                        Spacer()
                        
                        // Streak Badge
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundColor(manager.completedActivityToday ? .orange : .secondary.opacity(0.3))
                            Text("\(manager.streakDays)")
                                .appTitle(size: 22)
                                .foregroundColor(manager.completedActivityToday ? .primary : .secondary.opacity(0.5))
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: AppTheme.shadow(intensity: 0.10), radius: 14, x: 0, y: 10)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current streak")
                        .accessibilityValue("\(manager.streakDays) days")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            WellnessTipCard(tip: manager.dailyTip) {
                                showDailyTipSheet = true
                            }
                            StepsCard(manager: manager)
                            
                            NavigationLink(destination: HealthTipsView(manager: manager, isRootTabBarHidden: $isRootTabBarHidden)) {
                                HStack(spacing: 14) {
                                    Image(systemName: "heart.text.square.fill")
                                        .font(.title2)
                                        .foregroundColor(.pink)
                                        .frame(width: 44, height: 44)
                                        .background(Color.pink.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(L10n.homeHealthTipsTitle)
                                            .appHeadline()
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        Text(L10n.homeHealthTipsSubtitle)
                                            .appBody()
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.3))
                                }
                                .appCard(accent: .pink)
                            }
                            .accessibilityLabel(Text(L10n.homeHealthTipsA11yLabel))
                            .accessibilityHint(Text(L10n.homeHealthTipsA11yHint))
                            
                            if let challenge = manager.dailyChallenge {
                                ChallengeCard(challenge: challenge)
                            }
                            
                            // Hydration Tracker
                            WaterTrackerCard(manager: manager, showHydrationCheckIn: $showHydrationCheckIn)
                            
                            // Activity Entry Point
                            NavigationLink(destination: ActivitiesListView(manager: manager, isRootTabBarHidden: $isRootTabBarHidden)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: "figure.run")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.startWorkout)
                                            .appHeadline()
                                        Text(L10n.browseCatalog(manager.activities.count))
                                            .appBody()
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                .appCard(accent: .blue)
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: isRootTabBarHidden ? 0 : 96)
                    }
                }
                
                if let text = manager.levelUpText {
                    LevelUpView(levelText: text) {
                        withAnimation { manager.levelUpText = nil }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
                
                if let text = manager.infoBannerText {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "shield.checkerboard")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text(text)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: AppTheme.shadow(intensity: 0.12), radius: 18, x: 0, y: 12)
                        .padding(.bottom, 110)
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                manager.infoBannerText = nil
                            }
                        }
                    }
                }
                
                if manager.showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                
                if let badge = manager.newlyUnlockedBadge {
                    BadgeUnlockOverlay(badge: badge) {
                        manager.newlyUnlockedBadge = nil
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                isRootTabBarHidden = false
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ActivityCard: View {
    let activity: Activity
    @ObservedObject var manager: StreakManager
    let isRecommended: Bool
    @State private var showQuickCheckInAlert = false
    
    init(activity: Activity, manager: StreakManager, isRecommended: Bool = false) {
        self.activity = activity
        self.manager = manager
        self.isRecommended = isRecommended
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                manager.selectedActivity = activity
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        Image(systemName: activity.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(colors: [activity.color, activity.color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(color: activity.color.opacity(0.4), radius: 5, x: 0, y: 3)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.gray.opacity(0.2))
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(activity.name)
                            .appHeadline()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
    
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(activity.durationFormatted)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(L10n.activityXP(activity.xp))
                                .font(.caption)
                                .fontWeight(.bold)
                                .appPill(color: activity.color)
                        }
                        .foregroundColor(.secondary)
                }
                .frame(height: 140)
                .appCard(accent: isRecommended ? activity.color : nil)
                
                if isRecommended {
                    Text(L10n.recommendedBadge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(activity.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .offset(x: 10, y: -10)
                        .shadow(radius: 2)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(action: {
                showQuickCheckInAlert = true
            }) {
                Label("Quick log (half points)", systemImage: "checkmark.circle")
            }
        }
        .alert(isPresented: $showQuickCheckInAlert) {
            Alert(
                title: Text(L10n.quickLogTitle),
                message: Text(L10n.quickLogMessage),
                primaryButton: .default(Text(L10n.quickLogButton), action: {
                    manager.completeActivity(activity, isQuickCheckIn: true)
                }),
                secondaryButton: .cancel(Text(L10n.cancelButton))
            )
        }
        .accessibilityLabel("\(isRecommended ? "Recommended: " : "")\(activity.name), \(activity.durationFormatted)")
        .accessibilityHint("Double tap to start, long press for quick log")
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ProfileView: View {
    @ObservedObject var manager: StreakManager
    @State private var showAvatarEditor = false
    @State private var showSettings = false
    @State private var showAllBadges = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Professional Header
                        ProfileHeaderView(manager: manager, showEditor: $showAvatarEditor)
                        
                        // 2. Highlights (Streak & XP)
                        HStack(spacing: 16) {
                            InsightCard(
                                title: L10n.profileCurrentStreak,
                                value: "\(manager.streakDays)",
                                unit: L10n.profileDaysUnit,
                                icon: "flame.fill",
                                color: .orange
                            )
                            InsightCard(
                                title: L10n.profileTotalXP,
                                value: "\(manager.totalPoints)",
                                unit: L10n.profilePointsUnit,
                                icon: "star.fill",
                                color: .yellow
                            )
                        }
                        .padding(.horizontal)
                        
                        // 3. Level Progress (Integrated)
                        LevelProgressBar(totalPoints: manager.totalPoints)
                            .padding(.horizontal)
                        
                        WeeklyProgressChart(data: manager.getCurrentWeekMinutesData())
                            .padding(.horizontal)
                        
                        CalendarHistoryView(history: manager.getHistory())
                            .padding(.horizontal)
                        
                        ActivityBreakdownView(stats: manager.getActivityStats(), activities: manager.activities)
                            .padding(.horizontal)
                        
                        // 7. Achievements
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(L10n.profileAchievements)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: { showAllBadges = true }) {
                                    Text(L10n.profileSeeAll)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .background(AppTheme.cardBackground)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(manager.badges) { badge in
                                        BadgeView(badge: badge, manager: manager)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 8. Settings Entry Point
                        Button(action: { showSettings = true }) {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                
                                Text(L10n.profileSettings)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .appCard(accent: .gray)
                            .padding(.horizontal)
                        }
                        
                        // Footer
                        EmptyView()
                    }
                    .padding(.top)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
            }
            .navigationTitle(L10n.profileTitle)
            .navigationBarHidden(true)
            .sheet(item: $manager.selectedBadge) { badge in
                BadgeDetailView(badge: badge) {
                    manager.selectedBadge = nil
                }
            }
            .sheet(isPresented: $showAvatarEditor) {
                ProfileEditorView(manager: manager)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(manager: manager)
            }
            .sheet(isPresented: $showAllBadges) {
                AllBadgesView(manager: manager)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct SettingsView: View {
    @ObservedObject var manager: StreakManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showAvatarEditor = false
    @State private var showResetAlert = false
    
    private var isSimulator: Bool {
#if targetEnvironment(simulator)
        true
#else
        false
#endif
    }
    
    private var appVersionText: String {
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
        let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
        return "MoveStreak v\(version) (Build \(build))"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(L10n.settingsProfile)) {
                    Button(action: { showAvatarEditor = true }) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(manager.avatarColor.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: manager.avatarIcon)
                                    .foregroundColor(manager.avatarColor)
                            }
                            Text(L10n.settingsCustomizeAvatar)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text(L10n.settingsPreferences)) {
                    Toggle(isOn: Binding(
                        get: { manager.notificationsEnabled },
                        set: { manager.notificationsEnabled = $0 }
                    )) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    .tint(.blue)
                    .onChange(of: manager.notificationsEnabled) { oldVal, enabled in
                        if enabled {
                            manager.ensureNotificationsConfigured()
                            AudioManager.shared.haptic(.light)
                        } else {
                            AudioManager.shared.haptic(.light)
                        }
                    }
                    
                    Toggle(isOn: Binding(
                        get: { manager.hapticsEnabled },
                        set: { manager.hapticsEnabled = $0 }
                    )) {
                        Label("Haptic feedback", systemImage: "hand.tap.fill")
                    }
                    .tint(.blue)
                    .onChange(of: manager.hapticsEnabled) { oldVal, enabled in
                        guard enabled else { return }
                        AudioManager.shared.haptic(.light)
                    }
                    
                    Toggle(isOn: Binding(
                        get: { manager.soundEnabled },
                        set: { manager.soundEnabled = $0 }
                    )) {
                        Label("Sounds", systemImage: "speaker.wave.2.fill")
                    }
                    .tint(.blue)
                    .onChange(of: manager.soundEnabled) { _, enabled in
                        guard enabled else { return }
                        AudioManager.shared.playSound("tap")
                    }
                }

                Section(header: Text(L10n.settingsData)) {
                    Button(action: {
                        showResetAlert = true
                    }) {
                        Label("Delete user data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showResetAlert) {
                        Alert(
                            title: Text("Delete user data?"),
                            message: Text("This can’t be undone. All progress and XP will be permanently lost. Continue?"),
                            primaryButton: .destructive(Text("Delete everything")) {
                                withAnimation { manager.resetProgress() }
                                presentationMode.wrappedValue.dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                Section(footer: Text(appVersionText)) {
                    NavigationLink(destination: AboutMoveStreakView(manager: manager)) {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .appScrollIndicatorsHidden()
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(L10n.settingsTitle)
            .navigationBarItems(trailing: Button(L10n.commonDone) {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showAvatarEditor) {
                ProfileEditorView(manager: manager)
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Professional Subviews

struct ProfileHeaderView: View {
    @ObservedObject var manager: StreakManager
    @Binding var showEditor: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(manager.avatarColor.opacity(0.1))
                    .frame(width: 84, height: 84)
                
                Image(systemName: manager.avatarIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(manager.avatarColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(manager.userName)
                    .appTitle(size: 24)
                
                Text(manager.memberSinceText)
                    .appBody()
                
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                    Text(L10n.statsTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .appPill(color: .blue)
            }
            Spacer()
        }
        .appCard(accent: manager.avatarColor)
        .padding(.horizontal)
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appHeadline()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .appTitle(size: 28)
                    Text(unit)
                        .appBody()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(accent: color)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
    }
}

struct CalendarHistoryView: View {
    let history: [String: Int]
    
    // Generate dates for the current month
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)!
        let numDays = range.count
        
        let components = calendar.dateComponents([.year, .month], from: now)
        let firstDayOfMonth = calendar.date(from: components)!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...numDays {
            var dateComponents = components
            dateComponents.day = day
            days.append(calendar.date(from: dateComponents))
        }
        
        let remainder = days.count % 7
        if remainder != 0 {
            days.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
        }
        return days
    }
    
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        return Array(symbols[startIndex...] + symbols[..<startIndex]).map { $0.capitalized }
    }
    
    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with Month Name
            HStack {
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 5)
            .accessibilityAddTraits(.isHeader)
            
            // Modern Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                // Weekday Headers
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                
                // Days
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        let dateString = df.string(from: date)
                        let points = history[dateString] ?? 0
                        let isToday = Calendar.current.isDateInToday(date)
                        let dayNumber = Calendar.current.component(.day, from: date)
                        
                        ZStack {
                            if points >= 50 {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                            } else if isToday {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            }
                            
                            Text("\(dayNumber)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(points >= 50 ? .white : (isToday ? .blue : .primary))
                        }
                        .frame(height: 35)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Day \(dayNumber)")
                        .accessibilityValue(points >= 50 ? "Completed" : "No activity")
                        .accessibilityHint(isToday ? "Today" : "")
                    } else {
                        Color.clear.frame(height: 35)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 8, height: 8)
                    Text(L10n.statsCompleted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Circle().stroke(Color.blue, lineWidth: 1.5).frame(width: 8, height: 8)
                    Text(L10n.statsToday)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 5)
        }
        .appCard(accent: .blue)
    }
}

struct WeeklyProgressChart: View {
    let data: [(day: String, points: Int)]
    
    private let dailyGoalMinutes: Int = 30
    
    private struct WeeklyPoint: Identifiable, Hashable {
        let id: Int
        let label: String
        let minutes: Int
        let isPadding: Bool
        let isToday: Bool
    }
    
    private var points: [WeeklyPoint] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "EEE"
        
        let map = Dictionary(uniqueKeysWithValues: data.map { ($0.day, $0.points) })
        let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let todayLabel = df.string(from: Date())
        
        return order.enumerated().map { index, label in
            WeeklyPoint(
                id: index,
                label: label,
                minutes: map[label] ?? 0,
                isPadding: false,
                isToday: label == todayLabel
            )
        }
    }
    
    private var daysHitGoal: Int {
        points.filter { !$0.isPadding && $0.minutes >= dailyGoalMinutes }.count
    }
    
    private var totalMinutes: Int {
        points.reduce(0) { $0 + $1.minutes }
    }
    
    private var averageMinutes: Int {
        Int((Double(totalMinutes) / 7.0).rounded())
    }
    
    private var yMax: Double {
        let maxValue = max(points.map(\.minutes).max() ?? 0, dailyGoalMinutes)
        let padded = max(10, ((maxValue + 4) / 5) * 5)
        return Double(padded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            weeklyChart
        }
        .appCard()
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.statsWeekly)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(L10n.statsMinGoal(dailyGoalMinutes))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.gray)
            }
            
            Text(L10n.statsTotal(totalMinutes, averageMinutes))
                .font(.system(size: 13))
                .foregroundStyle(Color.gray)
        }
    }
    
    private var weeklyChart: some View {
        let barGradient = LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
        let plotPadding: CGFloat = 18
        
        return VStack(spacing: 8) {
            Chart {
                RuleMark(y: .value("Goal", dailyGoalMinutes))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                
                ForEach(points) { item in
                    if item.minutes > 0 {
                        BarMark(
                            x: .value("Day", item.id),
                            y: .value("Minutes", item.minutes)
                        )
                        .cornerRadius(6)
                        .foregroundStyle(barGradient)
                        .accessibilityLabel(item.label)
                        .accessibilityValue("\(item.minutes) minutes")
                    }
                }
            }
            .frame(height: 170)
            .chartXScale(domain: -0.5...6.5)
            .chartYScale(domain: 0...yMax)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(L10n.statsWeeklyActivity))
            .accessibilityValue(weeklyA11yValue)
            .accessibilityHint(Text(L10n.statsWeeklyHint))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { plotArea in
                plotArea.padding(.horizontal, plotPadding)
            }
            
            HStack(spacing: 0) {
                ForEach(points) { item in
                    Text(item.label)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(UIColor.systemGray3))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, plotPadding)
        }
    }
    
    private var weeklyA11yValue: String {
        let parts = points.map { "\($0.label) \($0.minutes) minutes" }
        return "You reached your goal \(daysHitGoal) times this week. " + parts.joined(separator: ", ")
    }
}

struct LevelProgressBar: View {
    let totalPoints: Int
    private var currentLevel: Int {
        (totalPoints / 50) + 1
    }
    private var progressInLevel: Double {
        Double(totalPoints % 50) / 50.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Level \(currentLevel)")
                        .font(.headline)
                    Text("\(50 - (totalPoints % 50)) XP to next level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(12, geo.size.width * CGFloat(progressInLevel)), height: 12)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 12)
        }
        .appCard(accent: .cyan)
    }
}

struct BadgeView: View {
    let badge: Badge
    @ObservedObject var manager: StreakManager
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: badge.icon)
                .font(.system(size: 30))
                .foregroundColor(badge.isUnlocked ? .yellow : .gray)
                .frame(width: 60, height: 60)
                .background(badge.isUnlocked ? Color.yellow.opacity(0.16) : Color.gray.opacity(0.10))
                .clipShape(Circle())
                .opacity(badge.isUnlocked ? 1.0 : 0.75)
            
            Text(badge.name)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(badge.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .opacity(badge.isUnlocked ? 1.0 : 0.85)
        }
        .frame(width: 110)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.sectionCornerRadius, style: .continuous)
                .stroke((badge.isUnlocked ? Color.yellow : Color.primary).opacity(0.18), lineWidth: 1)
        )
        .onTapGesture {
            AudioManager.shared.feedback(sound: .tap, haptic: .light)
            manager.selectedBadge = badge
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(badge.name)
        .accessibilityValue(badge.isUnlocked ? "Unlocked" : "Locked")
        .accessibilityHint(badge.description)
        .accessibilityIdentifier("BadgeView_\(badge.name)")
    }
}

// Helper for Hex Color
// Moved to MoveStreakLogic.swift

struct BadgeUnlockOverlay: View {
    let badge: Badge
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 20) {
                Text(L10n.badgeUnlocked)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 10)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Circle().fill(Color.yellow.opacity(0.14)))
                    .shadow(color: .yellow.opacity(0.25), radius: 16)
                
                VStack(spacing: 5) {
                    Text(badge.name)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text(badge.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 15) {
                    Button(action: onDismiss) {
                        Text(L10n.badgeAwesome)
                    }
                    .buttonStyle(AppPrimaryButtonStyle(color: .blue))
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding(20)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow(intensity: 0.10), radius: 18, x: 0, y: 10)
            .padding(28)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            AudioManager.shared.feedback(sound: .success, haptic: .success)
        }
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: badge.icon)
                .font(.system(size: 100))
                .foregroundColor(badge.isUnlocked ? .yellow : .gray)
                .padding(30)
                .background(Circle().fill(badge.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1)))
                .shadow(color: badge.isUnlocked ? .yellow.opacity(0.5) : .clear, radius: 20)
            
            VStack(spacing: 10) {
                Text(badge.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text(badge.isUnlocked ? "UNLOCKED" : "LOCKED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(badge.isUnlocked ? .green : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(badge.isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Text(badge.description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Text(L10n.badgeClose)
            }
            .buttonStyle(AppSecondaryButtonStyle(color: .blue))
            .padding(.horizontal, 40)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Timer View (Professional Feature)

struct TimerView: View {
    let activity: Activity
    @ObservedObject var manager: StreakManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var timeRemaining: TimeInterval
    @State private var totalTime: TimeInterval
    @State private var isActive = false
    @State private var progress: CGFloat = 1.0
    @State private var breatheScale: CGFloat = 1.0
    @State private var showTips = false
    @Environment(\.scenePhase) var scenePhase
    @State private var lastActiveTime: Date = Date()
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @AppStorage("timerEndTime") private var timerEndTime: Double = 0
    @AppStorage("timerActivityName") private var timerActivityName: String = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(activity: Activity, manager: StreakManager) {
        self.activity = activity
        self.manager = manager
        _timeRemaining = State(initialValue: activity.duration)
        _totalTime = State(initialValue: activity.duration)
    }
    
    /// Recover timer state if app was terminated during active timer
    func recoverTimerState() {
        guard timerEndTime > 0 && timerActivityName == activity.name else { return }
        
        let now = Date()
        let remainingTime = max(0, timerEndTime - now.timeIntervalSince1970)
        
        if remainingTime > 0 {
            timeRemaining = remainingTime
            isActive = true
            progress = CGFloat(timeRemaining / totalTime)
            lastActiveTime = now
        } else {
            // Timer expired while app was terminated
            timeRemaining = 0
            isActive = false
            progress = 0
            timerEndTime = 0
            timerActivityName = ""
        }
    }
    
    /// Formats a time interval to mm:ss for display.
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func toggleTimer() {
        withAnimation(.spring()) {
            isActive.toggle()
        }
        
        if isActive {
            lastActiveTime = Date() // Mark start time
            // Store timer end time for background recovery
            timerEndTime = Date().timeIntervalSince1970 + timeRemaining
            timerActivityName = activity.name
            AudioManager.shared.feedback(sound: .timerStart, haptic: .medium)
        } else {
            // Clear stored timer state when paused
            timerEndTime = 0
            timerActivityName = ""
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
            AudioManager.shared.feedback(sound: .timerStop, haptic: .medium)
        }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            // Dynamic Background based on activity color
            activity.color.opacity(0.05).ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .fill(.secondary.opacity(0.25))
                        .frame(width: 44, height: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.top, 12)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Label("Close", systemImage: "xmark")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Close")
                        .padding(.top, 2)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 15) {
                    Text(activity.name)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text(activity.description)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Immersive Timer Ring
                ZStack {
                    // Background Ring
                    Circle()
                        .stroke(lineWidth: 30)
                        .opacity(0.1)
                        .foregroundColor(activity.color)
                    
                    // Progress Ring
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                        .fill(
                            LinearGradient(colors: [activity.color, activity.color.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        )
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear(duration: 1.0), value: progress)
                        .shadow(color: activity.color.opacity(0.4), radius: 15, x: 0, y: 0)
                    
                    // Breathing Guide (for "Breathe" activity)
                    if activity.name == "Breathe" || activity.name == "Meditation" {
                         Circle()
                            .fill(activity.color.opacity(0.15))
                            .scaleEffect(isActive ? breatheScale : 1.0)
                            .animation(isActive ? .easeInOut(duration: 4).repeatForever(autoreverses: true) : .default, value: breatheScale)
                            .onAppear { breatheScale = 0.8 }
                    }
                    
                    VStack(spacing: 5) {
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 70, weight: .bold, design: .monospaced))
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.primary)
                            .appNumericTextTransition()
                        
                        if isActive {
                            Text(L10n.timerStayFocused)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                }
                .frame(maxWidth: 300, maxHeight: 300)
                .aspectRatio(1, contentMode: .fit)
                .padding()
                
                Spacer()
                
                // Controls
                if timeRemaining > 0 {
                    HStack(spacing: 40) {
                        Button(action: {
                            withAnimation {
                                timeRemaining = totalTime
                                progress = 1.0
                                isActive = false
                            }
                        }) {
                            VStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                Text(L10n.timerReset)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .disabled(isActive)
                        .opacity(isActive ? 0.3 : 1.0)
                        
                        Button(action: toggleTimer) {
                            Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 90))
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(LinearGradient(colors: [activity.color, activity.color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: activity.color.opacity(0.3), radius: 10, x: 0, y: 5)
                                .scaleEffect(isActive ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
                        }
                        
                        Button(action: {
                            manager.soundEnabled.toggle()
                        }) {
                            VStack {
                                Image(systemName: manager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(.title2)
                                Text(L10n.timerAudio)
                                    .font(.caption)
                            }
                            .foregroundColor(manager.soundEnabled ? .secondary : .red)
                        }
                        .accessibilityLabel(manager.soundEnabled ? "Sound on" : "Sound off")
                    }
                } else {
                    Button(action: {
                        manager.completeActivity(activity, isTimeAttack: true)
                        AudioManager.shared.playSuccess()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                            Text(L10n.timerComplete)
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle(color: activity.color))
                    .padding(.horizontal, 40)
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if isActive {
                if newPhase == .active {
                    // Came back to foreground - recover timer state
                    let now = Date()
                    let timePassed = now.timeIntervalSince(lastActiveTime)
                    
                    // Use stored end time if available for more accuracy
                    if timerEndTime > 0 {
                        let remainingTime = max(0, timerEndTime - now.timeIntervalSince1970)
                        timeRemaining = remainingTime
                    } else if timeRemaining > timePassed {
                        timeRemaining -= timePassed
                    } else {
                        timeRemaining = 0
                    }
                    
                    if timeRemaining <= 0 {
                        timeRemaining = 0
                        isActive = false
                        progress = 0
                        AudioManager.shared.feedback(sound: .timerStop, haptic: .light)
                    } else {
                        progress = CGFloat(timeRemaining / totalTime)
                    }
                    
                    lastActiveTime = now
                    
                    if backgroundTask != .invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTask)
                        backgroundTask = .invalid
                    }
                } else if newPhase == .background {
                    // Going to background - request background task
                    lastActiveTime = Date()
                    
                    // Start background task to keep timer accurate
                    if backgroundTask == .invalid {
                        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "TimerContinuation") {
                            // Expiration handler
                            if self.backgroundTask != .invalid {
                                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                                self.backgroundTask = .invalid
                            }
                        }
                    }
                    
                    // Update stored end time
                    if isActive {
                        timerEndTime = Date().timeIntervalSince1970 + timeRemaining
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            guard isActive else { return }
            
            // Sync current active time to prevent drift
            lastActiveTime = Date()
            
            if timeRemaining > 0 {
                timeRemaining -= 1
                progress = CGFloat(timeRemaining / totalTime)
                
                // Update stored end time during active countdown
                if timerEndTime > 0 {
                    timerEndTime = Date().timeIntervalSince1970 + timeRemaining
                }
            } else {
                isActive = false
                progress = 0
                timerEndTime = 0
                timerActivityName = ""
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
                AudioManager.shared.feedback(sound: .timerStop, haptic: .light)
            }
        }
        .onAppear {
            // Recover timer state when view appears
            recoverTimerState()
        }
    }
}

// MARK: - Audio Manager
// Moved to MoveStreakLogic.swift

// MARK: - New Views (Avatar, Confetti, Tips)

// MARK: - Visionary Views (Mockups for Submission)

struct LevelUpView: View {
    let levelText: String
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            if showParticles {
                ConfettiView()
            }
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 150, height: 150)
                        .blur(radius: 20)
                        .opacity(0.5)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 10)
                }
                
                VStack(spacing: 10) {
                    Text(L10n.timerLevelUp)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    
                    Text(levelText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
            Button(action: onDismiss) {
                Text("Continue")
                }
                .buttonStyle(AppPrimaryButtonStyle(color: .orange))
                .padding(.top, 20)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            showParticles = true
            AudioManager.shared.feedback(sound: .success, haptic: .success)
        }
    }
}

struct InsightsTeaserView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Insights")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .padding(.horizontal, 5)
            
            ZStack {
                VStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Detailed analysis coming soon")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 120)
            .overlay(
                 Text("PREVIEW")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.gray.opacity(0.1))
                    .rotationEffect(.degrees(-15))
            )
            .appMeshCard(accent: .purple, colors: [.purple, .blue, .cyan])
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insights coming soon")
    }
}

struct WaterTrackerCard: View {
    @ObservedObject var manager: StreakManager
    @Binding var showHydrationCheckIn: Bool
    @State private var confettiTrigger: Int = 0
    @State private var lastWasAtGoal: Bool = false
    @State private var plusPulse: Int = 0
    @State private var minusPulse: Int = 0
    
    var body: some View {
        ZStack {
            content
            ConfettiBurst(trigger: confettiTrigger, colors: [.cyan, .blue, .mint, .purple, .yellow])
        }
        .appCard(accent: .cyan)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.hydrationTitle))
        .accessibilityValue(L10n.hydrationValue(current: manager.waterIntake, goal: manager.waterGoal))
        .accessibilityHint(Text(L10n.hydrationCardA11yHint))
        .accessibilityAdjustableAction { direction in
            if direction == .increment { manager.addWater() }
            else { manager.removeWater() }
        }
        .accessibilityAction(named: L10n.hydrationA11yAddAction) {
            manager.addWater()
        }
        .accessibilityAction(named: L10n.hydrationA11yRemoveAction) {
            manager.removeWater()
        }
        .onAppear {
            lastWasAtGoal = manager.waterIntake >= manager.waterGoal
        }
        .onChange(of: manager.waterIntake) {
            let nowAtGoal = manager.waterIntake >= manager.waterGoal
            if nowAtGoal && !lastWasAtGoal {
                confettiTrigger += 1
                if manager.hapticsEnabled {
                    _ = HapticsEngine.shared.playSuccess()
                }
            }
            lastWasAtGoal = nowAtGoal
        }
    }
    
    private var content: some View {
        VStack(spacing: 15) {
            HStack {
                Label(L10n.hydrationTitle, systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundColor(.cyan)
                Spacer()
                Text("\(manager.waterIntake)/\(manager.waterGoal)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .appNumericTextTransition()
                
                Button(action: { showHydrationCheckIn = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.caption)
                        .padding(8)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .clipShape(Circle())
                }
                .accessibilityLabel(Text(L10n.hydrationEditA11yLabel))
                .accessibilityHint(Text(L10n.hydrationEditA11yHint))
            }
            
            WaterWaveBar(
                progress: min(1.0, Double(manager.waterIntake) / Double(max(1, manager.waterGoal))),
                color: .cyan
            )
            
            HStack {
                Button(action: {
                    minusPulse += 1
                    manager.removeWater()
                }) {
                    Image(systemName: "minus")
                        .font(.caption)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(manager.waterIntake == 0)
                .appSymbolBounce(value: minusPulse)
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(Text(L10n.hydrationRemoveOne))
                .accessibilityHint(Text(L10n.hydrationRemoveOneHint))
                
                Spacer()
                
                Text(manager.waterIntake >= manager.waterGoal ? L10n.hydrationGoalReached : L10n.hydrationPrompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel(Text(manager.waterIntake >= manager.waterGoal ? L10n.hydrationGoalReachedA11y : L10n.hydrationPrompt))
                
                Spacer()
                
                Button(action: {
                    plusPulse += 1
                    manager.addWater()
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .padding(8)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .clipShape(Circle())
                }
                .appSymbolBounce(value: plusPulse)
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(Text(L10n.hydrationAddOne))
                .accessibilityHint(Text(L10n.hydrationAddOneHint))
            }
        }
    }
}

struct WaterWaveBar: View {
    let progress: Double
    let color: Color
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        GeometryReader { geo in
            let fullWidth = geo.size.width
            let height = geo.size.height
            let fillWidth = max(0, min(fullWidth, fullWidth * CGFloat(progress)))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.10))
                
                ZStack(alignment: .leading) {
                    if reduceMotion {
                        Capsule()
                            .fill(LinearGradient(colors: [color.opacity(0.75), color], startPoint: .bottom, endPoint: .top))
                    } else {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                            let t = timeline.date.timeIntervalSinceReferenceDate
                            ZStack {
                                WaveShape(phase: t * 2.2, amplitude: 6, baseline: height * 0.62)
                                    .fill(LinearGradient(colors: [color.opacity(0.55), color], startPoint: .top, endPoint: .bottom))
                                WaveShape(phase: t * 3.1 + 1.2, amplitude: 4, baseline: height * 0.58)
                                    .fill(color.opacity(0.35))
                            }
                            .clipShape(Capsule())
                        }
                    }
                }
                .frame(width: fillWidth)
                .clipShape(Capsule())
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 28)
        .accessibilityHidden(true)
    }
}

struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat
    var baseline: CGFloat
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = min(max(baseline, 0), height)
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: midY))
        
        let wavelength = max(1, width / 1.4)
        let twoPi = Double.pi * 2
        
        var x: CGFloat = 0
        while x <= width {
            let progress = Double(x / wavelength)
            let y = midY + amplitude * CGFloat(sin(twoPi * progress + phase))
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

struct ActivityBreakdownView: View {
    let stats: [String: Int]
    let activities: [Activity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Activity summary")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .padding(.horizontal, 5)
            
            if stats.isEmpty {
                    Text("Complete activities to see your stats.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .appCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(stats.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(colorFor(key).opacity(0.14))
                                    .frame(width: 34, height: 34)
                                Image(systemName: iconFor(key))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(colorFor(key))
                            }
                            
                            Text(key)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(value)")
                                .fontWeight(.bold)
                            
                            Text("sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .appCard()
                    }
                }
            }
        }
        .appCard()
    }
    
    func iconFor(_ name: String) -> String {
        activities.first(where: { $0.name == name })?.icon ?? "circle.fill"
    }
    
    func colorFor(_ name: String) -> Color {
        activities.first(where: { $0.name == name })?.color ?? .gray
    }
}

struct ChallengeCard: View {
    let challenge: AppDailyChallenge
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.red)
                    Text("Daily challenge")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                
                Text(challenge.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                
                HStack {
                    ProgressView(value: challenge.progress)
                        .tint(.red)
                    Text(challenge.currentPoints > challenge.targetPoints ? "Goal exceeded: \(challenge.currentPoints)/\(challenge.targetPoints)" : "\(challenge.currentPoints)/\(challenge.targetPoints)")
                        .font(.caption)
                        .foregroundColor(challenge.currentPoints > challenge.targetPoints ? .green : .secondary)
                        .fontWeight(challenge.currentPoints > challenge.targetPoints ? .bold : .regular)
                }
            }
            
            if challenge.isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .padding(.leading)
            }
        }
        .appCard(accent: .red)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily challenge: \(challenge.title)")
        .accessibilityValue("\(challenge.currentPoints) of \(challenge.targetPoints) points. \(challenge.isCompleted ? "Completed" : "In progress")")
        .accessibilityHint("Today's challenge progress")
        .accessibilityIdentifier("ChallengeCard_\(challenge.title)")
    }
}

struct WellnessTipCard: View {
    let tip: String
    let onTap: () -> Void
    
    var body: some View {
        content
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture().onEnded {
                    onTap()
                    AudioManager.shared.feedback(sound: .tap, haptic: .light)
                }
            )
        .appCard(accent: .yellow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tip of the day")
        .accessibilityValue(tip)
        .accessibilityHint("Double tap to open")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("WellnessTipCard")
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color.yellow.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.yellow)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.wellnessTipTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text("TIP")
                            .appPill(color: .yellow)
                    }
                    
                    Text(tip)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EducationalTipSheet: View {
    let tip: EducationalTip
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 84, height: 84)
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text(tip.title)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(tip.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Done") {
                    onClose()
                }
                .buttonStyle(AppPrimaryButtonStyle(color: .blue))
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding(.top, 24)
            .navigationTitle("Why it matters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onClose() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct StepsCard: View {
    @ObservedObject var manager: StreakManager
    
    private let goal: Int = 10000
    
    private var steps: Int? { manager.stepsToday }
    
    private var progress: Double {
        guard let steps else { return 0 }
        return min(1.0, Double(steps) / Double(max(1, goal)))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Steps", systemImage: "figure.walk.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                
                Spacer()
                
                Text("Today")
                    .appPill(color: .secondary)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(steps.map(String.init) ?? "—")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .appNumericTextTransition()
                
                Spacer()
                
                Text("Goal \(goal)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.green.opacity(0.12))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .mint, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(12, geo.size.width * CGFloat(progress)), height: 12)
                        .shadow(color: .green.opacity(0.25), radius: 6, x: 0, y: 3)
                }
            }
            .frame(height: 12)
        }
        .appCard(accent: .green)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Steps today")
        .accessibilityValue(steps.map { "\($0) steps" } ?? "Not available")
    }
}

struct ProfileEditorView: View {
    @ObservedObject var manager: StreakManager
    @Environment(\.dismiss) private var dismiss
    
    let icons = [
        "person.crop.circle.fill",
        "person.circle.fill",
        "person.fill",
        "face.smiling.fill",
        "sun.max.fill",
        "moon.stars.fill",
        "cloud.sun.fill",
        "sparkles",
        "star.circle.fill",
        "star.fill",
        "bolt.circle.fill",
        "bolt.fill",
        "heart.circle.fill",
        "heart.fill",
        "flame.circle.fill",
        "flame.fill",
        "crown.fill",
        "trophy.fill",
        "medal.fill",
        "shield.fill",
        "leaf.circle.fill",
        "leaf.fill",
        "drop.fill",
        "figure.walk",
        "figure.run",
        "figure.strengthtraining.traditional",
        "figure.yoga",
        "figure.mind.and.body",
        "figure.hiking",
        "bicycle",
        "dumbbell.fill",
        "target",
        "wand.and.stars",
        "gamecontroller.fill",
        "headphones.circle.fill",
        "music.note",
        "camera.fill",
        "paintpalette.fill",
        "pencil.tip.crop.circle",
        "books.vertical.fill",
        "graduationcap.fill",
        "briefcase.fill",
        "lightbulb.fill",
        "globe.europe.africa.fill",
        "map.fill",
        "paperplane.fill",
        "bolt.heart.fill",
        "pawprint.fill",
        "hare.fill",
        "tortoise.fill"
    ]
    let colors = [
        "007AFF",
        "0A84FF",
        "34C759",
        "30D158",
        "FF9500",
        "FF9F0A",
        "FFCC00",
        "FFD60A",
        "FF2D55",
        "FF375F",
        "FF3B30",
        "FF453A",
        "AF52DE",
        "BF5AF2",
        "5856D6",
        "5E5CE6",
        "5AC8FA",
        "64D2FF",
        "30B0C7",
        "32ADE6",
        "A2845E",
        "AC8E68",
        "8E8E93",
        "636366",
        "1C1C1E",
        "3A3A3C"
    ]
    
    @State private var selectedIcon: String = ""
    @State private var selectedColor: String = ""
    @State private var editName: String = ""
    @FocusState private var isNameFocused: Bool
    
    private var trimmedName: String {
        editName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var hasChanges: Bool {
        trimmedName != manager.userName ||
        selectedIcon != manager.avatarIcon ||
        selectedColor != manager.avatarColorHex
    }
    
    private var canSave: Bool {
        !trimmedName.isEmpty && hasChanges
    }
    
    private var previewColor: Color {
        Color(hex: selectedColor.isEmpty ? manager.avatarColorHex : selectedColor)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(previewColor.opacity(0.12))
                                    .frame(width: 96, height: 96)
                                
                                Image(systemName: selectedIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 46, height: 46)
                                    .foregroundColor(previewColor)
                            }
                            .overlay(Circle().stroke(previewColor.opacity(0.25), lineWidth: 1))
                            
                            VStack(spacing: 4) {
                                Text(trimmedName.isEmpty ? "Name" : trimmedName)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(trimmedName.isEmpty ? .secondary : .primary)
                                
                                Text("Level \(manager.currentLevel) • \(manager.difficultyModeString)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                
                Section(header: Text("Name"), footer: Text("Max 20 characters.")) {
                    TextField("Enter your name", text: $editName)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit { isNameFocused = false }
                        .onChange(of: editName) { _, newValue in
                            if newValue.count > 20 {
                                editName = String(newValue.prefix(20))
                            }
                        }
                }
                
                Section(header: Text("Avatar"), footer: Text("Tap an icon and a color to update your avatar.")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                        AudioManager.shared.feedback(sound: .tap, haptic: .light)
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? .white : .primary)
                                            .frame(width: 54, height: 54)
                                            .background(selectedIcon == icon ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        
                        Divider()
                        
                        Text("Colore")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(colors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                        AudioManager.shared.feedback(sound: .tap, haptic: .light)
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 44, height: 44)
                                            
                                            if selectedColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(selectedColor == color ? 0.15 : 0.05), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .appScrollIndicatorsHidden()
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        AudioManager.shared.feedback(sound: .success, haptic: .success)
                        manager.updateAvatar(icon: selectedIcon, colorHex: selectedColor)
                        manager.userName = trimmedName
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                selectedIcon = manager.avatarIcon
                selectedColor = manager.avatarColorHex
                editName = manager.userName
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ConfettiView: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            if !reduceMotion {
                ForEach(0..<30) { _ in
                    ConfettiParticle(isAnimating: isAnimating)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityHidden(true)
    }
}

struct ConfettiParticle: View {
    let isAnimating: Bool
    @State private var randomX: CGFloat = CGFloat.random(in: -300...300)
    @State private var randomY: CGFloat = CGFloat.random(in: -500...200)
    @State private var randomScale: CGFloat = CGFloat.random(in: 0.5...1.5)
    @State private var randomColor: Color = [Color.red, .blue, .green, .yellow, .purple, .orange].randomElement()!
    @State private var rotation: Double = Double.random(in: 0...360)
    
    var body: some View {
        Circle()
            .fill(randomColor)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? randomScale : 0.1)
            .offset(x: isAnimating ? randomX : 0, y: isAnimating ? randomY : 0)
            .opacity(isAnimating ? 0 : 1)
            .rotationEffect(.degrees(isAnimating ? rotation : 0))
            .animation(.easeOut(duration: 2.5).delay(Double.random(in: 0...0.5)), value: isAnimating)
    }
}

struct AllBadgesView: View {
    @ObservedObject var manager: StreakManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedBadge: Badge?
    
    var unlockedBadges: [Badge] {
        manager.badges.filter { $0.isUnlocked }
    }
    
    var lockedBadges: [Badge] {
        manager.badges.filter { !$0.isUnlocked }
    }
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        // Header Stats Card
                        ZStack {
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            
                            VStack(spacing: 15) {
                                Text("Progresso traguardi")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                HStack(spacing: 40) {
                                    VStack {
                                        Text("\(unlockedBadges.count)")
                                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("Unlocked")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    VStack {
                                        Text("\(manager.badges.count)")
                                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("Total")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(width: geo.size.width * CGFloat(unlockedBadges.count) / CGFloat(max(1, manager.badges.count)), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                .padding(.horizontal, 40)
                            }
                            .padding(.vertical, 30)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if !unlockedBadges.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Label("Collection", systemImage: "trophy.fill")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(unlockedBadges) { badge in
                                        AchievementCard(badge: badge)
                                            .onTapGesture {
                                                selectedBadge = badge
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        if !lockedBadges.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Label("Locked", systemImage: "lock.fill")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(lockedBadges) { badge in
                                        AchievementCard(badge: badge)
                                            .onTapGesture {
                                                selectedBadge = badge
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                if let selectedBadge {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.selectedBadge = nil
                            }
                        }
                    
                    BadgeDetailView(badge: selectedBadge) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.selectedBadge = nil
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .animation(.easeInOut(duration: 0.2), value: selectedBadge != nil)
        }
        .navigationViewStyle(.stack)
    }
}

struct AchievementCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Color.yellow.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 32))
                    .foregroundColor(badge.isUnlocked ? .yellow : .gray)
            }
            .padding(.top, 10)
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.headline)
                    .foregroundColor(badge.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(badge.isUnlocked ? "Sbloccato" : "Bloccato")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(badge.isUnlocked ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(badge.isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .appCard(accent: badge.isUnlocked ? .yellow : nil)
        .opacity(badge.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Daily Challenge Completion Sheet

struct DailyChallengeCompletionSheet: View {
    @ObservedObject var manager: StreakManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        manager.showDailyChallengeComplete = false
                    }
                }
            
            VStack(spacing: 24) {
                // Flame icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Great!")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("You crushed it today.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    manager.showDailyChallengeComplete = false
                }) {
                    Text("Close")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 40)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
            )
            .padding(40)
        }
    }
}
