//
//  SupabaseService.swift
//  Seizcare
//
//  Created by GS Agrawal on 11/03/26.
//

import Foundation
import Supabase

// MARK: - SupabaseService

final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://rewuxzcdgivbwmakwjtc.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJld3V4emNkZ2l2YndtYWt3anRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTQ2OTEsImV4cCI6MjA4ODc5MDY5MX0.kk1Mq-O6SfQ60TZagcp202cGqNB08ywUPWgxlFdiXp4"
        )
    }

    // MARK: - Auth

    /// Sign in with email and password. Returns the Supabase user UUID on success.
    func signIn(email: String, password: String) async throws -> UUID {
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user.id
    }

    /// Sign up with email and password. Returns the Supabase user UUID on success.
    func signUp(email: String, password: String) async throws -> UUID {
        let response = try await client.auth.signUp(email: email, password: password)
        // In Supabase Swift SDK v2, AuthResponse.user is non-optional
        return response.user.id
    }

    /// Sign out the current user.
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Returns the currently authenticated user's UUID, or nil if not logged in.
    func currentUserId() async -> UUID? {
        return try? await client.auth.user().id
    }

    // MARK: - Users Table

    func fetchUsers() async throws -> [UserDTO] {
        let rows: [UserDTO] = try await client
            .from("users")
            .select()
            .execute()
            .value
        return rows
    }

    func fetchUser(id: UUID) async throws -> UserDTO? {
        // First, fetch raw data so we can log exactly what Supabase returned
        let response = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("[fetchUser] raw JSON:", raw)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rows = try decoder.decode([UserDTO].self, from: response.data)
        return rows.first
    }

    func insertUser(_ dto: UserDTO) async throws {
        try await client
            .from("users")
            .insert(dto)
            .execute()
    }

    func updateUser(_ dto: UserDTO) async throws {
        try await client
            .from("users")
            .update(dto)
            .eq("id", value: dto.id.uuidString)
            .execute()
    }

    // MARK: - Seizure Records Table

    func fetchSeizureRecords(userId: UUID) async throws -> [SeizureRecordDTO] {
        let rows: [SeizureRecordDTO] = try await client
            .from("seizure_records")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date_time", ascending: false)
            .execute()
            .value
        return rows
    }

    func insertSeizureRecord(_ dto: SeizureRecordDTO) async throws {
        try await client
            .from("seizure_records")
            .insert(dto)
            .execute()
    }

    func deleteSeizureRecord(id: UUID) async throws {
        try await client
            .from("seizure_records")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateSeizureRecord(_ dto: SeizureRecordDTO) async throws {
        try await client
            .from("seizure_records")
            .update(dto)
            .eq("id", value: dto.id.uuidString)
            .execute()
    }

    // MARK: - Seizure Triggers Table

    func fetchTriggers(recordId: UUID) async throws -> [SeizureTriggerDTO] {
        let rows: [SeizureTriggerDTO] = try await client
            .from("seizure_triggers")
            .select()
            .eq("record_id", value: recordId.uuidString)
            .execute()
            .value
        return rows
    }

    func insertTriggers(_ dtos: [SeizureTriggerDTO]) async throws {
        guard !dtos.isEmpty else { return }
        try await client
            .from("seizure_triggers")
            .insert(dtos)
            .execute()
    }

    func deleteTriggers(recordId: UUID) async throws {
        try await client
            .from("seizure_triggers")
            .delete()
            .eq("record_id", value: recordId.uuidString)
            .execute()
    }

    // MARK: - Emergency Contacts Table

    func fetchContacts(userId: UUID) async throws -> [EmergencyContactDTO] {
        let rows: [EmergencyContactDTO] = try await client
            .from("emergency_contacts")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return rows
    }

    func insertContact(_ dto: EmergencyContactDTO) async throws {
        try await client
            .from("emergency_contacts")
            .insert(dto)
            .execute()
    }

    func deleteContact(id: UUID) async throws {
        try await client
            .from("emergency_contacts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Notifications Table

    func fetchNotifications(userId: UUID) async throws -> [NotificationDTO] {
        let rows: [NotificationDTO] = try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date_time", ascending: false)
            .execute()
            .value
        return rows
    }

    func insertNotification(_ dto: NotificationDTO) async throws {
        try await client
            .from("notifications")
            .insert(dto)
            .execute()
    }

    // MARK: - Sleep Data Table

    func fetchSleepEntries(userId: UUID) async throws -> [SleepEntryDTO] {
        let rows: [SleepEntryDTO] = try await client
            .from("sleep_data")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        return rows
    }

    func insertSleepEntry(_ dto: SleepEntryDTO) async throws {
        try await client
            .from("sleep_data")
            .insert(dto)
            .execute()
    }
}

// MARK: - SupabaseServiceError

enum SupabaseServiceError: Error, LocalizedError {
    case authFailed(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg): return "Auth failed: \(msg)"
        case .notFound(let msg):   return "Not found: \(msg)"
        }
    }
}

// MARK: - DTOs (snake_case → Supabase column mapping)

// Each DTO uses CodingKeys to map Swift camelCase to Supabase snake_case column names.
// They are separate from the app-level model structs to keep the persistence concern isolated.

struct UserDTO: Codable {
    let id: UUID
    let fullName: String?
    let email: String?
    let contactNumber: String?
    let gender: String?
    let dateOfBirth: String?     // Supabase returns "yyyy-MM-dd" — keep as String
    let height: Double?
    let weight: Double?
    let bloodGroup: String?
    let createdAt: String?       // Extra column returned by Supabase — absorb so decode never fails

    enum CodingKeys: String, CodingKey {
        case id
        case fullName       = "full_name"
        case email
        case contactNumber  = "contact_number"
        case gender
        case dateOfBirth    = "date_of_birth"
        case height
        case weight
        case bloodGroup     = "blood_group"
        case createdAt      = "created_at"
    }

    // Convert domain model → DTO (for INSERT / UPDATE — always has full data)
    init(from user: User) {
        self.id            = user.id
        self.fullName      = user.fullName
        self.email         = user.email
        self.contactNumber = user.contactNumber
        self.gender        = user.gender.rawValue
        self.dateOfBirth   = UserDTO.dateFormatter.string(from: user.dateOfBirth)
        self.height        = user.height
        self.weight        = user.weight
        self.bloodGroup    = user.bloodGroup
        self.createdAt     = nil
    }

    // Convert DTO → domain model — parse the "yyyy-MM-dd" date string manually
    func toDomain() -> User {
        let dob: Date = dateOfBirth.flatMap { UserDTO.dateFormatter.date(from: $0) } ?? Date()
        return User(
            id:            id,
            fullName:      fullName      ?? "",
            email:         email         ?? "",
            contactNumber: contactNumber ?? "",
            gender:        Gender(rawValue: gender ?? "") ?? .unspecified,
            dateOfBirth:   dob,
            password:      "",
            height:        height,
            weight:        weight,
            bloodGroup:    bloodGroup
        )
    }

    // Shared formatter for "yyyy-MM-dd"
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
}


struct SeizureRecordDTO: Codable {
    let id: UUID
    let userId: UUID
    let entryType: String
    let dateTime: Date
    let description: String?
    let type: String?
    let duration: Double?
    let spo2: Int?
    let heartRate: Int?
    let location: String?
    let title: String?
    let symptoms: [String]?
    let timeBucket: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId      = "user_id"
        case entryType   = "entry_type"
        case dateTime    = "date_time"
        case description
        case type
        case duration
        case spo2
        case heartRate   = "heart_rate"
        case location
        case title
        case symptoms
        case timeBucket  = "time_bucket"
    }

    init(from record: SeizureRecord) {
        self.id          = record.id
        self.userId      = record.userId
        self.entryType   = record.entryType.rawValue
        self.dateTime    = record.dateTime
        self.description = record.description
        self.type        = record.type?.rawValue
        self.duration    = record.duration
        self.spo2        = record.spo2
        self.heartRate   = record.heartRate
        self.location    = record.location
        self.title       = record.title
        self.symptoms    = record.symptoms
        self.timeBucket  = record.timeBucket.rawValue
    }

    func toDomain(triggers: [SeizureTrigger] = []) -> SeizureRecord {
        SeizureRecord(
            id:          id,
            userId:      userId,
            entryType:   RecordEntryType(rawValue: entryType) ?? .manual,
            dateTime:    dateTime,
            description: description,
            type:        type.flatMap { SeizureType(rawValue: $0) },
            duration:    duration,
            spo2:        spo2,
            heartRate:   heartRate,
            location:    location,
            title:       title,
            symptoms:    symptoms,
            triggers:    triggers.isEmpty ? nil : triggers,
            timeBucket:  SeizureTimeBucket(rawValue: timeBucket)
        )
    }
}

struct SeizureTriggerDTO: Codable {
    let id: UUID
    let recordId: UUID
    let trigger: String

    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case trigger
    }

    init(recordId: UUID, trigger: SeizureTrigger) {
        self.id       = UUID()
        self.recordId = recordId
        self.trigger  = trigger.rawValue
    }
}

struct EmergencyContactDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let contactNumber: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId        = "user_id"
        case name
        case contactNumber = "contact_number"
    }

    init(from contact: EmergencyContact) {
        self.id            = contact.id
        self.userId        = contact.userId
        self.name          = contact.name
        self.contactNumber = contact.contactNumber
    }

    func toDomain() -> EmergencyContact {
        EmergencyContact(id: id, userId: userId, name: name, contactNumber: contactNumber)
    }
}

struct NotificationDTO: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let iconName: String
    let dateTime: Date
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId      = "user_id"
        case title
        case iconName    = "icon_name"
        case dateTime    = "date_time"
        case description
    }

    init(from notification: AppNotification) {
        self.id          = notification.id
        self.userId      = notification.userId
        self.title       = notification.title
        self.iconName    = notification.iconName
        self.dateTime    = notification.dateTime
        self.description = notification.description
    }

    func toDomain() -> AppNotification {
        AppNotification(
            id:          id,
            userId:      userId,
            title:       title,
            iconName:    iconName,
            dateTime:    dateTime,
            description: description
        )
    }
}

struct SleepEntryDTO: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let hours: Double

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case hours
    }

    init(userId: UUID, date: Date, hours: Double) {
        self.id     = UUID()
        self.userId = userId
        self.date   = date
        self.hours  = hours
    }
}
