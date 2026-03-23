//
//  AddRecordTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

// MARK: - AddRecordTableViewController

class AddRecordTableViewController: UITableViewController {

    // MARK: - IBOutlets (Storyboard-connected)
    @IBOutlet weak var seizureLevelSegment: UISegmentedControl!
    @IBOutlet weak var timeOfDaySegment: UISegmentedControl!
    @IBOutlet weak var topInputsCardView: UIView!
    @IBOutlet weak var notesCardView: UIView!
    @IBOutlet weak var symptompsCardView: UIView!   // Reused as Triggers container
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var severitySegment: UISegmentedControl!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!

    // MARK: - State
    /// Tracks which triggers the user has selected
    var selectedTriggers: Set<SeizureTrigger> = []

    /// Chip button map: trigger → its UIButton
    private var chipButtons: [SeizureTrigger: UIButton] = [:]

    var onDismiss: (() -> Void)?
    var recordToEdit: SeizureRecord?
    var isEditMode: Bool { recordToEdit != nil }

    // Duration in seconds
    var duration: TimeInterval = 0 {
        didSet { updateDurationLabel(); validateForm() }
    }

    private let placeholderText = "Add your notes here..."

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()

        [topInputsCardView, symptompsCardView, notesCardView].forEach {
            $0?.applyRecordCard()
        }

        // Date picker
        dateTextField.isUserInteractionEnabled = true
        dateTextField.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openDatePicker))
        )

        // Duration picker
        durationLabel.isUserInteractionEnabled = true
        durationLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openDurationPicker))
        )

        notesTextView.delegate = self
        seizureLevelSegment.applyPrimaryStyle()
        setupTimeOfDaySegment()

        saveButton.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .disabled)

        // Build the trigger chip grid programmatically
        setupTriggerChips()

        titleTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        dateTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

        if isEditMode {
            configureForEdit()
        } else {
            configureForAdd()
        }
    }

    // MARK: - Trigger Chip Setup

    /// Clears the card view and injects a dynamic chip grid for all SeizureTrigger cases.
    private func setupTriggerChips() {
        guard let container = symptompsCardView else { return }
        container.subviews.forEach { $0.removeFromSuperview() }


        // Wrapping chip layout using nested UIStackViews (rows of 3)
        let triggers = SeizureTrigger.allCases
        let columns = 3
        var rows: [[SeizureTrigger]] = []
        var currentRow: [SeizureTrigger] = []
        for trigger in triggers {
            currentRow.append(trigger)
            if currentRow.count == columns {
                rows.append(currentRow)
                currentRow = []
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 10
        outerStack.alignment = .fill
        outerStack.distribution = .equalSpacing
        outerStack.translatesAutoresizingMaskIntoConstraints = false

        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.alignment = .fill
            rowStack.distribution = .fillEqually

            for trigger in row {
                let btn = makeChipButton(for: trigger)
                chipButtons[trigger] = btn
                rowStack.addArrangedSubview(btn)
            }

            // If the last row doesn't have a full set of columns, pad it
            if row.count < columns {
                for _ in row.count..<columns {
                    let spacer = UIView()
                    spacer.isUserInteractionEnabled = false
                    rowStack.addArrangedSubview(spacer)
                }
            }

            outerStack.addArrangedSubview(rowStack)
        }

        container.addSubview(outerStack)

        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            outerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            outerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            outerStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }

    private func makeChipButton(for trigger: SeizureTrigger) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(trigger.displayName, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        btn.titleLabel?.numberOfLines = 2
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.lineBreakMode = .byWordWrapping

        var config = UIButton.Configuration.plain()
        config.titleAlignment = .center
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6)
        btn.configuration = config

        btn.layer.cornerRadius = 10
        btn.clipsToBounds = false
        applyUnselectedChipStyle(btn)

        btn.addTarget(self, action: #selector(triggerChipTapped(_:)), for: .touchUpInside)

        // Store tag for identity lookup (index in allCases)
        if let idx = SeizureTrigger.allCases.firstIndex(of: trigger) {
            btn.tag = idx
        }
        return btn
    }

    @objc private func triggerChipTapped(_ sender: UIButton) {
        guard let trigger = SeizureTrigger.allCases[safe: sender.tag] else { return }
        if selectedTriggers.contains(trigger) {
            selectedTriggers.remove(trigger)
            UIView.animate(withDuration: 0.2) { self.applyUnselectedChipStyle(sender) }
        } else {
            selectedTriggers.insert(trigger)
            UIView.animate(withDuration: 0.2) { self.applySelectedChipStyle(sender) }
        }
        validateForm()
    }

    // MARK: - Chip Styling

    private func applySelectedChipStyle(_ btn: UIButton) {
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.borderWidth = 0
        btn.layer.shadowOpacity = 0.2
        btn.layer.shadowRadius = 4
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    private func applyUnselectedChipStyle(_ btn: UIButton) {
        btn.backgroundColor = .systemGray6
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemBlue.cgColor
        btn.layer.shadowOpacity = 0
    }

    // MARK: - Form Configuration

    private func configureForAdd() {
        navigationItem.title = "Add Record"
        saveButton.title = "Save"

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: now)

        updateTimeBucket(from: now)
        duration = 0

        notesTextView.text = placeholderText
        notesTextView.textColor = .tertiaryLabel

        validateForm()
    }

    private func configureForEdit() {
        navigationItem.title = "Edit Record"
        saveButton.title = "Update"
        saveButton.isEnabled = true
        populateData()
    }

    private func populateData() {
        guard let record = recordToEdit else { return }

        titleTextField.text = record.title

        if let desc = record.description, !desc.isEmpty {
            notesTextView.text = desc
            notesTextView.textColor = .label
        } else {
            notesTextView.text = placeholderText
            notesTextView.textColor = .tertiaryLabel
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: record.dateTime)

        if let d = record.duration { duration = d }

        switch record.type {
        case .mild:     severitySegment.selectedSegmentIndex = 0
        case .moderate: severitySegment.selectedSegmentIndex = 1
        case .severe:   severitySegment.selectedSegmentIndex = 2
        default: break
        }

        switch record.timeBucket {
        case .morning:   timeOfDaySegment?.selectedSegmentIndex = 0
        case .afternoon: timeOfDaySegment?.selectedSegmentIndex = 1
        case .evening:   timeOfDaySegment?.selectedSegmentIndex = 2
        case .night:     timeOfDaySegment?.selectedSegmentIndex = 3
        default: updateTimeBucket(from: record.dateTime)
        }

        // Restore previously selected triggers
        if let triggers = record.triggers {
            for trigger in triggers where trigger != .unknown {
                selectedTriggers.insert(trigger)
                if let btn = chipButtons[trigger] {
                    applySelectedChipStyle(btn)
                }
            }
        }
        validateForm()
    }

    // MARK: - Save

    @IBAction func saveRecord(_ sender: UIBarButtonItem) {
        guard let title = titleTextField.text, !title.isEmpty,
              let dateString = dateTextField.text, !dateString.isEmpty,
              duration > 0 else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        guard let date = formatter.date(from: dateString) else { return }

        let severity: SeizureType = {
            switch severitySegment.selectedSegmentIndex {
            case 0: return .mild
            case 1: return .moderate
            default: return .severe
            }
        }()

        // Auto-assign Unknown if no trigger selected
        let triggers: [SeizureTrigger] = selectedTriggers.isEmpty
            ? [.unknown]
            : Array(selectedTriggers)

        let timeBucket: SeizureTimeBucket
        if let segment = timeOfDaySegment {
            switch segment.selectedSegmentIndex {
            case 0: timeBucket = .morning
            case 1: timeBucket = .afternoon
            case 2: timeBucket = .evening
            case 3: timeBucket = .night
            default: timeBucket = .unknown
            }
        } else {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<12: timeBucket = .morning
            case 12..<17: timeBucket = .afternoon
            case 17..<21: timeBucket = .evening
            default: timeBucket = .night
            }
        }

        var notes = notesTextView.text
        if notes == placeholderText && notesTextView.textColor == .tertiaryLabel { notes = "" }

        if let oldRecord = recordToEdit {
            let updatedRecord = SeizureRecord(
                id:          oldRecord.id,
                userId:      oldRecord.userId,
                entryType:   oldRecord.entryType,
                dateTime:    date,
                description: notes,
                type:        severity,
                duration:    duration,
                title:       title,
                triggers:    triggers,
                timeBucket:  timeBucket
            )
            SeizureRecordDataModel.shared.updateRecord(updatedRecord)
        } else {
            guard let user = UserDataModel.shared.getCurrentUser() else { return }
            let newRecord = SeizureRecord(
                id:          UUID(),
                userId:      user.id,
                entryType:   .manual,
                dateTime:    date,
                description: notes,
                type:        severity,
                duration:    duration,
                title:       title,
                triggers:    triggers,
                timeBucket:  timeBucket
            )
            SeizureRecordDataModel.shared.addManualRecord(newRecord)
        }

        onDismiss?()
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Validation

    func validateForm() {
        let isTitleValid    = !(titleTextField.text?.isEmpty ?? true)
        let isDateValid     = !(dateTextField.text?.isEmpty ?? true)
        let isDurationValid = duration > 0
        // Triggers are optional — Unknown is auto-assigned. No gate needed.
        saveButton.isEnabled = isTitleValid && isDateValid && isDurationValid
    }

    // MARK: - Date & Duration Pickers

    @objc private func openDatePicker() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let currentDate = formatter.date(from: dateTextField.text ?? "") ?? Date()
        let maxDate = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: Date()
        ) ?? Date()

        let sheet = SeizPickerSheet.datePicker(
            title: "Select Date",
            mode: .date,
            style: .inline,
            current: currentDate,
            maximumDate: maxDate
        ) { [weak self] selectedDate in
            guard let self else { return }
            self.dateTextField.text = formatter.string(from: selectedDate)
            self.updateTimeBucket(from: selectedDate)
            self.validateForm()
        }
        present(sheet, animated: true)
    }

    @objc private func openDurationPicker() {
        let sheet = SeizPickerSheet.durationPicker(
            title: "Select Duration",
            currentDuration: duration
        ) { [weak self] newDuration in
            self?.duration = newDuration
        }
        present(sheet, animated: true)
    }

    private func updateDurationLabel() {
        let min = Int(duration) / 60
        let sec = Int(duration) % 60
        if duration == 0 {
            durationLabel.text = "0 min 0 sec"
            durationLabel.textColor = .tertiaryLabel
        } else {
            var parts: [String] = []
            if min > 0 { parts.append("\(min) min") }
            if sec > 0 { parts.append("\(sec) sec") }
            durationLabel.text = parts.joined(separator: " ")
            durationLabel.textColor = .label
        }
    }

    // MARK: - Actions

    @IBAction func cancelButtonTapped(_ sender: Any) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc func textFieldChanged() { validateForm() }

    // MARK: - Time of Day

    private func setupTimeOfDaySegment() {
        guard let segment = timeOfDaySegment else { return }
        segment.applyPrimaryStyle()
    }

    private func updateTimeBucket(from date: Date) {
        let hour = Calendar.current.component(.hour, from: date)
        let index: Int
        switch hour {
        case 5..<12: index = 0
        case 12..<17: index = 1
        case 17..<21: index = 2
        default: index = 3
        }
        timeOfDaySegment?.selectedSegmentIndex = index
    }

    // MARK: - UITableView

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
}

// MARK: - UITextViewDelegate

extension AddRecordTableViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText && textView.textColor == .tertiaryLabel {
            textView.text = ""
            textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = .tertiaryLabel
        }
    }
}

// MARK: - Collection Safe Subscript
private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
