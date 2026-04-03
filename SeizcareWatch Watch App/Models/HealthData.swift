// HealthData.swift
// SeizcareWatch Watch App — Models
//
// Extended to include motion fields for the detection pipeline.

import Foundation

struct HealthData {
    // HealthKit readings
    var heartRate:          Double?
    var spo2:               Double?
    var sleepDurationHours: Double?

    // Latest motion snapshot (from CMMotionManager via MotionCollector)
    // These are stored for UI display only; the detection pipeline receives
    // motion data via WatchConnectivity sensorBatch payloads.
    var latestAccelMag:     Double?   // acceleration magnitude (g)
    var latestGyroMag:      Double?   // gyroscope magnitude (rad/s)
}
