// DetectionCore.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Canonical shared types for the full detection pipeline.
// Every layer (buffer, features, inference, decision, storage) imports only this file
// for its domain types. Do NOT add business logic here.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SensorSample
// ─────────────────────────────────────────────────────────────────────────────

/// A single atomic sensor reading from the Apple Watch.
/// Includes accelerometer, device-motion (gyro/attitude), and heart rate.
/// Collected on the Watch, serialised over WatchConnectivity, reconstructed on iPhone.
struct SensorSample {
    /// Unix epoch seconds (from the Watch clock)
    let timestamp: Double

    // --- Accelerometer (units: g) ---
    let ax: Double
    let ay: Double
    let az: Double

    // --- Gyroscope / device-motion rotation rate (units: rad/s) ---
    let gx: Double
    let gy: Double
    let gz: Double

    /// Heart rate in BPM. May be nil if a fresh reading is unavailable.
    let hr: Double?

    /// Convenience: cached Euclidean acceleration magnitude
    var accelMagnitude: Double {
        sqrt(ax * ax + ay * ay + az * az)
    }

    /// Convenience: cached Euclidean gyro magnitude
    var gyroMagnitude: Double {
        sqrt(gx * gx + gy * gy + gz * gz)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WindowFeatures
// ─────────────────────────────────────────────────────────────────────────────

/// Rich ~30-feature vector extracted from a 4-second window of SensorSamples.
/// This struct is the contract between FeatureExtractor and both inference services.
struct WindowFeatures {

    // MARK: Motion Features
    var accelMagMean:        Double = 0
    var accelMagStd:         Double = 0
    var accelMagMin:         Double = 0
    var accelMagMax:         Double = 0
    var accelMagMedian:      Double = 0
    var accelMagP75:         Double = 0
    var accelMagP25:         Double = 0
    var accelEnergy:         Double = 0
    var fftEnergy:           Double = 0
    var accelPeakToPeak:     Double = 0
    var signalMagnitudeArea: Double = 0  // ΣΣ|axis| / n
    var jerkMean:            Double = 0  // mean of |Δmag/Δt|
    var jerkVariance:        Double = 0
    var dominantFrequency:   Double = 0  // Hz from FFT (vDSP)
    var spectralPowerLow:    Double = 0  // 0.5–3 Hz band
    var spectralPowerMid:    Double = 0  // 3–8 Hz band
    var spectralPowerHigh:   Double = 0  // 8–20 Hz band
    var periodicityScore:    Double = 0  // lag-1 normalised autocorrelation
    var gyroMagMean:         Double = 0
    var gyroMagStd:          Double = 0

    // ─── ArtifactFilter ML Model Scalar Features ───────────
    var accMeanX: Double = 0; var accMeanY: Double = 0; var accMeanZ: Double = 0
    var accStdX:  Double = 0; var accStdY:  Double = 0; var accStdZ:  Double = 0
    var accMinX:  Double = 0; var accMinY:  Double = 0; var accMinZ:  Double = 0
    var accMaxX:  Double = 0; var accMaxY:  Double = 0; var accMaxZ:  Double = 0
    var accZcX:   Double = 0; var accZcY:   Double = 0; var accZcZ:   Double = 0
    var jerkRms:  Double = 0
    var samplesInWindow: Double = 0
    // ───────────────────────────────────────────────────────

    // MARK: Heart Rate Features
    var hrMean:              Double = 0
    var hrMax:               Double = 0
    var hrSlope:             Double = 0  // BPM/second linear regression
    var hrDeltaFromBaseline: Double = 0  // hrMean − userBaselineHR

    // MARK: Context Features
    var sleepHoursLastNight: Double = 0
    var sevenDaySleepAvg:    Double = 0
    var isAsleepFlag:        Double = 0  // 1.0 = currently asleep, 0.0 = awake
    var isWorkoutFlag:       Double = 0  // 1.0 = workout/workout HK session active
    var timeOfDayNorm:       Double = 0  // 0.0–1.0 (midnight = 0, noon = 0.5)
    var userBaselineHR:      Double = 0
    var userBaselineMotion:  Double = 0  // rolling normal-SMA

    // MARK: Personalization Features
    var sensitivityEncoded:  Double = 0  // 0=low, 0.5=medium, 1.0=high
    var seizureFreqProfile:  Double = 0  // 0=unknown, 0..1 normalised

    // MARK: Temporal Features
    var prevWindowRiskScore: Double = 0  // smoothed score from n-1 window
    var positiveWindowCount: Double = 0  // # suspicious windows in last 10
    var rhythmicDuration:    Double = 0  // seconds of continuous rhythmic motion
    var postEventStillness:  Double = 0  // accel variance after prior spike
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ActivityClass
// ─────────────────────────────────────────────────────────────────────────────

/// Artifact filter output — classification of the current window's motion.
enum ActivityClass: String, Codable {
    case running        = "running"
    case walking        = "walking"
    case workout        = "workout"
    case stairsMotion   = "stairs_motion"
    case sit            = "sit"
    case sleepMovement  = "sleep_movement"
    case brushingTeeth  = "brushing_teeth"
    case vehicle        = "vehicle"
    case normalActivity = "normal_activity"
    case suspicious     = "suspicious"
    case unknown        = "unknown"

    /// True for any label that strongly suggests the window is NOT a seizure.
    var isDefinitelyNormal: Bool {
        switch self {
        case .running, .walking, .workout, .stairsMotion, .sit, .brushingTeeth, .vehicle:
            return true
        case .sleepMovement, .normalActivity, .suspicious, .unknown:
            return false
        }
    }
    
    /// Human-readable UI string (e.g. "Walking", "Still / Rest")
    var displayName: String {
        switch self {
        case .running:        return "Running"
        case .walking:        return "Walking"
        case .workout:        return "Workout"
        case .stairsMotion:   return "Stairs Motion"
        case .sit:            return "Sitting"
        case .sleepMovement:  return "Sleep Movement"
        case .brushingTeeth:  return "Brushing Teeth"
        case .vehicle:        return "Vehicle / Transit"
        case .normalActivity: return "Normal Activity"
        case .suspicious:     return "Suspicious / Potential Event"
        case .unknown:        return "Still / Rest"
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ArtifactFilterResult
// ─────────────────────────────────────────────────────────────────────────────

struct ArtifactFilterResult {
    let activityClass:           ActivityClass
    /// Probability [0,1] that this window is explained by normal activity.
    let normalActivityProbability: Double
    /// Short human-readable reason (for debug logging)
    let reason:                  String
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DetectionContext
// ─────────────────────────────────────────────────────────────────────────────

/// Snapshot of contextual state injected into every decision cycle.
/// Sources: HealthKitManager, WorkoutSession, SensitivityDataModel, BaselineAdaptation.
struct DetectionContext {
    /// Hours of sleep last night (from HealthKit sleep analysis)
    var sleepHoursLastNight:  Double = 0
    /// Rolling 7-day average sleep
    var sevenDaySleepAvg:    Double = 0
    /// Whether the user is currently in an active sleep window
    var isCurrentlyAsleep:   Bool   = false
    /// Whether an HK workout session is explicitly active (user-initiated workout)
    var isWorkoutActive:     Bool   = false
    /// Current sensitivity level (from SensitivityDataModel / user setting)
    var sensitivityLevel:    SensitivityLevel = .medium
    /// User's resting heart rate baseline (EWMA-updated)
    var baselineHR:          Double = 65
    /// User's resting motion baseline (SMA percentile, updated daily)
    var baselineMotion:      Double = 1.0
    /// Seizure frequency profile (0 = unknown, up to 1 = daily)
    var seizureFreqProfile:  Double = 0
    /// Time of day as fraction [0,1]
    var timeOfDayNorm:       Double = 0

    static func current(sensitivity: SensitivityLevel,
                        baselines: BaselineStats,
                        sleepHours: Double,
                        sevenDayAvg: Double,
                        isAsleep: Bool,
                        isWorkout: Bool) -> DetectionContext {
        let now = Date()
        let seconds = now.timeIntervalSince(Calendar.current.startOfDay(for: now))
        let norm = seconds / 86400.0

        return DetectionContext(
            sleepHoursLastNight:  sleepHours,
            sevenDaySleepAvg:     sevenDayAvg,
            isCurrentlyAsleep:    isAsleep,
            isWorkoutActive:      isWorkout,
            sensitivityLevel:     sensitivity,
            baselineHR:           baselines.restingHR,
            baselineMotion:       baselines.normalMotionSMA,
            seizureFreqProfile:   baselines.seizureFreqProfile,
            timeOfDayNorm:        norm
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - BaselineStats
// ─────────────────────────────────────────────────────────────────────────────

/// Per-user rolling baselines maintained by BaselineAdaptationManager.
struct BaselineStats: Codable {
    /// Exponential-weighted moving average resting heart rate
    var restingHR:         Double = 65.0
    /// 90th-percentile SMA during calm periods
    var normalMotionSMA:   Double = 1.0
    /// Average sleep hours (7-day rolling)
    var avgSleepHours:     Double = 7.0
    /// Nighttime motion signature (average accel magnitude midnight–6am)
    var nighttimeMotion:   Double = 0.2
    /// Seizure frequency normalised [0,1] — updated by confirmed events
    var seizureFreqProfile: Double = 0.0
    /// When baselines were last updated
    var lastUpdated:       Date    = .distantPast
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SensitivityPolicy
// ─────────────────────────────────────────────────────────────────────────────

/// DECISION-POLICY layer for sensitivity.
/// Sensitivity does NOT label seizure classes — it adjusts alert thresholds.
struct SensitivityPolicy {
    /// Minimum smoothed seizure probability to consider alerting
    let seizureThreshold:      Double
    /// Number of windows out of `windowPoolSize` that must exceed threshold
    let requiredPositiveCount: Int
    /// Total windows in the confirmation vote pool
    let windowPoolSize:        Int
    /// Whether heart-rate confirmation is required (low sensitivity)
    let requireHRConfirmation: Bool
    /// Heart-rate change from baseline needed when requireHRConfirmation = true
    let hrConfirmationDelta:   Double

    static func policy(for level: SensitivityLevel) -> SensitivityPolicy {
        switch level {
        case .high:
            // Lower bar — catch more, accept more false alarms
            return SensitivityPolicy(
                seizureThreshold:      0.60,
                requiredPositiveCount: 2,
                windowPoolSize:        3,
                requireHRConfirmation: false,
                hrConfirmationDelta:   15
            )
        case .medium:
            return SensitivityPolicy(
                seizureThreshold:      0.75,
                requiredPositiveCount: 3,
                windowPoolSize:        5,
                requireHRConfirmation: false,
                hrConfirmationDelta:   20
            )
        case .low:
            // Higher bar — reduce false alarms, may miss mild events
            return SensitivityPolicy(
                seizureThreshold:      0.85,
                requiredPositiveCount: 4,
                windowPoolSize:        5,
                requireHRConfirmation: true,
                hrConfirmationDelta:   25
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DetectionDecision
// ─────────────────────────────────────────────────────────────────────────────

/// Final output of DecisionEngine for every processed window.
/// Contains everything needed for alert triggering AND full explainability logging.
struct DetectionDecision {
    // MARK: Scores
    let artifactProbability: Double
    let seizureProbability:  Double
    let smoothedProbability: Double

    // MARK: Classification
    let activityClass:       ActivityClass
    let outcome:             DetectionOutcome

    // MARK: Policy Snapshot
    let sensitivityLevel:    SensitivityLevel
    let thresholdUsed:       Double
    let requiredPositive:    Int
    let windowPoolSize:      Int

    // MARK: Context Flags
    let isAsleep:            Bool
    let isWorkoutActive:     Bool
    let hrConfirmed:         Bool

    // MARK: Explainability
    /// Human-readable reason string for every decision. Always populated.
    let reason:              String

    // MARK: Timestamp
    let timestamp:           Date

    var isSeizureSuspected: Bool { outcome == .seizureSuspected }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DetectionOutcome
// ─────────────────────────────────────────────────────────────────────────────

enum DetectionOutcome: String, Codable {
    case seizureSuspected    = "seizure_suspected"
    case suppressedByArtifact = "suppressed_by_artifact"
    case suppressedBySmoothing = "suppressed_by_smoothing"
    case suppressedByContext = "suppressed_by_context"
    case belowThreshold      = "below_threshold"
    case insufficientData    = "insufficient_data"
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FeedbackLabel
// ─────────────────────────────────────────────────────────────────────────────

/// Labels provided by the user after an alert resolves.
enum FeedbackLabel: String, Codable, CaseIterable {
    case trueSeizure    = "true_seizure"
    case falseAlarm     = "false_alarm"
    case runningWorkout = "running_workout"
    case sleepJerk      = "sleep_jerk"
    case unknown        = "unknown"

    var displayTitle: String {
        switch self {
        case .trueSeizure:    return "True Seizure"
        case .falseAlarm:     return "False Alarm"
        case .runningWorkout: return "Running / Workout"
        case .sleepJerk:      return "Sleep Jerk"
        case .unknown:        return "Not Sure"
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FeedbackConfidence & Provenance
// ─────────────────────────────────────────────────────────────────────────────

enum FeedbackConfidence: String, Codable {
    case notSure      = "not_sure"
    case somewhatSure = "somewhat_sure"
    case verySure     = "very_sure"
}

struct FeedbackProvenance: Codable {
    let label: FeedbackLabel
    let confidence: FeedbackConfidence?
    let timestamp: Date
    /// Distinguishes where this piece of feedback came from (e.g. "immediate", "history")
    let source: String
}

enum SyncStatus: String, Codable {
    case pending
    case synced
    case failed
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DetectionSession
// ─────────────────────────────────────────────────────────────────────────────

/// Persisted record for every alert that was considered (or fired).
struct DetectionSession: Codable, Identifiable {
    let id:                UUID
    let timestamp:         Date
    let decision:          DetectionOutcome
    let artifactProb:      Double
    let seizureProb:       Double
    let smoothedProb:      Double
    let activityClass:     String
    let sensitivityLevel:  String
    let thresholdUsed:     Double
    let isAsleep:          Bool
    let isWorkoutActive:   Bool
    let hrConfirmed:       Bool
    let reason:            String
    /// Feature snapshot JSON — compact dump for future model training use
    let featureSnapshot:   [String: Double]
    
    /// Historical record of labels applied to this session by the user
    var labelHistory:      [FeedbackProvenance]
    
    /// Computed current label (the most recently applied one)
    var feedbackLabel: FeedbackLabel? {
        return labelHistory.last?.label
    }
    
    var syncStatus:        SyncStatus
    var lastSyncAttempt:   Date?

    init(decision: DetectionDecision, features: WindowFeatures) {
        self.id               = UUID()
        self.timestamp        = decision.timestamp
        self.decision         = decision.outcome
        self.artifactProb     = decision.artifactProbability
        self.seizureProb      = decision.seizureProbability
        self.smoothedProb     = decision.smoothedProbability
        self.activityClass    = decision.activityClass.rawValue
        self.sensitivityLevel = decision.sensitivityLevel.rawValue
        self.thresholdUsed    = decision.thresholdUsed
        self.isAsleep         = decision.isAsleep
        self.isWorkoutActive  = decision.isWorkoutActive
        self.hrConfirmed      = decision.hrConfirmed
        self.reason           = decision.reason
        self.featureSnapshot  = features.asDict()
        self.labelHistory     = []
        self.syncStatus       = .pending
        self.lastSyncAttempt  = nil
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WindowFeatures serialisation helper
// ─────────────────────────────────────────────────────────────────────────────

extension WindowFeatures {
    /// Compact dictionary for JSON snapshot storage.
    func asDict() -> [String: Double] {
        return [
            "accel_mag_mean":         accelMagMean,
            "accel_mag_std":          accelMagStd,
            "accel_mag_min":          accelMagMin,
            "accel_mag_max":          accelMagMax,
            "accel_mag_median":       accelMagMedian,
            "accel_mag_p75":          accelMagP75,
            "accel_mag_p25":          accelMagP25,
            "accel_energy":           accelEnergy,
            "fft_energy":             fftEnergy,
            "accel_peak_to_peak":     accelPeakToPeak,
            "sma":                    signalMagnitudeArea,
            "jerk_mean":              jerkMean,
            "jerk_variance":          jerkVariance,
            "dominant_freq":          dominantFrequency,
            "spectral_power_low":     spectralPowerLow,
            "spectral_power_mid":     spectralPowerMid,
            "spectral_power_high":    spectralPowerHigh,
            "periodicity_score":      periodicityScore,
            "gyro_mag_mean":          gyroMagMean,
            "gyro_mag_std":           gyroMagStd,
            "hr_mean":                hrMean,
            "hr_max":                 hrMax,
            "hr_slope":               hrSlope,
            "hr_delta_baseline":      hrDeltaFromBaseline,
            "sleep_hours":            sleepHoursLastNight,
            "seven_day_sleep_avg":    sevenDaySleepAvg,
            "is_asleep":              isAsleepFlag,
            "is_workout":             isWorkoutFlag,
            "time_of_day":            timeOfDayNorm,
            "baseline_hr":            userBaselineHR,
            "baseline_motion":        userBaselineMotion,
            "sensitivity_encoded":    sensitivityEncoded,
            "seizure_freq":           seizureFreqProfile,
            "prev_risk":              prevWindowRiskScore,
            "positive_window_count":  positiveWindowCount,
            "rhythmic_duration":      rhythmicDuration,
            "post_event_stillness":   postEventStillness
        ]
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SensitivityLevel (canonical source — mirrors SensitivityDataModel)
// ─────────────────────────────────────────────────────────────────────────────
// NOTE: SensitivityLevel is already declared in SensitivityDataModel.swift.
// We reference it there. Do not re-declare here — keep SensitivityDataModel.swift
// as the canonical source for this enum.
