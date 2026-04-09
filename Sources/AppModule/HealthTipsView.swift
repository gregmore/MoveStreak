import SwiftUI
import UIKit

struct HealthTipsView: View {
    @ObservedObject var manager: StreakManager
    @Binding var isRootTabBarHidden: Bool
    
    @State private var refreshToken = UUID()
    
    @AppStorage("savedHealthTipIDs") private var savedHealthTipIDsRaw: String = ""

    init(manager: StreakManager, isRootTabBarHidden: Binding<Bool> = .constant(false)) {
        self.manager = manager
        self._isRootTabBarHidden = isRootTabBarHidden
    }
    
    private struct TipSection: Identifiable, Hashable {
        var id: String { title }
        let title: String
        let icon: String
        let color: Color
        let subtitle: String
        let tips: [String]
    }
    
    private var sections: [TipSection] {
        [
            TipSection(
                title: "Hydration",
                icon: "drop.fill",
                color: .blue,
                subtitle: "Energy, focus, recovery",
                tips: [
                    "Drink a glass right after you wake up.",
                    "If you exercise: hydrate before, during, and after.",
                    "Keep a bottle in sight to reduce “forgetting”.",
                    "Try a glass before coffee—thirst can feel like “craving stimulation”.",
                    "Very dark and infrequent urine can signal low hydration (medical exceptions apply).",
                    "After a long desk session: stand up and take 2–3 sips (a micro‑habit).",
                    "Don’t chase perfection: one extra glass today is already progress.",
                    "Infuse water with lemon or cucumber if you find plain water boring.",
                    "Drink a glass of water 30 minutes before a meal to aid digestion.",
                    "Headache? Try drinking water before reaching for medication.",
                    "Use a straw—it often leads to drinking more without noticing.",
                    "Eat water-rich foods like watermelon, cucumber, and oranges."
                ]
            ),
            TipSection(
                title: "Posture",
                icon: "figure.stand",
                color: .purple,
                subtitle: "Neck & back relief",
                tips: [
                    "Shoulders down and back, neck long—hold for 30 seconds.",
                    "Use the 20‑20‑20 break rule while on screens.",
                    "Chin tuck (double‑chin) for 8 controlled reps.",
                    "Plant your feet: stability below often reduces tension above.",
                    "Every hour: 10 slow scap squeezes (pinch and release).",
                    "Keep the screen at eye level to reduce “forward head” posture.",
                    "Breathe low (belly breathing) to relax shoulders and traps.",
                    "Uncross your legs to improve circulation and pelvic alignment.",
                    "Stand against a wall to reset your spine alignment.",
                    "Adjust your chair height so your hips are slightly above your knees.",
                    "Stretch your chest (doorway stretch) to counter slouching.",
                    "Switch your mouse hand occasionally to balance shoulder use."
                ]
            ),
            TipSection(
                title: "Sleep",
                icon: "moon.zzz.fill",
                color: .indigo,
                subtitle: "Deeper recovery",
                tips: [
                    "Keep a routine: similar sleep/wake times when possible.",
                    "Screens off 30 minutes before bed.",
                    "Cool, dark room and low light in the evening.",
                    "Get 5–10 minutes of morning daylight to support your body clock.",
                    "Avoid large late meals—digestion can disturb sleep.",
                    "Caffeine: try avoiding it within 6–8 hours of bedtime.",
                    "If your mind races: write 3 lines about tomorrow (a mental unload).",
                    "Try a warm shower or bath 90 minutes before bed.",
                    "Read a physical book instead of scrolling on your phone.",
                    "Use white noise or earplugs if your environment is noisy.",
                    "Limit liquid intake 1–2 hours before bed to avoid waking up.",
                    "Practice '4-7-8' breathing to relax your nervous system."
                ]
            ),
            TipSection(
                title: "Movement",
                icon: "figure.walk",
                color: .green,
                subtitle: "Momentum > motivation",
                tips: [
                    "A 5‑minute walk counts.",
                    "After meals: a 2‑minute walk can help digestion.",
                    "Quality over quantity: move slowly and with control.",
                    "If you feel stuck: 20 slow squats + 20 seconds of calm breathing.",
                    "Every hour: 60 seconds standing beats continuous sitting.",
                    "Alternate hard days and easy days to stay consistent.",
                    "If it’s raining: walk indoors during a song.",
                    "Take the stairs instead of the elevator whenever possible.",
                    "Park further away to add extra steps to your day.",
                    "Stretch while watching TV or waiting for coffee.",
                    "Dance to one song a day—it boosts mood and heart rate.",
                    "Do calf raises while brushing your teeth."
                ]
            ),
            TipSection(
                title: "Nutrition",
                icon: "fork.knife",
                color: .orange,
                subtitle: "Simple, sustainable choices",
                tips: [
                    "Add a serving of vegetables at lunch or dinner.",
                    "Protein at breakfast often means steadier energy.",
                    "Choose fruit as a snack when you can.",
                    "If you feel “weird hunger”: check hydration and sleep first.",
                    "More fiber = more satiety: legumes, oats, vegetables, fruit.",
                    "One better meal beats a perfect week you never start.",
                    "Make healthy snacks easy: prep something in advance.",
                    "Eat slowly and chew thoroughly to improve digestion.",
                    "Use smaller plates to naturally control portion sizes.",
                    "Shop with a list to avoid impulse buys.",
                    "Cook once, eat twice—batch cooking saves time and effort.",
                    "Spice it up: herbs and spices add flavor without calories."
                ]
            ),
            TipSection(
                title: "Screen & Eyes",
                icon: "eye.fill",
                color: .cyan,
                subtitle: "Reduce strain fast",
                tips: [
                    "20‑20‑20: every 20 minutes, look 20 seconds at ~20 feet (6 m).",
                    "Increase text size: less strain often means less tension.",
                    "Avoid very bright screens at night to support sleep.",
                    "If eyes feel dry: blink intentionally for 10 seconds.",
                    "Tired eyes: try palming (hands over eyes) for 30–60 seconds.",
                    "Position your monitor an arm's length away.",
                    "Reduce screen glare by adjusting lighting or using a matte filter.",
                    "Clean your screen regularily—dust increases eye strain.",
                    "Use 'Dark Mode' in low-light environments.",
                    "Take a complete screen break during lunch."
                ]
            ),
            TipSection(
                title: "Stress & Focus",
                icon: "brain.head.profile",
                color: .pink,
                subtitle: "Calm, then clarity",
                tips: [
                    "4–6 breathing: inhale 4s, exhale 6s for 2 minutes.",
                    "To start: “just 2 minutes” (momentum often follows).",
                    "When anxious: do one small physical action (walk, water, fresh air).",
                    "Pick one micro‑goal for the next hour—not the entire day.",
                    "Reduce notifications: fewer interruptions means less mental fatigue.",
                    "Write down your top 3 priorities for the day.",
                    "Practice saying 'no' to protect your time and energy.",
                    "Do a 'brain dump' when you feel overwhelmed.",
                    "Focus on what you can control, let go of what you can't.",
                    "Take a 'silence break'—5 minutes of no input."
                ]
            ),
            TipSection(
                title: "Sunlight & Nature",
                icon: "sun.max.fill",
                color: .yellow,
                subtitle: "Mood & rhythm",
                tips: [
                    "Morning sunlight helps reset your circadian rhythm.",
                    "Open windows to let fresh air circulate daily.",
                    "A 10-minute walk in a park lowers cortisol levels.",
                    "Look at the horizon or tree tops to relax your gaze.",
                    "Bring a plant into your workspace for a mood boost.",
                    "Step outside barefoot (earthing) if safe and possible.",
                    "Notice the changing seasons—it grounds you in the present.",
                    "Eat lunch outside whenever the weather permits."
                ]
            ),
            TipSection(
                title: "Digital Wellbeing",
                icon: "iphone",
                color: .gray,
                subtitle: "Reclaim your attention",
                tips: [
                    "Turn off non-human notifications (apps, news, games).",
                    "Charge your phone outside the bedroom.",
                    "Set app limits for social media scrolling.",
                    "Unfollow accounts that make you feel anxious or inadequate.",
                    "Have a 'tech-free' meal once a day.",
                    "Use 'Do Not Disturb' mode during deep work sessions.",
                    "Delete apps you haven't used in the last month.",
                    "Check email only at specific times, not constantly."
                ]
            ),
            TipSection(
                title: "Mindset",
                icon: "sparkles",
                color: .mint,
                subtitle: "Growth & perspective",
                tips: [
                    "Talk to yourself like you would to a friend.",
                    "Celebrate small wins—they release dopamine.",
                    "View failure as data, not as a character flaw.",
                    "Replace 'I have to' with 'I get to'.",
                    "Focus on progress, not perfection.",
                    "Gratitude: name 3 small good things that happened today.",
                    "Curiosity kills judgment—stay curious about your reactions.",
                    "Your worth is not defined by your productivity."
                ]
            )
        ]
    }
    
    private var savedIDs: Set<String> {
        Set(
            savedHealthTipIDsRaw
                .split(separator: "|")
                .map(String.init)
                .filter { !$0.isEmpty }
        )
    }
    
    private func tipID(section: String, tip: String) -> String {
        "\(section)|\(tip)"
    }
    
    private func isSaved(section: String, tip: String) -> Bool {
        savedIDs.contains(tipID(section: section, tip: tip))
    }
    
    private func setSaved(_ saved: Bool, section: String, tip: String) {
        var set = savedIDs
        let id = tipID(section: section, tip: tip)
        if saved { set.insert(id) } else { set.remove(id) }
        savedHealthTipIDsRaw = set.sorted().joined(separator: "|")
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                categoriesList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(L10n.healthTipsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .id(refreshToken)
        .onAppear {
            isRootTabBarHidden = true
        }
    }

    private var categoriesList: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.categoriesTitle)
                .appTitle(size: 20)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                ForEach(sections) { section in
                    NavigationLink {
                        HealthTipsCategoryView(
                            title: section.title,
                            icon: section.icon,
                            color: section.color,
                            subtitle: section.subtitle,
                            tips: section.tips,
                            isSaved: { tip in isSaved(section: section.title, tip: tip) },
                            setSaved: { saved, tip in setSaved(saved, section: section.title, tip: tip) }
                        )
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(section.color.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: section.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(section.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .appHeadline()
                                Text(section.subtitle)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Text("\(section.tips.count)")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(section.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(section.color.opacity(0.12))
                                    .clipShape(Capsule())
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.secondary.opacity(0.5))
                            }
                        }
                        .appCard()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func tipRow(section: String, color: Color, tip: String) -> some View {
        let saved = isSaved(section: section, tip: tip)
        
        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            
            Text(tip)
                .appBody(color: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            CopyButton(text: tip, color: color)
            
            Button {
                setSaved(!saved, section: section, tip: tip)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .font(.subheadline)
                    .foregroundStyle(saved ? color : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tip)
    }
}

private struct HealthTipsCategoryView: View {
    let title: String
    let icon: String
    let color: Color
    let subtitle: String
    let tips: [String]
    let isSaved: (String) -> Bool
    let setSaved: (Bool, String) -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                
                VStack(spacing: 12) {
                    ForEach(tips, id: \.self) { tip in
                        tipRow(tip)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
    
    private func tipRow(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            
            Text(tip)
                .appBody(color: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(2)
            
            CopyButton(text: tip, color: color)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tip)
    }
}
