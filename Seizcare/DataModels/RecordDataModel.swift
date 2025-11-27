//
//  RecordDataModel.swift
//  Seizcare
//
//  Created by GS Agrawal on 24/11/25.
//

import Foundation

// Enum for Seizure Type
enum SeizureType: String, Codable {
    case mild
    case moderate
    case severe
}

// Enum for Entry Type (NEW)
enum RecordEntryType: String, Codable {
    case automatic
    case manual
}

// Seizure Record Model
struct SeizureRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var entryType: RecordEntryType

    // Common fields
    var dateTime: Date
    var description: String?

    // Automatic log fields
    var type: SeizureType?
    var duration: TimeInterval?
    var spo2: Int?
    var heartRate: Int?
    var location: String?

    // Manual log fields
    var title: String?
    var symptoms: [String]?

    init(
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
        symptoms: [String]? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.entryType = entryType
        self.dateTime = dateTime
        self.description = description
        self.type = type
        self.duration = duration
        self.spo2 = spo2
        self.heartRate = heartRate
        self.location = location
        self.title = title
        self.symptoms = symptoms
    }

    static func == (lhs: SeizureRecord, rhs: SeizureRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// Data Model Class
class SeizureRecordDataModel {

    static let shared = SeizureRecordDataModel()

    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL

    private var records: [SeizureRecord] = []

    // Init
    private init() {
        archiveURL = documentsDirectory
            .appendingPathComponent("seizureRecords")
            .appendingPathExtension("plist")
        
        loadRecords()
    }

    //Public Methods

    func getAllRecords() -> [SeizureRecord] {
        return records
    }

    func getRecordsForCurrentUser() -> [SeizureRecord] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("⚠️ No user logged in.")
            return []
        }
        loadRecords()
        return records.filter { $0.userId == currentUser.id }
    }


    // ADD RECORDS

  
    func addAutomaticRecord(
        type: SeizureType,
        dateTime: Date,
        duration: TimeInterval,
        spo2: Int,
        heartRate: Int,
        location: String,
        description: String? = nil
    ) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else { return }

        let record = SeizureRecord(
            userId: currentUser.id,
            entryType: .automatic,
            dateTime: dateTime,
            description: description,
            type: type,
            duration: duration,
            spo2: spo2,
            heartRate: heartRate,
            location: location
        )

        records.append(record)
        saveRecords()
    }


    func addManualRecord(_ record: SeizureRecord) {
        print("🔥 addManualRecord CALLED")
        records.append(record)
        saveRecords()
    }
    // UPDATE / DELETE

    func updateRecord(_ record: SeizureRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveRecords()
        }
    }
    func updateRecordDescription(id: UUID, newDescription: String) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            var record = records[index]
            record.description = newDescription
            records[index] = record
            saveRecords()
        }
    }

    func deleteRecord(at index: Int) {
        guard records.indices.contains(index) else { return }
        records.remove(at: index)
        saveRecords()
    }

    //  Private Storage Methods

    private func loadRecords() {
        if let saved = loadRecordsFromDisk() {
            records = saved
        } else {
            records = loadSampleRecords()
        }
    }

    private func loadRecordsFromDisk() -> [SeizureRecord]? {
        print("📁 Archive URL:", archiveURL.path)
        print("📁 File exists?", FileManager.default.fileExists(atPath: archiveURL.path))

        guard let data = try? Data(contentsOf: archiveURL) else {
            print("⚠️ Could not read data from archive URL.")
            return nil
        }

        do {
            let decoded = try PropertyListDecoder().decode([SeizureRecord].self, from: data)
            print("📥 Loaded records count:", decoded.count)
            return decoded
        } catch {
            print("❌ Failed decoding records:", error)
            return nil
        }
    }


    private func saveRecords() {
        let encoder = PropertyListEncoder()
        let data = try? encoder.encode(records)
        try? data?.write(to: archiveURL, options: .noFileProtection)
    }

    //Sample Data
    private func loadSampleRecords() -> [SeizureRecord] {
        guard let sampleUserId = UserDataModel.shared.getCurrentUser()?.id else {
            return []
        }

        // Automatic Records
        let automatic1 = SeizureRecord(
            userId: sampleUserId,
            entryType: .automatic,
            dateTime: Date(),
            description: "Auto-detected seizure",
            type: .severe,
            duration: 120,
            spo2: 89,
            heartRate: 140,
            location: "Bedroom"
        )

        let automatic2 = SeizureRecord(
            userId: sampleUserId,
            entryType: .automatic,
            dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            description: "Detected during sleep",
            type: .moderate,
            duration: 75,
            spo2: 92,
            heartRate: 118,
            location: "Hostel Room"
        )

        let automatic3 = SeizureRecord(
            userId: sampleUserId,
            entryType: .automatic,
            dateTime: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            description: "Short seizure detected",
            type: .mild,
            duration: 40,
            spo2: 95,
            heartRate: 105,
            location: "Library"
        )

        //  Manual Records
        let manual1 = SeizureRecord(
            userId: sampleUserId,
            entryType: .manual,
            dateTime: Date(),
            description: "Felt dizzy, took meds",
            type: .mild,
            duration: 90, title: "Felt Aura",
            symptoms: ["Anxiety", "Dizziness"]
        )

        let manual2 = SeizureRecord(
            userId: sampleUserId,
            entryType: .manual,
            dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            description: "Visual distortion before sleeping",
            type: .moderate,
            duration: 60,
            title: "Visual Changes",
            symptoms: ["Visual Change", "Tired"]
        )

        let manual3 = SeizureRecord(
            userId: sampleUserId,
            entryType: .manual,
            dateTime: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            description: "Headache and nausea",
            type: .mild,
            duration: 120,
            title: "Headache Episode",
            symptoms: ["Headache", "Nausea", "Weakness"]
        )

        return [automatic1, automatic2, automatic3, manual1, manual2, manual3]
    }

}

// Helper function
extension SeizureRecordDataModel {
    func getLatestTwoRecordsForCurrentUser() -> [SeizureRecord] {
          guard let currentUser = UserDataModel.shared.getCurrentUser() else {
              print("⚠️ No user logged in.")
              return []
          }

          loadRecords()

          let userRecords = records
              .filter { $0.userId == currentUser.id }
              .sorted { $0.dateTime > $1.dateTime } 
          return Array(userRecords.prefix(2))
      }
}

