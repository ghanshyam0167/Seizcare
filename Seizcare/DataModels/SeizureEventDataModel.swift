//
//  SeizureEventDataModel.swift
//  Seizcare
//

import Foundation

//====================================================
// MARK: - Seizure Event Model
//====================================================
struct SeizureEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let latitude: Double
    let longitude: Double
    
    // Optional metadata for future extensibility
    var description: String?
    
    static func == (lhs: SeizureEvent, rhs: SeizureEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

//====================================================
// MARK: - Seizure Event Data Model
//====================================================
final class SeizureEventDataModel {
    static let shared = SeizureEventDataModel()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    private var events: [SeizureEvent] = []
    
    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("seizureEvents").appendingPathExtension("plist")
        loadEvents()
    }
    
    //====================================================
    // MARK: - Public Access
    //====================================================
    func getAllEvents() -> [SeizureEvent] {
        return events.sorted { $0.date > $1.date }
    }
    
    //====================================================
    // MARK: - Add / Update / Delete
    //====================================================
    func addEvent(_ event: SeizureEvent) {
        events.append(event)
        saveEvents()
    }
    
    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        saveEvents()
    }
    
    //====================================================
    // MARK: - Persistence
    //====================================================
    private func loadEvents() {
        if let data = try? Data(contentsOf: archiveURL),
           let savedEvents = try? PropertyListDecoder().decode([SeizureEvent].self, from: data) {
            events = savedEvents
        } else {
            events = []
            saveEvents()
        }
    }
    
    private func saveEvents() {
        if let data = try? PropertyListEncoder().encode(events) {
            try? data.write(to: archiveURL, options: .noFileProtection)
        }
    }
}
