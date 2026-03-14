//
//  SensitivityDataModel.swift
//  Seizcare
//

import Foundation

// MARK: - SensitivityLevel Enum
enum SensitivityLevel: String, Codable {
    case low
    case medium
    case high
}

// MARK: - SensitivityDataModel
final class SensitivityDataModel {

    static let shared = SensitivityDataModel()

    // In-memory cache
    private var currentSensitivity: SensitivityLevel = .medium

    private init() {}

    // MARK: - Refresh (async, Supabase → cache)
    /// Fetches the user's sensitivity preference from Supabase.
    /// If no preference exists, it defaults to `.medium` and inserts a new record to Supabase.
    func refreshSensitivity() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            if let dto = try await SupabaseService.shared.fetchSensitivity(userId: userId) {
                // Record found in database, update cache
                if let level = SensitivityLevel(rawValue: dto.sensitivityLevel) {
                    currentSensitivity = level
                }
            } else {
                // No record found, create default (.medium) in Supabase and cache
                let defaultLevel: SensitivityLevel = .medium
                currentSensitivity = defaultLevel
                let dto = SensitivityDTO(userId: userId, sensitivityLevel: defaultLevel.rawValue)
                try await SupabaseService.shared.insertSensitivity(dto: dto)
            }
        } catch {
            print("⚠️ [SensitivityDataModel] refreshSensitivity failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Accessors
    /// Returns the currently cached sensitivity level.
    func getCurrentSensitivity() -> SensitivityLevel {
        return currentSensitivity
    }

    // MARK: - Set Preference
    /// Updates the in-memory cache and pushes the change to Supabase.
    func setSensitivity(level: SensitivityLevel) {
        currentSensitivity = level
        
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        
        Task {
            do {
                let dto = SensitivityDTO(userId: userId, sensitivityLevel: level.rawValue)
                try await SupabaseService.shared.updateSensitivity(dto: dto)
            } catch {
                print("⚠️ [SensitivityDataModel] setSensitivity failed: \(error.localizedDescription)")
            }
        }
    }
}
