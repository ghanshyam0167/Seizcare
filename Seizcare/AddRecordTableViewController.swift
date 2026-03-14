//
//  AddRecordTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit

enum Symptom: String {
    case dejaVu = "Déjà vu"
    case anxiety = "Anxiety"
    case visualChange = "Visual Change"
    case oddSmell = "Odd Smell/Taste"
    case dizziness = "Dizziness"
    case nausea = "Nausea"
    case confused = "Confused"
    case tired = "Tired"
    case headache = "Headache"
    case bodyAche = "Body Ache"
    case weakness = "Weakness"
    case memoryLoss = "Memory Loss"
}

class AddRecordTableViewController: UITableViewController {

    @IBOutlet weak var seizureLevelSegment: UISegmentedControl!
    @IBOutlet weak var timeOfDaySegment: UISegmentedControl!
    @IBOutlet weak var topInputsCardView: UIView!
    @IBOutlet weak var notesCardView: UIView!
    @IBOutlet weak var symptompsCardView: UIView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var memoryLossSymptomButton: UIButton!
    @IBOutlet weak var weaknessSymptomButton: UIButton!
    @IBOutlet weak var bodyacheSymptomButton: UIButton!
    @IBOutlet weak var headacheSymptomButton: UIButton!
    @IBOutlet weak var tiredSymptomButton: UIButton!
    @IBOutlet weak var confusedSymptomButton: UIButton!
    @IBOutlet weak var nauseaSymptomButton: UIButton!
    @IBOutlet weak var dizzinesSymptomButton: UIButton!
    @IBOutlet weak var smellSymptomButton: UIButton!
    @IBOutlet weak var visualChangeSymptomButton: UIButton!
    @IBOutlet weak var anxietySymptomButton: UIButton!
    @IBOutlet weak var dejavuSymptomButton: UIButton!
    @IBOutlet weak var severitySegment: UISegmentedControl!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    
    var selectedSymptoms: Set<Symptom> = []
    var onDismiss: (() -> Void)?

    var recordToEdit: SeizureRecord?   // nil = Add, non-nil = Edit
    var isEditMode: Bool {
        recordToEdit != nil
    }
    
    // Duration in seconds
    var duration: TimeInterval = 0 {
        didSet {
            updateDurationLabel()
            validateForm()
        }
    }

    private let placeholderText = "Add your notes here..."

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        [topInputsCardView, symptompsCardView, notesCardView].forEach {
            $0?.applyRecordCard()
        }


        dateTextField.isUserInteractionEnabled = true
        let tapDate = UITapGestureRecognizer(target: self, action: #selector(openDatePicker))
        dateTextField.addGestureRecognizer(tapDate)
        
        // Duration Label Interaction
        durationLabel.isUserInteractionEnabled = true
        let tapDuration = UITapGestureRecognizer(target: self, action: #selector(openDurationPicker))
        durationLabel.addGestureRecognizer(tapDuration)
        
        // Delegate for placeholder
        notesTextView.delegate = self

        seizureLevelSegment.applyPrimaryStyle()
        setupTimeOfDaySegment()

        let symptomButtons = [
                dejavuSymptomButton,
                anxietySymptomButton,
                visualChangeSymptomButton,
                smellSymptomButton,
                dizzinesSymptomButton,
                nauseaSymptomButton,
                confusedSymptomButton,
                tiredSymptomButton,
                headacheSymptomButton,
                bodyacheSymptomButton,
                weaknessSymptomButton,
                memoryLossSymptomButton
            ]
        
        // Note: saveButton enabled state is managed by validateForm() called in configureForAdd/Edit
        
        // Explicitly set gray color for disabled state
        saveButton.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .disabled)
            
        for button in symptomButtons {
            guard let btn = button else { continue }

            var config = btn.configuration ?? UIButton.Configuration.plain()

            config.titleAlignment = .center
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

       
            btn.configuration = config


            btn.layer.cornerRadius = 10
            btn.clipsToBounds = false
            btn.backgroundColor = .systemGray6
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemBlue.cgColor
            btn.setTitleColor(.systemBlue, for: .normal)

         
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }
        
        titleTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        dateTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        if isEditMode {
            configureForEdit()
        } else {
            configureForAdd()
        }
    }


    private func fixDateLabel() {
        // Recursively find "Date & Time" label and change to "Date"
        func scan(view: UIView) {
            if let label = view as? UILabel, label.text == "Date & Time" {
                label.text = "Date"
            }
            view.subviews.forEach { scan(view: $0) }
        }
        scan(view: view)
    }
    private func configureForAdd() {
        navigationItem.title = "Add Record"
        saveButton.title = "Save"
        
        // Set default date to today
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: now)
        
        updateTimeBucket(from: now)
        
        // Default Duration
        duration = 0
        
        // Initial placeholder
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

        if let d = record.duration {
            duration = d
        }

        switch record.type {
        case .mild: severitySegment.selectedSegmentIndex = 0
        case .moderate: severitySegment.selectedSegmentIndex = 1
        case .severe: severitySegment.selectedSegmentIndex = 2
        default: break
        }
        
        switch record.timeBucket {
        case .morning: timeOfDaySegment?.selectedSegmentIndex = 0
        case .afternoon: timeOfDaySegment?.selectedSegmentIndex = 1
        case .evening: timeOfDaySegment?.selectedSegmentIndex = 2
        case .night: timeOfDaySegment?.selectedSegmentIndex = 3
        default: updateTimeBucket(from: record.dateTime)
        }

        if let symptoms = record.symptoms {
            for symptom in symptoms {
                if let s = Symptom(rawValue: symptom),
                   let btn = button(for: s) {
                    selectedSymptoms.insert(s)
                    highlight(button: btn)
                }
            }
        }
        validateForm()
    }
    private func button(for symptom: Symptom) -> UIButton? {
        switch symptom {
        case .dejaVu: return dejavuSymptomButton
        case .anxiety: return anxietySymptomButton
        case .visualChange: return visualChangeSymptomButton
        case .oddSmell: return smellSymptomButton
        case .dizziness: return dizzinesSymptomButton
        case .nausea: return nauseaSymptomButton
        case .confused: return confusedSymptomButton
        case .tired: return tiredSymptomButton
        case .headache: return headacheSymptomButton
        case .bodyAche: return bodyacheSymptomButton
        case .weakness: return weaknessSymptomButton
        case .memoryLoss: return memoryLossSymptomButton
        }
    }

    @objc func textFieldChanged() {
        validateForm()
    }
    
    
    @IBAction func symptomTapped(_ sender: UIButton) {
        guard let symptom = Symptom(rawValue: symptomNameFromTag(sender.tag)) else { return }

           if selectedSymptoms.contains(symptom) {
               selectedSymptoms.remove(symptom)
               unHighlight(button: sender)
           } else {
               selectedSymptoms.insert(symptom)
               highlight(button: sender)
           }
        validateForm()
    }
    func symptomNameFromTag(_ tag: Int) -> String {
        switch tag {
        case 0: return Symptom.dejaVu.rawValue
        case 1: return Symptom.anxiety.rawValue
        case 2: return Symptom.visualChange.rawValue
        case 3: return Symptom.oddSmell.rawValue
        case 4: return Symptom.dizziness.rawValue
        case 5: return Symptom.nausea.rawValue
        case 6: return Symptom.confused.rawValue
        case 7: return Symptom.tired.rawValue
        case 8: return Symptom.headache.rawValue
        case 9: return Symptom.bodyAche.rawValue
        case 10: return Symptom.weakness.rawValue
        case 11: return Symptom.memoryLoss.rawValue
        default:
            return ""
        }
    }

    
    func highlight(button: UIButton) {
        UIView.animate(withDuration: 0.2) {
            button.backgroundColor = UIColor.systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
            button.layer.shadowOpacity = 0.2
            button.layer.shadowRadius = 4
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }


    func unHighlight(button: UIButton) {
        UIView.animate(withDuration: 0.2) {
            button.backgroundColor = UIColor.systemGray6
            button.setTitleColor(.systemBlue, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.layer.shadowOpacity = 0
        }
    }


    
    @IBAction func saveRecord(_ sender: UIBarButtonItem) {
        // Validation is handled by safe-guards and button state
        guard let title = titleTextField.text, !title.isEmpty,
              let dateString = dateTextField.text, !dateString.isEmpty,
              duration > 0,
              !selectedSymptoms.isEmpty else { return }
        
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

        let symptoms = selectedSymptoms.map { $0.rawValue }
        
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
             // Fallback if UI not connected: derive from date
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<12: timeBucket = .morning
            case 12..<17: timeBucket = .afternoon
            case 17..<21: timeBucket = .evening
            default: timeBucket = .night
            }
        }
        
        var notes = notesTextView.text
        if notes == placeholderText && notesTextView.textColor == .tertiaryLabel {
            notes = ""
        }

        if let oldRecord = recordToEdit {
            let updatedRecord = SeizureRecord(
                    id: oldRecord.id,  
                    userId: oldRecord.userId,
                    entryType: oldRecord.entryType,
                    dateTime: date,
                    description: notes,
                    type: severity,
                    duration: duration,
                    title: title,
                    symptoms: selectedSymptoms.map { $0.rawValue },
                    timeBucket: timeBucket
                )

                SeizureRecordDataModel.shared.updateRecord(updatedRecord)
        } else {
            // ➕ ADD
            guard let user = UserDataModel.shared.getCurrentUser() else { return }

            let newRecord = SeizureRecord(
                id : UUID(),
                userId: user.id,
                entryType: .manual,
                dateTime: date,
                description: notes,
                type: severity,
                duration: duration,
                title: title,
                symptoms: symptoms,
                timeBucket: timeBucket
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

    func validateForm() {
        let isTitleValid = !(titleTextField.text?.isEmpty ?? true)
        let isDateValid = !(dateTextField.text?.isEmpty ?? true)
        let isDurationValid = duration > 0
        let isSymptomsValid = !selectedSymptoms.isEmpty
        
        saveButton.isEnabled = isTitleValid && isDateValid && isDurationValid && isSymptomsValid
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }

    @objc private func openDatePicker() {
        // Parse existing date from field
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let currentDate = formatter.date(from: dateTextField.text ?? "") ?? Date()

        // Max = end of today
        let calendar = Calendar.current
        let maxDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()

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

    @IBAction func cancelButtonTapped(_ sender: Any) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    
    
    private func setupTimeOfDaySegment() {
         guard let segment = timeOfDaySegment else { return }
         
         // Segments are defined in Storyboard: Morning, Afternoon, Evening, Night
         
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
}

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
