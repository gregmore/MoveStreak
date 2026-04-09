import SwiftUI

struct HydrationCheckInSheet: View {
    @ObservedObject var manager: StreakManager
    @Environment(\.dismiss) private var dismiss
    @State private var glasses: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("Hydration")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("How many glasses of water have you had today?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 10) {
                    Text("\(glasses)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .appNumericTextTransition()
                    
                    Stepper(value: $glasses, in: 0...15) {
                        Text("Glasses")
                    }
                }
                .appMeshCard(accent: .cyan, colors: [.cyan, .blue, .mint, .purple])
                
                Text("Each glass gives you points. If you lower the number, points will go down too.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        manager.skipHydrationCheckInToday()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.setWaterIntakeForToday(glasses)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            glasses = manager.waterIntake
        }
    }
}
