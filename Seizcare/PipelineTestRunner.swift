// PipelineTestRunner.swift
import Foundation

final class PipelineTestRunner {
    static let shared = PipelineTestRunner()
    private init() {}

    /// Call at app launch in DEBUG builds only.
    /// Routes to each sub-tester so the full pipeline can be validated in the console.
    func runAllTests() {
        #if DEBUG
        // print("\n🧪 ========== PIPELINE TEST RUNNER ==========")
        // print("   Running all DEBUG simulation suites...\n")

        // ── Model 1: Artifact Filter ──────────────────
        // ArtifactModelTester.runArtifactSimulation()

        // print("🧪 ========================================\n")
        #else
        // print("🧪 [PipelineTest] Tests disabled in production builds.")
        #endif
    }
}
