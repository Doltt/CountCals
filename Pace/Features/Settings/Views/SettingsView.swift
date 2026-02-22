//
//  SettingsView.swift
//  Pace
//
//  Settings page with welcome, language, and theme options.

import SwiftUI
import UIKit

struct SettingsView: View {
    @State private var settings = AppSettingsManager.shared
    @State private var showingLanguagePicker = false
    @State private var showingThemePicker = false
    @State private var showingBodyData = false
    @State private var showingOnboarding = false
    @State private var viewModel = DashboardViewModel()
    
    private func L(_ key: LocalizedKey) -> String {
        settings.localized(key)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                welcomeSection
                
                // Body Data Section
                bodyDataSection
                
                // Appearance Section
                appearanceSection
                
                // Onboarding Section
                onboardingSection
                
                // About Section
                aboutSection
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerSheet(settings: settings)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerSheet(settings: settings)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBodyData) {
            ProfileView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingPreviewView()
        }
    }
    
    // MARK: - Body Data Section
    
    private var bodyDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.healthProfile))
                .font(.paceRounded(.subheadline))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    title: L(.bodyData),
                    subtitle: L(.bodyDataSubtitle),
                    value: "\(viewModel.userProfile.weight)kg, \(viewModel.userProfile.height)cm"
                ) {
                    showingBodyData = true
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L(.welcome))
                .font(.paceRounded(.largeTitle, weight: .black))
            
            Text(L(.welcomeSubtitle))
                .font(.paceRounded(.subheadline))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
    
    
    // MARK: - Onboarding Section
    
    private var onboardingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.support))
                .font(.paceRounded(.subheadline))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "sparkles",
                    iconColor: Color(red: 1, green: 0.267, blue: 0),
                    title: L(.viewOnboarding),
                    subtitle: L(.viewOnboardingSubtitle)
                ) {
                    showingOnboarding = true
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.appearance))
                .font(.paceRounded(.subheadline))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: L(.language),
                    subtitle: L(.languageSubtitle),
                    value: settings.language.displayName
                ) {
                    showingLanguagePicker = true
                }
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsRow(
                    icon: settings.theme.icon,
                    iconColor: .orange,
                    title: L(.theme),
                    subtitle: L(.themeSubtitle),
                    value: settings.language == .chinese ? settings.theme.displayNameCN : settings.theme.displayName
                ) {
                    showingThemePicker = true
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L(.about))
                .font(.paceRounded(.subheadline))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bubble.left.and.bubble.right",
                    iconColor: .green,
                    title: L(.feedback),
                    subtitle: L(.feedbackSubtitle)
                ) {
                    openAppStoreFeedback()
                }
                
                Divider()
                    .padding(.leading, 52)
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.paceRounded(.title3))
                        .foregroundStyle(.gray)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L(.version))
                            .font(.paceRounded(.body))
                            .foregroundStyle(.primary)
                        
                        Text(L(.versionSubtitle))
                            .font(.paceRounded(.caption))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.paceRounded(.body))
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func openAppStoreFeedback() {
        // Open App Store feedback page
        // Format: https://apps.apple.com/app/id{APP_ID}?action=write-review
        // Or use StoreKit's SKStoreReviewController for in-app review
        
        // Option 1: Direct App Store URL (requires App ID)
        // Replace YOUR_APP_ID with actual App Store ID
        if let appStoreURL = URL(string: "https://apps.apple.com/app/id6739782001?action=write-review") {
            UIApplication.shared.open(appStoreURL)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.paceRounded(.title3))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.paceRounded(.body))
                        .foregroundStyle(.primary)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.paceRounded(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let value {
                    Text(value)
                        .font(.paceRounded(.body))
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.paceRounded(.caption))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Language Picker Sheet

private struct LanguagePickerSheet: View {
    @Bindable var settings: AppSettingsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text(settings.localized(.language))
                .font(.paceRounded(.headline, weight: .black))
                .padding()
            
            VStack(spacing: 8) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        settings.language = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.flag)
                                .font(.paceRounded(.title2))
                            
                            Text(language.displayName)
                                .font(.paceRounded(.body))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if settings.language == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(settings.language == language ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Theme Picker Sheet

private struct ThemePickerSheet: View {
    @Bindable var settings: AppSettingsManager
    @Environment(\.dismiss) private var dismiss
    
    private var themeDisplayName: (AppTheme) -> String {
        { theme in
            settings.language == .chinese ? theme.displayNameCN : theme.displayName
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(settings.localized(.theme))
                .font(.paceRounded(.headline, weight: .black))
                .padding()
            
            VStack(spacing: 8) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        settings.theme = theme
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: theme.icon)
                                .font(.paceRounded(.title2))
                                .foregroundStyle(theme == .dark ? .purple : (theme == .light ? .orange : .gray))
                                .frame(width: 32)
                            
                            Text(themeDisplayName(theme))
                                .font(.paceRounded(.body))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if settings.theme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(settings.theme == theme ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}
