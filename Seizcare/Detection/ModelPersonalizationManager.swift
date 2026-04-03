// ModelPersonalizationManager.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Scaffolding for future on-device Core ML model personalization.
//
// IMPORTANT SAFETY RULES (strict):
//   ❌ Never update from unlabeled data
//   ❌ Never update from a single alert
//   ❌ Never auto-promote a new model without validation
//   ✅ Only batch-update from confirmed + labeled samples
//   ✅ Always keep original bundled model as fallback
//   ✅ Validate personalized model before promotion
//   ✅ Save personalized model snapshots separately from bundled model
//
// Current status: Stub/scaffold only.
// TODO: Implement MLUpdateTask workflow when SeizureDetector.mlmodel is trained
//       with Apple's updatable Core ML model format.
// Reference: https://developer.apple.com/documentation/coreml/personalizing_a_model_with_on-device_updates

import Foundation
import CoreML

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PersonalizationSample
// ─────────────────────────────────────────────────────────────────────────────

/// A labeled sample ready for on-device personalization.
/// Only created from confirmed + user-labeled detection sessions.
struct PersonalizationSample: Codable {
    let sessionID:      UUID
    let features:       [String: Double]  // WindowFeatures.asDict()
    let label:          FeedbackLabel
    let timestamp:      Date
    let sensitivityLevel: String
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ModelPersonalizationManager
// ─────────────────────────────────────────────────────────────────────────────

final class ModelPersonalizationManager {

    // MARK: Singleton

    static let shared = ModelPersonalizationManager()

    // MARK: Configuration

    /// Minimum confirmed labeled samples required before a batch update can run
    private let minSamplesForUpdate = 20

    // MARK: State

    private var pendingSamples: [PersonalizationSample] = []
    private let queue = DispatchQueue(label: "com.seizcare.personalization", qos: .background)

    private var samplesURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("personalization_samples.json")
    }
    private var personalizedModelURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("SeizureDetector_personalized.mlmodelc")
    }

    // MARK: Init

    private init() {
        queue.async { self.loadSamplesFromDisk() }
        print("🧬 [ModelPersonalization] Initialised — samples: \(pendingSamples.count)")
    }

    // MARK: - Collect Labeled Sample

    /// Call after user submits confirmed feedback for an alert session.
    /// Only collects samples with definitive labels (true seizure or false alarm).
    func collectSample(from session: DetectionSession, label: FeedbackLabel) {
        // Only high-confidence labels are useful for training
        guard label == .trueSeizure || label == .falseAlarm else {
            print("🧬 [ModelPersonalization] Skipping sample — label '\(label.rawValue)' not definitive enough")
            return
        }

        let sample = PersonalizationSample(
            sessionID:       session.id,
            features:        session.featureSnapshot,
            label:           label,
            timestamp:       session.timestamp,
            sensitivityLevel: session.sensitivityLevel
        )

        queue.async {
            // Deduplicate by session ID
            guard !self.pendingSamples.contains(where: { $0.sessionID == session.id }) else { return }
            self.pendingSamples.append(sample)
            self.saveSamplesToDisk()
            print("🧬 [ModelPersonalization] Collected sample — total: \(self.pendingSamples.count)/\(self.minSamplesForUpdate)")
        }
    }

    // MARK: - Batch Update (Future)

    /// Returns true if enough labeled samples exist to trigger a batch update.
    var isUpdateCandidateReady: Bool {
        queue.sync { pendingSamples.count >= minSamplesForUpdate }
    }

    /// Initiates on-device model personalization.
    /// MUST be called explicitly by a user/caregiver — never automatically.
    /// TODO: Implement using MLUpdateTask with an updatable SeizureDetector.mlmodel
    func triggerBatchUpdate(completion: @escaping (Result<URL, Error>) -> Void) {
        // TODO: Implement on-device personalization via MLUpdateTask.
        //
        // High-level flow:
        //   1. Load base model: SeizureDetector.mlmodel (updatable variant)
        //   2. Prepare MLBatchProvider from pendingSamples
        //   3. Create MLUpdateTask with progressHandlers
        //   4. On completion: validate model (see validatePersonalizedModel)
        //   5. If valid: save to personalizedModelURL, notify SeizureInferenceService
        //   6. Keep bundled model as fallback
        //
        // Example:
        // let updateTask = try MLUpdateTask(
        //     forModelAt: Bundle.main.url(forResource: "SeizureDetector", withExtension: "mlmodelc")!,
        //     trainingData: batchProvider,
        //     configuration: MLModelConfiguration(),
        //     progressHandlers: MLUpdateProgressHandlers(forEvents: [.trainingBegin, .epochEnd, .trainingEnd],
        //         progressHandler: { context in ... },
        //         completionHandler: { context in
        //             try context.model.write(to: personalizedModelURL)
        //             completion(.success(personalizedModelURL))
        //         }
        //     ))
        // updateTask.resume()

        print("🧬 [ModelPersonalization] triggerBatchUpdate called — TODO: implement MLUpdateTask")
        completion(.failure(ModelPersonalizationError.notImplemented))
    }

    /// Validates a candidate personalised model before promoting it.
    /// Runs a held-out test set through both old and new models; promotes only if improved.
    /// TODO: Implement validation logic
    private func validatePersonalizedModel(at url: URL) -> Bool {
        // TODO: Run held-out labeled samples through both bundled and personalised models.
        // Accept personalised model only if accuracy >= bundled model accuracy.
        print("🧬 [ModelPersonalization] validatePersonalizedModel — TODO: implement")
        return false
    }

    // MARK: - Disk

    private func loadSamplesFromDisk() {
        guard FileManager.default.fileExists(atPath: samplesURL.path),
              let data = try? Data(contentsOf: samplesURL),
              let samples = try? JSONDecoder().decode([PersonalizationSample].self, from: data) else { return }
        pendingSamples = samples
        print("🧬 [ModelPersonalization] Loaded \(samples.count) pending samples")
    }

    private func saveSamplesToDisk() {
        guard let data = try? JSONEncoder().encode(pendingSamples) else { return }
        try? data.write(to: samplesURL, options: .atomicWrite)
    }
}

// MARK: - Error

enum ModelPersonalizationError: Error {
    case notImplemented
    case insufficientSamples(have: Int, need: Int)
    case validationFailed
    case modelWriteFailed
}
