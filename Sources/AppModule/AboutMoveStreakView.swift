import SwiftUI
import UIKit

struct AboutMoveStreakView: View {
    @ObservedObject var manager: StreakManager
    
    private var versionText: String {
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
        let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
        return L10n.aboutVersion(version, build)
    }

    private var deviceInfoText: String {
        "iOS \(UIDevice.current.systemVersion) • \(UIDevice.current.model)"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                heroCard
                quickStartCard
                featuresCard
                privacyCard
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(L10n.aboutTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MoveStreak")
                        .appTitle(size: 24)
                    Text(versionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(deviceInfoText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            
            Text(L10n.aboutDescription)
                .appBody()
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard(accent: .blue)
    }

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.aboutQuickStart)
                .appHeadline()
            
            aboutRow(icon: "figure.walk", color: .blue, title: L10n.aboutOpenToday, subtitle: L10n.aboutOpenTodayDesc)
            aboutRow(icon: "drop.fill", color: .cyan, title: L10n.aboutTrackWater, subtitle: L10n.aboutTrackWaterDesc)
            aboutRow(icon: "trophy.fill", color: .purple, title: L10n.aboutCheckDifficulty, subtitle: L10n.aboutCheckDifficultyDesc)
        }
        .appCard()
    }
    
    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.aboutFeatures)
                .appHeadline()
            
            aboutRow(icon: "clock.fill", color: .blue, title: L10n.aboutGuidedActivities, subtitle: L10n.aboutGuidedActivitiesDesc)
            aboutRow(icon: "flame.fill", color: .orange, title: L10n.aboutStreakProgress, subtitle: L10n.aboutStreakProgressDesc)
            aboutRow(icon: "heart.text.square.fill", color: .pink, title: L10n.aboutWellness, subtitle: L10n.aboutWellnessDesc)
        }
        .appCard()
    }
    
    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.aboutPrivacy)
                .appHeadline()
            
            aboutRow(icon: "iphone.gen1", color: .blue, title: L10n.aboutOnDevice, subtitle: L10n.aboutOnDeviceDesc)
            aboutRow(icon: "person.crop.circle.badge.xmark", color: .green, title: L10n.aboutNoLogin, subtitle: L10n.aboutNoLoginDesc)
            aboutRow(icon: "lock.shield", color: .secondary, title: L10n.aboutLocalStorage, subtitle: L10n.aboutLocalStorageDesc)
        }
        .appCard()
    }
    
    private func aboutRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appHeadline()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
    }
}
