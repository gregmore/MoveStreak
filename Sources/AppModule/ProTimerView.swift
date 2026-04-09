import SwiftUI

struct ProTimerView: View {
    let activity: Activity
    @ObservedObject var manager: StreakManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var timeRemaining: TimeInterval
    @State private var totalTime: TimeInterval
    @State private var isActive = false
    @State private var progress: CGFloat = 1.0
    @State private var didReachZero = false
    @State private var didComplete = false
    @State private var lastActiveTime = Date()
    @State private var lastTickDate = Date()
    @State private var endTime: Date? = nil
    @State private var confettiTrigger: Int = 0
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(activity: Activity, manager: StreakManager) {
        self.activity = activity
        self.manager = manager
        _timeRemaining = State(initialValue: activity.duration)
        _totalTime = State(initialValue: activity.duration)
    }
    
    private var isFinished: Bool {
        timeRemaining <= 0.0001
    }
    
    private var statusText: String {
        if isFinished { return "DONE" }
        return isActive ? "FOCUS" : "PAUSED"
    }
    
    var body: some View {
        GeometryReader { geo in
            let ringDiameter = min(280, geo.size.width * 0.74)
            
            ZStack {
                background
                
                VStack(spacing: 0) {
                    header
                    
                    Spacer(minLength: 14)
                    
                    titleBlock
                        .padding(.top, 8)
                    
                    Spacer(minLength: 28)
                    
                    ring(diameter: ringDiameter)
                    
                    Spacer(minLength: 34)
                    
                    controls
                        .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            lastTickDate = Date()
        }
        .onChange(of: isActive) { _, _ in
            lastTickDate = Date()
            lastActiveTime = Date()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if isActive, let endTime {
                    let now = Date()
                    let remaining = max(0, endTime.timeIntervalSince(now))
                    timeRemaining = remaining
                    progress = CGFloat(max(0, remaining / max(0.1, totalTime)))
                    lastTickDate = now
                    lastActiveTime = now
                    if isFinished {
                        reachZero()
                    }
                } else {
                    lastTickDate = Date()
                    lastActiveTime = Date()
                }
            } else {
                if isActive, endTime == nil {
                    endTime = Date().addingTimeInterval(timeRemaining)
                }
                lastTickDate = Date()
                lastActiveTime = Date()
            }
        }
        .onReceive(timer) { _ in
            guard isActive else { return }
            let now = Date()
            let delta = now.timeIntervalSince(lastTickDate)
            lastTickDate = now
            tick(by: delta)
        }
    }
    
    private var background: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    activity.color.opacity(0.14),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }
    
    private var header: some View {
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
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(activity.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: AppTheme.shadow(intensity: 0.08), radius: 10, x: 0, y: 6)
                }
                .accessibilityLabel("Close")
                .padding(.top, 2)
            }
            .padding(.horizontal)
        }
    }
    
    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(activity.name)
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.75)
            
            Text(activity.description)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .padding(.top, 6)
    }
    
    private func ring(diameter: CGFloat) -> some View {
        Group {
            if isActive && !reduceMotion {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let phase = t * (2.0 * Double.pi / 2.3)
                    let pulse = 1.0 + 0.02 * (0.5 + 0.5 * sin(phase))
                    ringContent(diameter: diameter)
                        .scaleEffect(pulse)
                }
            } else {
                ringContent(diameter: diameter)
                    .scaleEffect(1.0)
            }
        }
    }

    private func ringContent(diameter: CGFloat) -> some View {
        let lineWidth = max(18, diameter * 0.09)
        return ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(Color.primary.opacity(0.10))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .fill(
                    LinearGradient(
                        colors: [activity.color, activity.color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(270))
                .shadow(color: activity.color.opacity(0.4), radius: 15, x: 0, y: 0)
                .animation(.linear(duration: 0.10), value: progress)

            VStack(spacing: 6) {
                Text(timeString(timeRemaining))
                    .font(.system(size: max(58, diameter * 0.27), weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.primary)
                    .appNumericTextTransition()

                Text(didReachZero ? "Tap Complete" : (isActive ? "Stay focused" : "Paused"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            ConfettiBurst(trigger: confettiTrigger, colors: [.green, .mint, .cyan, .yellow, .purple])
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activity.name) timer")
        .accessibilityValue("\(Int(ceil(timeRemaining))) seconds remaining")
    }
    
    private var statusColor: Color {
        if isFinished { return .green }
        return isActive ? .blue : .orange
    }
    
    private var controls: some View {
        HStack(spacing: 40) {
            Button {
                resetTimer()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text(L10n.timerReset)
                        .font(.caption)
                }
                .foregroundStyle(isActive ? Color.secondary.opacity(0.35) : Color.secondary)
            }
            .disabled(isActive)
            .accessibilityLabel("Reset")
            
            if didReachZero {
                Button {
                    completeSession()
                } label: {
                    ZStack {
                        Circle()
                            .fill(activity.color)
                            .frame(width: 92, height: 92)
                            .shadow(color: AppTheme.shadow(intensity: 0.18), radius: 18, x: 0, y: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityLabel("Complete")
            } else {
                Button {
                    toggleTimer()
                } label: {
                    ZStack {
                        Circle()
                            .fill(activity.color)
                            .frame(width: 92, height: 92)
                            .shadow(color: AppTheme.shadow(intensity: 0.18), radius: 18, x: 0, y: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        
                        Image(systemName: isActive ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isActive ? 0.96 : 1)
                .animation(.spring(response: 0.28, dampingFraction: 0.70), value: isActive)
                .accessibilityLabel(isActive ? "Pause" : "Start")
            }
            
            Button {
                manager.soundEnabled.toggle()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: manager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title2)
                    Text(L10n.timerAudio)
                        .font(.caption)
                }
                .foregroundStyle(manager.soundEnabled ? Color.secondary : Color.red)
            }
            .accessibilityLabel(manager.soundEnabled ? "Sound on" : "Sound off")
        }
        .padding(.bottom, 8)
    }
    
    private func toggleTimer() {
        guard !didReachZero else { return }
        isActive.toggle()
        if isActive {
            endTime = Date().addingTimeInterval(timeRemaining)
            AudioManager.shared.feedback(sound: .timerStart, haptic: .medium)
        } else {
            AudioManager.shared.feedback(sound: .timerStop, haptic: .light)
            lastTickDate = Date()
            lastActiveTime = Date()
            endTime = nil
        }
    }
    
    private func resetTimer() {
        isActive = false
        didReachZero = false
        didComplete = false
        timeRemaining = totalTime
        progress = 1
        endTime = nil
        AudioManager.shared.feedback(sound: .tap, haptic: .light)
    }
    
    private func tick(by delta: TimeInterval) {
        guard !didReachZero else { return }
        guard timeRemaining > 0 else {
            progress = 0
            return
        }
        
        timeRemaining = max(0, timeRemaining - delta)
        progress = CGFloat(max(0, timeRemaining / max(0.1, totalTime)))
        
        if isFinished {
            reachZero()
        }
    }
    
    private func reachZero() {
        guard !didReachZero else { return }
        didReachZero = true
        isActive = false
        timeRemaining = 0
        progress = 0
        AudioManager.shared.feedback(sound: .timerStop, haptic: .light)
    }
    
    private func completeSession() {
        guard didReachZero else { return }
        guard !didComplete else { return }
        didComplete = true
        confettiTrigger += 1
        AudioManager.shared.playSuccess()
        manager.completeActivity(activity, isTimeAttack: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dismiss()
        }
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time.rounded(.down)))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}
