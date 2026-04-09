import SwiftUI

struct WelcomeView: View {
    @ObservedObject var manager: StreakManager
    @State private var showPrePermissionDialog = false
    @FocusState private var isNameFocused: Bool
    
    private var trimmedName: String {
        manager.userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canContinue: Bool { !trimmedName.isEmpty }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                        .padding(.top, 22)
                        .padding(.horizontal, 22)
                        .accessibilityAddTraits(.isHeader)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        WelcomeMinimalFeatureCard(
                            icon: "figure.walk",
                            title: "Today dashboard",
                            message: "See your tip of the day, steps, hydration, and daily challenge in one place.",
                            tint: .blue
                        )
                        
                        WelcomeMinimalFeatureCard(
                            icon: "timer",
                            title: "Pro Timer sessions",
                            message: "Start a timed workout with a clean ring UI, haptics, and auto‑finish.",
                            tint: .purple
                        )
                        
                        WelcomeMinimalFeatureCard(
                            icon: "drop.fill",
                            title: "Hydration check‑ins",
                            message: "Log water quickly, earn points, and hit your daily goal.",
                            tint: .cyan
                        )
                        
                        WelcomeMinimalFeatureCard(
                            icon: "figure.walk.circle.fill",
                            title: "Step counting",
                            message: "Track steps with Motion & Fitness to stay active during the day.",
                            tint: .green
                        )
                        
                        WelcomeMinimalFeatureCard(
                            icon: "target",
                            title: "Daily challenge",
                            message: "Get a daily goal and progress bar to keep momentum.",
                            tint: .red
                        )
                        
                        WelcomeMinimalFeatureCard(
                            icon: "trophy.fill",
                            title: "Difficulty + progression",
                            message: "Progress through difficulty tiers and level up with XP.",
                            tint: .orange
                        )
                        
                        WelcomeMinimalFeatureCard(
                            icon: "sparkles",
                            title: "Tips & education",
                            message: "Short, actionable tips to improve posture, energy, and recovery.",
                            tint: .pink
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 180)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                bottomPanel
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .alert(isPresented: $showPrePermissionDialog) {
            Alert(
                title: Text(L10n.welcomeNotificationsTitle),
                message: Text(L10n.welcomeNotificationsBody),
                primaryButton: .default(Text(L10n.welcomeNotificationsEnable)) {
                    manager.ensureNotificationsConfigured()
                    withAnimation {
                        manager.completeOnboarding()
                    }
                },
                secondaryButton: .cancel(Text(L10n.welcomeNotificationsSkip)) {
                    withAnimation {
                        manager.completeOnboarding()
                    }
                }
            )
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: AppTheme.shadow(intensity: 0.10), radius: 14, x: 0, y: 10)
            
            VStack(spacing: 6) {
                Text(L10n.welcomeSubtitle)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text("MoveStreak")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(Color.primary)
                
                Text(L10n.welcomeTagline)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
        }
    }
    
    private var bottomPanel: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.welcomeNameLabel)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !trimmedName.isEmpty {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                
                TextField(L10n.welcomeNamePlaceholder, text: $manager.userName)
                    .font(.title3)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit { isNameFocused = false }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
            Text(L10n.welcomePrivacyNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                isNameFocused = false
                AudioManager.shared.feedback(sound: .tap, haptic: .success)
                showPrePermissionDialog = true
            }) {
                Text(L10n.welcomeContinue)
            }
            .buttonStyle(AppPrimaryButtonStyle(color: canContinue ? .blue : .gray))
            .disabled(!canContinue)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow(intensity: 0.10), radius: 22, x: 0, y: 14)
    }
}

private struct WelcomeMinimalFeatureCard: View {
    let icon: String
    let title: String
    let message: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(tint)
                    )
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow(intensity: 0.08), radius: 16, x: 0, y: 10)
        .accessibilityElement(children: .combine)
    }
}
