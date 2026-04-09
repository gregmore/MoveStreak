import Foundation

struct EducationalTip: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let body: String
    let tags: [String]
}

final class TipEngine {
    static let shared = TipEngine()
    
    private var cachedTips: [EducationalTip]?
    
    func tips() -> [EducationalTip] {
        if let cachedTips { return cachedTips }
        cachedTips = Self.builtInTips
        return Self.builtInTips
    }
    
    func dailyTip(for date: Date) -> EducationalTip? {
        let all = tips()
        guard !all.isEmpty else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let dayStart = cal.startOfDay(for: date)
        let refStart = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
        let dayNumber = cal.dateComponents([.day], from: refStart, to: dayStart).day ?? 0
        let index = ((dayNumber % all.count) + all.count) % all.count
        return all[index]
    }
    
    func tipForActivity(name: String) -> EducationalTip? {
        let all = tips()
        guard !all.isEmpty else { return nil }
        let key = name.lowercased()
        let matches = all.filter { tip in
            tip.tags.contains { tag in
                key.contains(tag.lowercased())
            }
        }
        if !matches.isEmpty {
            let index = Int.random(in: 0..<matches.count)
            return matches[index]
        }
        let index = Int.random(in: 0..<all.count)
        return all[index]
    }
    
    private static func dayKey(for date: Date) -> String {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    private static let builtInTips: [EducationalTip] = [
        EducationalTip(
            id: "daily_01",
            title: "Strength and bones",
            body: "Resistance training supports more than muscles: over time, it also stimulates bone density.",
            tags: ["strength", "bodyweight", "dumbbell", "kettlebell", "resistance"]
        ),
        EducationalTip(
            id: "daily_02",
            title: "Post‑meal walk",
            body: "A 2–10 minute walk after meals can support digestion and blood sugar control.",
            tags: ["walk"]
        ),
        EducationalTip(
            id: "daily_03",
            title: "Breathing and stress",
            body: "Lengthen your exhale (e.g., 4s in, 6–8s out). It’s a simple way to calm your nervous system.",
            tags: ["breathe", "meditation"]
        ),
        EducationalTip(
            id: "daily_04",
            title: "Smart recovery",
            body: "Better results come from recovery: sleep, hydration, and easy days matter as much as training.",
            tags: ["recovery", "sleep"]
        ),
        EducationalTip(
            id: "daily_05",
            title: "Mobility",
            body: "Mobility improves movement quality—5 minutes a day can make a real difference.",
            tags: ["mobility", "stretch", "yoga", "pilates"]
        ),
        EducationalTip(
            id: "daily_06",
            title: "HIIT with intention",
            body: "HIIT is effective but taxing. Alternate hard and easy days to stay consistent.",
            tags: ["hiit", "sprint", "interval"]
        ),
        EducationalTip(
            id: "daily_07",
            title: "Posture reset",
            body: "Shoulders away from ears, chest open, chin slightly tucked—your back will thank you.",
            tags: ["posture"]
        ),
        EducationalTip(
            id: "daily_08",
            title: "Hydration",
            body: "Keeping water in sight increases the chance you’ll drink. Environment beats willpower.",
            tags: ["hydration"]
        ),
        EducationalTip(
            id: "daily_09",
            title: "Core control",
            body: "A strong core means stability. Slow, controlled reps beat lots of fast reps.",
            tags: ["core", "plank", "dead bug"]
        ),
        EducationalTip(
            id: "daily_10",
            title: "Zone 2",
            body: "Easy, sustainable sessions (you can talk) build aerobic base and support recovery.",
            tags: ["walk", "run", "cycle"]
        ),
        EducationalTip(
            id: "daily_11",
            title: "Movement and mood",
            body: "Even small amounts of movement can improve mood—your brain responds quickly to motion.",
            tags: ["walk", "run", "yoga", "dance"]
        ),
        EducationalTip(
            id: "daily_12",
            title: "Small goals",
            body: "Aim for 70%. Doing something today beats waiting for the perfect session tomorrow.",
            tags: ["mindset"]
        ),
        EducationalTip(
            id: "daily_13",
            title: "Hydration habits",
            body: "The easiest way to drink more is to make water effortless: bottle visible and a glass ready.",
            tags: ["hydration"]
        ),
        EducationalTip(
            id: "daily_14",
            title: "Eyes and screens",
            body: "The 20‑20‑20 rule (every 20 min, 20 sec, at ~20 feet) reduces eye strain and neck tension.",
            tags: ["posture", "mindset"]
        ),
        EducationalTip(
            id: "daily_15",
            title: "Morning light",
            body: "5–10 minutes of natural light in the morning helps regulate daytime energy and nighttime sleep.",
            tags: ["sleep", "recovery"]
        ),
        EducationalTip(
            id: "daily_16",
            title: "Micro‑break",
            body: "60 seconds standing every hour reduces sedentary time—small, repeated often, is powerful.",
            tags: ["walk", "recovery"]
        ),
        EducationalTip(
            id: "daily_17",
            title: "Caffeine timing",
            body: "If sleep is fragile, try moving your last caffeine at least 6–8 hours before bed.",
            tags: ["sleep"]
        ),
        EducationalTip(
            id: "daily_18",
            title: "Protein at breakfast",
            body: "Protein and fiber in the morning can improve satiety and energy stability throughout the day.",
            tags: ["nutrition"]
        ),
        EducationalTip(
            id: "daily_19",
            title: "4–6 breathing",
            body: "Inhale 4 seconds, exhale 6 seconds for 2 minutes—often enough to reduce perceived stress.",
            tags: ["breathe", "meditation"]
        ),
        EducationalTip(
            id: "daily_20",
            title: "Neck‑shoulder mobility",
            body: "10 slow scap squeezes + 8 chin tucks can improve desk posture fast.",
            tags: ["posture", "stretch", "mobility"]
        ),
        EducationalTip(
            id: "daily_21",
            title: "Active recovery",
            body: "Easy days aren’t “skipped”: walking and mobility can speed up recovery.",
            tags: ["recovery", "walk", "mobility"]
        ),
        EducationalTip(
            id: "daily_22",
            title: "Hip flexors",
            body: "If you sit a lot, 45 seconds of hip‑flexor stretch per side can help your back too.",
            tags: ["stretch", "mobility", "posture"]
        ),
        EducationalTip(
            id: "daily_23",
            title: "Make healthy snacks easy",
            body: "Prep a healthy snack in advance—environment drives choices more than willpower.",
            tags: ["nutrition", "mindset"]
        ),
        EducationalTip(
            id: "daily_24",
            title: "Walking and creativity",
            body: "A short walk can unlock ideas—your brain likes rhythmic movement.",
            tags: ["walk", "mindset"]
        ),
        EducationalTip(
            id: "daily_25",
            title: "Minimum effective strength",
            body: "2–3 well‑done basics (squat, hinge, push) can be enough to progress if you’re consistent.",
            tags: ["strength", "bodyweight", "resistance"]
        ),
        EducationalTip(
            id: "daily_26",
            title: "Sleep routine",
            body: "More than perfect duration, consistency matters—similar schedules improve sleep quality.",
            tags: ["sleep", "recovery"]
        ),
        EducationalTip(
            id: "daily_27",
            title: "Adjust intensity",
            body: "If today you’re low on energy, do an easier version. The goal is to keep the chain going.",
            tags: ["mindset", "recovery"]
        ),
        EducationalTip(
            id: "daily_28",
            title: "After‑meal movement",
            body: "Moving 2–10 minutes after meals can support energy and digestion—without a full workout.",
            tags: ["walk"]
        ),
        EducationalTip(
            id: "daily_29",
            title: "Water and electrolytes",
            body: "If you sweat a lot, replenishing fluids matters. In some cases, electrolytes help too (without overdoing it).",
            tags: ["hydration", "recovery"]
        ),
        EducationalTip(
            id: "daily_30",
            title: "Jaw tension",
            body: "If you clench your teeth while working, relax your jaw and take 3 slow breaths—often it changes instantly.",
            tags: ["mindset", "posture"]
        )
    ]
}
