//
//  LanguageDataModel.swift
//  Seizcare
//

import Foundation

// MARK: - AppLanguage Enum
enum AppLanguage: String, Codable {
    case english = "English"
    case hindi = "Hindi"
    case marathi = "Marathi"
    case telugu = "Telugu"
    case bengali = "Bengali"
    case tamil = "Tamil"
}

// MARK: - LanguageDataModel
final class LanguageDataModel {

    static let shared = LanguageDataModel()

    // In-memory cache
    private var currentLanguage: AppLanguage = .english

    private init() {}

    // MARK: - Refresh (async, Supabase → cache)
    /// Fetches the user's language preference from Supabase.
    /// If no preference exists, it defaults to `.english` and inserts a new record to Supabase.
    func refreshLanguage() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            if let dto = try await SupabaseService.shared.fetchLanguage(userId: userId) {
                // Record found in database, update cache
                if let language = AppLanguage(rawValue: dto.languageCode) {
                    currentLanguage = language
                }
            } else {
                // No record found, create default (.english) in Supabase and cache
                let defaultLanguage: AppLanguage = .english
                currentLanguage = defaultLanguage
                let dto = LanguageDTO(userId: userId, languageCode: defaultLanguage.rawValue)
                try await SupabaseService.shared.insertLanguage(dto: dto)
            }
        } catch {
            print("⚠️ [LanguageDataModel] refreshLanguage failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Accessors
    /// Returns the currently cached language.
    func getCurrentLanguage() -> AppLanguage {
        return currentLanguage
    }

    // MARK: - Set Preference
    /// Updates the in-memory cache and pushes the change to Supabase.
    func setLanguage(language: AppLanguage) {
        currentLanguage = language
        
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        
        Task {
            do {
                // Check if a record exists
                if let _ = try await SupabaseService.shared.fetchLanguage(userId: userId) {
                    // Update existing record
                    let dto = LanguageDTO(userId: userId, languageCode: language.rawValue)
                    try await SupabaseService.shared.updateLanguage(dto: dto)
                } else {
                    // Insert new record
                    let dto = LanguageDTO(userId: userId, languageCode: language.rawValue)
                    try await SupabaseService.shared.insertLanguage(dto: dto)
                }
            } catch {
                print("⚠️ [LanguageDataModel] setLanguage failed: \(error.localizedDescription)")
            }
        }
    }
}
