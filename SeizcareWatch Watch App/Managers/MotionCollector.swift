// MotionCollector.swift
// SeizcareWatch Watch App — Managers
//
// PURPOSE: Collect device motion at ~50 Hz from CMMotionManager.
// Batches samples into arrays and sends them via WatchConnectivityManager
// every 2 seconds (MotionCollector.batchIntervalSeconds).
//
// WHY BATCH: Sending 50 individual WCSession messages/second would overwhelm
// WatchConnectivity and drain the battery. Instead we batch into one message.
// The iPhone receives [[ax,ay,az,gx,gy,gz,timestamp], ...] and processes it.
//
// NOTE: CoreMotion on watchOS requires the Watch to have an active workout
// session (or be the foreground app) for sustained high-frequency access.
// MonitoringSession.shared keeps the session alive.

import Foundation
import CoreMotion

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - MotionCollector
// ─────────────────────────────────────────────────────────────────────────────

final class MotionCollector {

    // MARK: Singleton

    static let shared = MotionCollector()

    // MARK: Configuration

    /// Target device motion update interval — 50 Hz = 0.02 seconds/sample
    private let motionUpdateInterval: TimeInterval = 1.0 / 50.0

    /// How often to flush the batch to WatchConnectivity (seconds)
    let batchIntervalSeconds: TimeInterval = 2.0

    // MARK: State

    private let motionManager  = CMMotionManager()
    private var batchBuffer:   [[Double]] = []
    private var batchTimer:    Timer?
    private var isCollecting   = false
    private let queue          = DispatchQueue(label: "com.seizcare.motionCollector", qos: .userInteractive)

    // MARK: Init

    private init() {
        print("🏃 [MotionCollector] Initialised — rate: \(Int(1/motionUpdateInterval)) Hz, batch: \(batchIntervalSeconds)s")
    }

    // MARK: - Start / Stop

    func startCollecting() {
        guard !isCollecting else { return }
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ [MotionCollector] Device motion not available on this device")
            return
        }

        motionManager.deviceMotionUpdateInterval = motionUpdateInterval

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            self.queue.async { self.handleMotion(motion) }
        }

        // Flush timer — fires every batchIntervalSeconds
        batchTimer = Timer.scheduledTimer(
            withTimeInterval: batchIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            self?.flushBatch()
        }

        isCollecting = true
        print("✅ [MotionCollector] Started collecting device motion")
    }

    func stopCollecting() {
        guard isCollecting else { return }
        motionManager.stopDeviceMotionUpdates()
        batchTimer?.invalidate()
        batchTimer = nil
        queue.async { self.batchBuffer.removeAll() }
        isCollecting = false
        print("🛑 [MotionCollector] Stopped")
    }

    // MARK: - Motion Handling

    private func handleMotion(_ motion: CMDeviceMotion) {
        // Row format: [ax, ay, az, gx, gy, gz, timestamp]
        let row: [Double] = [
            motion.userAcceleration.x,  // ax (fractional g)
            motion.userAcceleration.y,  // ay
            motion.userAcceleration.z,  // az
            motion.rotationRate.x,       // gx (rad/s)
            motion.rotationRate.y,       // gy
            motion.rotationRate.z,       // gz
            Date().timeIntervalSince1970 // timestamp
        ]
        batchBuffer.append(row)
    }

    // MARK: - Batch Flush

    private func flushBatch() {
        queue.async { [weak self] in
            guard let self, !self.batchBuffer.isEmpty else { return }

            let batch = self.batchBuffer
            self.batchBuffer.removeAll()
            self.batchBuffer.reserveCapacity(100)

            print("📦 [MotionCollector] Flushing batch of \(batch.count) samples to iPhone")

            DispatchQueue.main.async {
                WatchConnectivityManager.shared.sendMotionBatch(batch)
            }
        }
    }
}
