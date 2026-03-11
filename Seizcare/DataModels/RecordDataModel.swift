//
//  RecordDataModel.swift
//  Seizcare
//

import Foundation
import Charts


//  Seizure Type

enum SeizureType: String, Codable, CaseIterable {
    case mild
    case moderate
    case severe
}


//  Seizure Trigger

enum SeizureTrigger: String, Codable, CaseIterable, Plottable {
    case stress
    case sleepDeprivation
    case missedMedication
    case alcohol
    case flashingLights
    case illness
    case unknown
}


// MARK: - Seizure Time Bucket

enum SeizureTimeBucket: String, Codable, CaseIterable {
    case morning
    case afternoon
    case evening
    case night
    case unknown

    var displayText: String {
        switch self {
        case .morning:   return "Morning"
        case .afternoon: return "Afternoon"
        case .evening:   return "Evening"
        case .night:     return "Night"
        case .unknown:   return "Unknown"
        }
    }
}


// Entry Type

enum RecordEntryType: String, Codable {
    case automatic
    case manual
}


// Seizure Record Model

struct SeizureRecord: Identifiable, Codable, Equatable {

    let id: UUID
    let userId: UUID
    var entryType: RecordEntryType

    // Core
    var dateTime: Date
    var description: String?

    // Automatic fields
    var type: SeizureType?
    var duration: TimeInterval?
    var spo2: Int?
    var heartRate: Int?
    var location: String?

    // Manual fields
    var title: String?
    var symptoms: [String]?

    // Dashboard / Analytics
    var triggers: [SeizureTrigger]?
    var timeBucket: SeizureTimeBucket

    
    //  Init
    
    init(
        id: UUID,
        userId: UUID,
        entryType: RecordEntryType,
        dateTime: Date,
        description: String? = nil,
        type: SeizureType? = nil,
        duration: TimeInterval? = nil,
        spo2: Int? = nil,
        heartRate: Int? = nil,
        location: String? = nil,
        title: String? = nil,
        symptoms: [String]? = nil,
        triggers: [SeizureTrigger]? = nil,
        timeBucket: SeizureTimeBucket? = nil
    ) {
        self.id          = id
        self.userId      = userId
        self.entryType   = entryType
        self.dateTime    = dateTime
        self.description = description
        self.type        = type
        self.duration    = duration
        self.spo2        = spo2
        self.heartRate   = heartRate
        self.location    = location
        self.title       = title
        self.symptoms    = symptoms
        self.triggers    = triggers

        if let explicitBucket = timeBucket {
            self.timeBucket = explicitBucket
        } else {
            let hour = Calendar.current.component(.hour, from: dateTime)
            switch hour {
            case 5..<12:        self.timeBucket = .morning
            case 12..<17:       self.timeBucket = .afternoon
            case 17..<22:       self.timeBucket = .evening
            case 22...23, 0..<5: self.timeBucket = .night
            default:            self.timeBucket = .unknown
            }
        }
    }

    static func == (lhs: SeizureRecord, rhs: SeizureRecord) -> Bool {
        lhs.id == rhs.id
    }
}


//  Record Data Model

final class SeizureRecordDataModel {

    static let shared = SeizureRecordDataModel()

    /// In-memory cache – DashboardDataModel reads from this via the sync getters.
    private var records: [SeizureRecord] = []

    
    //  Init
    
    private init() {
        
        archiveURL = documentsDirectory
            .appendingPathComponent("seizureRecords")
            .appendingPathExtension("plist")
        loadRecords()
        
        
        

    /// Fetches all records for the current user from Supabase (including triggers)
    /// and refreshes the local cache.
    func refreshRecords() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        do {
            let dtos = try await SupabaseService.shared.fetchSeizureRecords(userId: userId)

            // Fetch triggers for all records in parallel
            var loaded: [SeizureRecord] = []
            for dto in dtos {
                let triggerDTOs = try await SupabaseService.shared.fetchTriggers(recordId: dto.id)
                let triggers = triggerDTOs.compactMap { SeizureTrigger(rawValue: $0.trigger) }
                loaded.append(dto.toDomain(triggers: triggers))
            }
            records = loaded
        } catch {
            print("⚠️ [SeizureRecordDataModel] refreshRecords failed:", error.localizedDescription)
        }
    }

    
    //  Public Access
    
    func getAllRecords() -> [SeizureRecord] {
        records
    }

    func getRecordsForCurrentUser() -> [SeizureRecord] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            return []
        }
        return records.filter { $0.userId == currentUser.id }
    }


    //Add Records
    
    func addAutomaticRecord(
        type: SeizureType,
        dateTime: Date,
        duration: TimeInterval,
        spo2: Int,
        heartRate: Int,
        location: String,
        triggers: [SeizureTrigger]? = nil,
        description: String? = nil
    ) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else { return }

        let record = SeizureRecord(
            id: UUID(),
            userId: currentUser.id,
            entryType: .automatic,
            dateTime: dateTime,
            description: description,
            type: type,
            duration: duration,
            spo2: spo2,
            heartRate: heartRate,
            location: location,
            triggers: triggers
        )

        records.append(record)
        persistRecord(record)
    }

    func addManualRecord(_ record: SeizureRecord) {
        records.append(record)
        persistRecord(record)
    }

   
    //  Update / Delete
    
    func updateRecord(_ record: SeizureRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        }
        Task {
            do {
                // Update the main row
                try await SupabaseService.shared.updateSeizureRecord(SeizureRecordDTO(from: record))
                // Refresh triggers: delete old + insert new
                try await SupabaseService.shared.deleteTriggers(recordId: record.id)
                if let triggers = record.triggers, !triggers.isEmpty {
                    let dtos = triggers.map { SeizureTriggerDTO(recordId: record.id, trigger: $0) }
                    try await SupabaseService.shared.insertTriggers(dtos)
                }
            } catch {
                print("⚠️ [SeizureRecordDataModel] updateRecord failed:", error.localizedDescription)
            }
        }
    }

    func updateRecordDescription(id: UUID, newDescription: String) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            var record = records[index]
            record.description = newDescription
            records[index] = record
            updateRecord(record)
        }
    }

    func deleteRecord(at index: Int) {
        guard records.indices.contains(index) else { return }
        let recordId = records[index].id
        records.remove(at: index)
        saveRecords()
    }

   
    
   
    private func loadRecords() {
        
        if let saved = loadFromDisk() {
            records = saved
        } else {
            // Start with an empty list for new users
             records = loadSampleRecords()
            saveRecords()
        }
    }

    private func loadFromDisk() -> [SeizureRecord]? {
        guard let data = try? Data(contentsOf: archiveURL) else { return nil }
        return try? PropertyListDecoder().decode([SeizureRecord].self, from: data)
    }

    private func saveRecords() {
        let data = try? PropertyListEncoder().encode(records)
        try? data?.write(to: archiveURL, options: .noFileProtection)
    }

    
    //  Sample Data (UPDATED)
    
    private func loadSampleRecords() -> [SeizureRecord] {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return [] }

        let calendar = Calendar.current
        let now = Date()

        let locations = ["Bedroom", "Office", "Living Room", "Bathroom"]
        let autoDescriptions = [
            "Auto detected during rest",
            "Detected during sleep",
            "Detected after physical exertion",
            "Detected during stress period"
        ]
        let manualTitles = [
            "Aura Episode",
            "Night Seizure",
            "Post Medication Miss",
            "Stress Triggered Episode"
        ]
        let symptomsPool: [[Symptom]] = [
            [.dizziness, .visualChange],
            [.confused, .headache],
            [.tired],
            [.bodyAche, .weakness]
        ]

        let triggersPool: [[SeizureTrigger]] = [
            [.stress],
            [.sleepDeprivation],
            [.missedMedication],
            [.alcohol],
            [.stress, .sleepDeprivation]
        ]

        var records: [SeizureRecord] = []

        for _ in 0..<50 {
            let daysAgo = Int.random(in: 0...180) // past 6 months
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!

            let isAutomatic = Bool.random()

            if isAutomatic {
                records.append(
                    SeizureRecord(
                        id : UUID(),
                        userId: userId,
                        entryType: .automatic,
                        dateTime: date,
                        description: autoDescriptions.randomElement()!,
                        type: SeizureType.allCases.randomElement()!,
                        duration: TimeInterval(Int.random(in: 30...180)),
                        spo2: Int.random(in: 85...97),
                        heartRate: Int.random(in: 90...160),
                        location: locations.randomElement()!,
                        triggers: triggersPool.randomElement()!
                    )
                )
            } else {
                records.append(
                    SeizureRecord(
                        id : UUID(),
                        userId: userId,
                        entryType: .manual,
                        dateTime: date,
                        type: SeizureType.allCases.randomElement()!, duration: TimeInterval(Int.random(in: 40...150)),
                        title: manualTitles.randomElement()!,
                        symptoms: (symptomsPool.randomElement() ?? []).map { $0.rawValue },
                        triggers: triggersPool.randomElement()!
                    )
                )
            }
        }
    }
}


// Extra Helper

extension SeizureRecordDataModel {
    func getLatestTwoRecordsForCurrentUser() -> [SeizureRecord] {
        getRecordsForCurrentUser()
            .sorted { $0.dateTime > $1.dateTime }
            .prefix(2)
            .map { $0 }
    }

    func getSpO2Timeline(for record: SeizureRecord) -> [SpO2TimelinePoint] {
        guard record.entryType == .automatic else { return [] }
        return SpO2TimelineBuilder.generateTimeline(seizureTime: record.dateTime)
    }
}
