// FeedbackViewController.swift
// Seizcare — Detection Pipeline
//
// PURPOSE: Lightweight post-alert feedback UI.
// Presented as a bottom sheet immediately after an alert resolves.
// Richer correction/editing is also available in the alert history view.
//
// Options: True Seizure | False Alarm | Running/Workout | Sleep Jerk | Unknown

import UIKit

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FeedbackViewController
// ─────────────────────────────────────────────────────────────────────────────

final class FeedbackViewController: UIViewController {

    // MARK: - Properties

    private let sessionID: UUID
    private let source: String
    private let initialLabel: FeedbackLabel?
    
    private var stackView: UIStackView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var buttonStack: UIStackView!
    private var confidenceSegment: UISegmentedControl!

    // MARK: - Init

    init(sessionID: UUID, source: String = "immediate", initialLabel: FeedbackLabel? = nil) {
        self.sessionID = sessionID
        self.source = source
        self.initialLabel = initialLabel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        // Grabber view
        let grabber = UIView()
        grabber.backgroundColor = UIColor.separator
        grabber.layer.cornerRadius = 2
        grabber.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grabber)

        // Title
        titleLabel = UILabel()
        titleLabel.text = source == "history" ? "Edit Event Label" : "What happened?"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        subtitleLabel = UILabel()
        if let initial = initialLabel {
            subtitleLabel.text = "Current ML label: \(initial.displayTitle)"
        } else {
            subtitleLabel.text = "This helps the app learn your patterns over time."
        }
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Confidence
        confidenceSegment = UISegmentedControl(items: ["Not Sure", "Somewhat Sure", "Very Sure"])
        confidenceSegment.selectedSegmentIndex = 2 // Default Very Sure
        confidenceSegment.translatesAutoresizingMaskIntoConstraints = false

        // Feedback buttons
        let buttons = FeedbackLabel.allCases.map { label -> UIButton in
            let btn = makeFeedbackButton(label: label)
            return btn
        }

        buttonStack = UIStackView(arrangedSubviews: buttons)
        buttonStack.axis = .vertical
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        // Skip button
        let skipButton = UIButton(type: .system)
        skipButton.setTitle("Skip for now", for: .normal)
        skipButton.setTitleColor(.secondaryLabel, for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 14)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(grabber)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(confidenceSegment)
        view.addSubview(buttonStack)
        view.addSubview(skipButton)

        NSLayoutConstraint.activate([
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 4),

            titleLabel.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            confidenceSegment.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            confidenceSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confidenceSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: confidenceSegment.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            skipButton.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 14),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func makeFeedbackButton(label: FeedbackLabel) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = label.displayTitle
        config.baseForegroundColor = .white
        config.baseBackgroundColor = colorFor(label: label)
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var attrs = attrs
            attrs.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return attrs
        }

        let btn = UIButton(configuration: config)
        btn.accessibilityIdentifier = "feedback_\(label.rawValue)"
        btn.addAction(UIAction { [weak self] _ in
            self?.feedbackSelected(label)
        }, for: .touchUpInside)
        return btn
    }

    private func colorFor(label: FeedbackLabel) -> UIColor {
        switch label {
        case .trueSeizure:    return .systemRed
        case .falseAlarm:     return .systemBlue
        case .runningWorkout: return .systemOrange
        case .sleepJerk:      return .systemPurple
        case .unknown:        return .systemGray
        }
    }

    // MARK: - Actions
    
    private var currentConfidence: FeedbackConfidence {
        switch confidenceSegment.selectedSegmentIndex {
        case 0: return .notSure
        case 1: return .somewhatSure
        default: return .verySure
        }
    }

    private func feedbackSelected(_ label: FeedbackLabel) {
        let confidence = currentConfidence
        print("📝 [FeedbackVC] User selected: \(label.displayTitle) with confidence \(confidence.rawValue) for session \(sessionID)")
        FeedbackLogger.shared.submitFeedback(sessionID: sessionID, label: label, confidence: confidence, source: source)

        // If true seizure — also update baseline and personalization
        if label == .trueSeizure {
            BaselineAdaptationManager.shared.recordConfirmedSeizureEvent()
            if let session = DetectionSessionStore.shared.session(for: sessionID) {
                ModelPersonalizationManager.shared.collectSample(from: session, label: label)
            }
        } else if label == .falseAlarm {
            if let session = DetectionSessionStore.shared.session(for: sessionID) {
                ModelPersonalizationManager.shared.collectSample(from: session, label: label)
            }
        }

        dismiss(animated: true)
    }

    @objc private func skipTapped() {
        if source == "immediate" {
            FeedbackLogger.shared.clearPendingFeedback()
        }
        dismiss(animated: true)
    }
}
