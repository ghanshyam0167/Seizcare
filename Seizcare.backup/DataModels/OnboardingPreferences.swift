//
//  OnboardingPreferences.swift
//  Seizcare
//

import Foundation

/// A temporary local store for onboarding preferences, ensuring we do not try to save
/// to Supabase before a user is completely signed up.
final class OnboardingPreferences {
    static let shared = OnboardingPreferences()

    var language: AppLanguage = .english
    var sensitivity: SensitivityLevel = .medium

    private init() {}
}
