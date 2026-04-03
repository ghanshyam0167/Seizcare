// SensorBufferManager.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Rolling ring buffer for SensorSamples from the Apple Watch.
// Design:
//   • Configured for a 4-second window at ~50 Hz = 200 samples.
//   • 50% overlap means we trigger feature extraction every 100 samples (2 seconds).
//   • Thread-safe via a serial dispatch queue.
//   • Calls `onWindowReady` with a snapshot copy — never the raw buffer.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SensorBufferManager
// ─────────────────────────────────────────────────────────────────────────────

final class SensorBufferManager {

    // MARK: - Configuration

    struct Config {
        /// Nominal sample rate from the Watch (Hz)
        let sampleRate:    Int    = 50
        /// Window duration in seconds
        let windowSeconds: Double = 4.0
        /// Stride between evaluations (seconds) — 50% overlap
        let strideSeconds: Double = 2.0

        var windowSize: Int  { Int(Double(sampleRate) * windowSeconds) }  // 200
        var strideCount: Int { Int(Double(sampleRate) * strideSeconds)  }  // 100
    }

    let config = Config()

    // MARK: - State

    private var buffer: [SensorSample] = []
    private var samplesSinceLastEval: Int = 0
    private let queue = DispatchQueue(label: "com.seizcare.sensorBuffer", qos: .userInitiated)

    // MARK: - Callback

    /// Called on the internal queue when a full window is ready.
    /// Receives a snapshot copy of the current 200-sample window.
    var onWindowReady: (([SensorSample]) -> Void)?

    // MARK: - Init

    init() {
        buffer.reserveCapacity(config.windowSize + config.strideCount)
        print("📦 [SensorBuffer] Initialised — window: \(config.windowSize) samples (\(config.windowSeconds)s), stride: \(config.strideCount) samples (\(config.strideSeconds)s)")
    }

    // MARK: - Public API

    /// Append a single sensor sample. Thread-safe.
    func add(sample: SensorSample) {
        queue.async { [weak self] in
            self?.internalAdd(sample: sample)
        }
    }

    /// Append a batch of sensor samples received from Watch in one message.
    func addBatch(_ samples: [SensorSample]) {
        queue.async { [weak self] in
            guard let self else { return }
            for s in samples { self.internalAdd(sample: s) }
        }
    }

    /// Drain the buffer. Call when monitoring stops.
    func reset() {
        queue.async { [weak self] in
            self?.buffer.removeAll()
            self?.samplesSinceLastEval = 0
            print("🔄 [SensorBuffer] Buffer reset")
        }
    }

    /// Current buffer fill level (0.0 – 1.0)
    var fillLevel: Double {
        queue.sync { Double(buffer.count) / Double(config.windowSize) }
    }

    // MARK: - Private

    private func internalAdd(sample: SensorSample) {
        // Ring buffer: drop oldest sample when full
        if buffer.count >= config.windowSize {
            buffer.removeFirst()
        }
        buffer.append(sample)
        samplesSinceLastEval += 1

        // Fire window when:
        //   (a) we now have a full window AND
        //   (b) enough new samples have arrived since last eval (stride)
        if buffer.count >= config.windowSize && samplesSinceLastEval >= config.strideCount {
            samplesSinceLastEval = 0
            let snapshot = Array(buffer)  // copy — we must not leak the reference
            onWindowReady?(snapshot)
        }
    }
}
