//
//  OnboardingPreviewView.swift
//  Pace
//
//  Preview version of onboarding flow (does not reset onboarding state).
//

import SwiftUI

struct OnboardingPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isCompleted = false
    
    var body: some View {
        NavigationStack {
            OnboardingContentView(isCompleted: $isCompleted)
                .onChange(of: isCompleted) { _, completed in
                    if completed {
                        dismiss()
                    }
                }
        }
    }
}

// Separate view to handle the onboarding flow with dismiss capability
private struct OnboardingContentView: View {
    @Binding var isCompleted: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: OnboardingView.Step = .welcome
    @State private var userProfile = UserProfile.default
    @Environment(\.colorScheme) private var colorScheme
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.top, 60)
                    .padding(.horizontal, 40)
                
                // Content based on step
                contentView
                    .padding(.top, 40)
                
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: goBackOrDismiss) {
                    Image(systemName: "arrow.left")
                        .font(.paceRounded(.title3, weight: .semibold))
                        .foregroundColor(Color(.label))
                }
                .accessibilityLabel(AppSettingsManager.shared.localized(.accBack))
            }
        }
    }
    
    private func goBackOrDismiss() {
        if currentStep == .welcome {
            dismiss()
        } else if let currentIndex = OnboardingView.Step.allCases.firstIndex(of: currentStep),
                  currentIndex > 0 {
            withAnimation {
                currentStep = OnboardingView.Step.allCases[currentIndex - 1]
            }
        }
    }
    
    private func goNext() {
        if let currentIndex = OnboardingView.Step.allCases.firstIndex(of: currentStep),
           currentIndex < OnboardingView.Step.allCases.count - 1 {
            withAnimation {
                currentStep = OnboardingView.Step.allCases[currentIndex + 1]
            }
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 1, green: 0.267, blue: 0))
                    .frame(width: geo.size.width * currentStep.progress, height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch currentStep {
        case .welcome:
            WelcomeStep {
                goNext()
            }
        case .bodyData:
            BodyDataStep(profile: $userProfile) {
                goNext()
            }
        case .goalConfirm:
            GoalConfirmStep(profile: userProfile) {
                isCompleted = true
            }
        }
    }
}

#Preview {
    OnboardingPreviewView()
}
