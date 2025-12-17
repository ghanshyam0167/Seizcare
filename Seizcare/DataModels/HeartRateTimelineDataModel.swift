//
//  HeartRateTimelineDataModel.swift
//  Seizcare
//
//  Created by GS Agrawal on 16/12/25.
//

import Foundation

// MARK: - Heart Rate Phase
enum HeartRatePhase: String, Codable {
    case before
    case during
    case after
}

// MARK: - Timeline Point
struct HeartRateTimelinePoint: Identifiable {
    let id = UUID()

    let timestamp: Date
    let bpm: Int
    let phase: HeartRatePhase
}

// MARK: - Builder (Mock / Server-ready)
struct HeartRateTimelineBuilder {

    /// Generates HR timeline: 2h before → during → 2h after
    static func generateTimeline(
        seizureTime: Date,
        seizureDuration: TimeInterval,
        intervalMinutes: Int = 5
    ) -> [HeartRateTimelinePoint] {

        var points: [HeartRateTimelinePoint] = []

        for minuteOffset in stride(from: -120, through: 120, by: intervalMinutes) {

            let time = Calendar.current.date(
                byAdding: .minute,
                value: minuteOffset,
                to: seizureTime
            )!

            let phase: HeartRatePhase =
                minuteOffset < 0 ? .before :
                minuteOffset <= Int(seizureDuration / 60) ? .during :
                .after

            let bpm: Int = {
                switch phase {
                case .before:
                    return Int.random(in: 65...90)
                case .during:
                    return Int.random(in: 110...160)
                case .after:
                    return Int.random(in: 75...100)
                }
            }()

            points.append(
                HeartRateTimelinePoint(
                    timestamp: time,
                    bpm: bpm,
                    phase: phase
                )
            )
        }

        return points
    }
}
