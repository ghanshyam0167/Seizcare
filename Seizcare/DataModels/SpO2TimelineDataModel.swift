//
//  SpO2TimelineDataModel.swift
//  Seizcare
//
//  Created by GS Agrawal on 16/12/25.
//
//


import Foundation

//  SpO2 Phase
enum SpO2Phase: String, Codable {
    case before
    case during
    case after
}

// SpO2 Timeline Point
struct SpO2TimelinePoint: Identifiable {
    let id = UUID()

    let timestamp: Date
    let spo2: Int
    let phase: SpO2Phase
}

// Timeline Generator (Temporary / Server-ready)
struct SpO2TimelineBuilder {

    static func generateTimeline(for record: SeizureRecord) -> [SpO2TimelinePoint] {
        guard let spo2 = record.spo2 else { return [] }
        return [SpO2TimelinePoint(timestamp: record.dateTime, spo2: spo2, phase: .during)]
    }
}
