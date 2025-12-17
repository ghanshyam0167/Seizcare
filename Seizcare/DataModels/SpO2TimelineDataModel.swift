//
//  SpO2TimelineDataModel.swift
//  Seizcare
//
//  Created by GS Agrawal on 16/12/25.
//
//


import Foundation

// MARK: - SpO2 Phase
enum SpO2Phase: String, Codable {
    case before
    case during
    case after
}

// MARK: - SpO2 Timeline Point
struct SpO2TimelinePoint: Identifiable {
    let id = UUID()

    let timestamp: Date
    let spo2: Int
    let phase: SpO2Phase
}

// MARK: - Timeline Generator (Temporary / Server-ready)
struct SpO2TimelineBuilder {

    /// Generates 2h before → during → 2h after SpO₂ data
    static func generateTimeline(
        seizureTime: Date,
        intervalMinutes: Int = 10
    ) -> [SpO2TimelinePoint] {

        var points: [SpO2TimelinePoint] = []

        for minuteOffset in stride(
            from: -120,
            through: 120,
            by: intervalMinutes
        ) {

            let time = Calendar.current.date(
                byAdding: .minute,
                value: minuteOffset,
                to: seizureTime
            )!

            let phase: SpO2Phase =
                minuteOffset < 0 ? .before :
                minuteOffset == 0 ? .during :
                .after

            let spo2: Int = {
                switch phase {
                case .before:
                    return Int.random(in: 92...97)
                case .during:
                    return Int.random(in: 84...88)
                case .after:
                    return Int.random(in: 90...96)
                }
            }()

            points.append(
                SpO2TimelinePoint(
                    timestamp: time,
                    spo2: spo2,
                    phase: phase
                )
            )
        }

        return points
    }
}
