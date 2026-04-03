//
//  HeartRateTimelineDataModel.swift
//  Seizcare
//
//  Created by GS Agrawal on 16/12/25.
//

import Foundation

//  Heart Rate Phase
enum HeartRatePhase: String, Codable {
    case before
    case during
    case after
}

//  Timeline Point
struct HeartRateTimelinePoint: Identifiable {
    let id = UUID()

    let timestamp: Date
    let bpm: Int
    let phase: HeartRatePhase
}

//  Builder (Mock / Server-ready)
struct HeartRateTimelineBuilder {

    static func generateTimeline(for record: SeizureRecord) -> [HeartRateTimelinePoint] {
        guard let hr = record.heartRate else { return [] }
        return [HeartRateTimelinePoint(timestamp: record.dateTime, bpm: hr, phase: .during)]
    }
}
