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
    @IBOutlet weak var durationTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    
    var selectedSymptoms: Set<Symptom> = []
    var onDismiss: (() -> Void)?

    var recordToEdit: SeizureRecord?   // nil = Add, non-nil = Edit
    var isEditMode: Bool {
        recordToEdit != nil
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(openDatePicker))
        dateTextField.addGestureRecognizer(tap)
        
        // Delegate for placeholder
        notesTextView.delegate = self

        seizureLevelSegment.applyPrimaryStyle()
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
        saveButton.isEnabled = false

            
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
        durationTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        if isEditMode {
            configureForEdit()
        } else {
            configureForAdd()
        }
        
        fixDateLabel()

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
        saveButton.isEnabled = false
        
        // Set default date to today
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = formatter.string(from: Date())
        
        // Initial placeholder
        notesTextView.text = placeholderText
        notesTextView.textColor = .tertiaryLabel
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

        if let duration = record.duration {
            let min = Int(duration) / 60
            let sec = Int(duration) % 60
            durationTextField.text = "\(min)min \(sec)sec"
        }

        switch record.type {
        case .mild: severitySegment.selectedSegmentIndex = 0
        case .moderate: severitySegment.selectedSegmentIndex = 1
        case .severe: severitySegment.selectedSegmentIndex = 2
        default: break
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
            guard let title = titleTextField.text, !title.isEmpty,
                  let dateString = dateTextField.text,
                  let durationString = durationTextField.text else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            guard let date = formatter.date(from: dateString),
                  let durationSeconds = parseDuration(durationString) else { return }

            let severity: SeizureType = {
                switch severitySegment.selectedSegmentIndex {
                case 0: return .mild
                case 1: return .moderate
                default: return .severe
                }
            }()

            let symptoms = selectedSymptoms.map { $0.rawValue }
//            let symptoms = selectedSymptoms.map { $0.rawValue }
            
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
                        duration: durationSeconds,
                        title: title,
                        symptoms: selectedSymptoms.map { $0.rawValue }
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
                    duration: durationSeconds,
                    title: title,
                    symptoms: symptoms
                )

                SeizureRecordDataModel.shared.addManualRecord(newRecord)
            }

            onDismiss?()
            dismiss(animated: true)
        
    }
    func validateForm() {
        let isTitleValid = !(titleTextField.text?.isEmpty ?? true)
        let isDateValid = !(dateTextField.text?.isEmpty ?? true)
        let isDurationValid = !(durationTextField.text?.isEmpty ?? true)
        
        let isSymptomsValid = !selectedSymptoms.isEmpty
        
        saveButton.isEnabled = isTitleValid && isDateValid && isDurationValid && isSymptomsValid
    }
    func parseDuration(_ text: String) -> TimeInterval? {
        let lower = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 1. Try plain number -> treat as seconds
        if let value = Double(lower) {
            return value
        }

        var minutes: Double = 0
        var seconds: Double = 0

        // Extract minutes
        if let minRange = lower.range(of: "min") {
            let num = lower[..<minRange.lowerBound].trimmingCharacters(in: .whitespaces)
            minutes = Double(num) ?? 0
        }

        // Extract seconds
        if let secRange = lower.range(of: "sec") {
            // find the number before "sec"
            let before = lower[..<secRange.lowerBound]
            if let lastSpace = before.lastIndex(of: " ") {
                let secString = before[before.index(after: lastSpace)...]
                seconds = Double(secString) ?? 0
            } else {
                // E.g. "30sec" where no space found, but we know it's seconds because we checked "sec"
                // Try to parse the whole chunk before "sec" if it's just a number
                 let num = before.trimmingCharacters(in: .whitespaces)
                 seconds = Double(num) ?? 0
            }
        }

        return (minutes * 60) + seconds
    }
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }

    @objc private func openDatePicker() {

        let pickerVC = UIViewController()
        pickerVC.view.backgroundColor = .systemBackground
        pickerVC.modalPresentationStyle = .pageSheet

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        
        // Allow all of today by setting max to end of today (23:59:59)
        let calendar = Calendar.current
        if let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) {
            datePicker.maximumDate = endOfToday
        } else {
            datePicker.maximumDate = Date()
        }

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(datePicker)
        
        // Add Done button
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: pickerVC.view.topAnchor, constant: 60),
            datePicker.leadingAnchor.constraint(equalTo: pickerVC.view.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor, constant: -16),
            datePicker.bottomAnchor.constraint(equalTo: pickerVC.view.bottomAnchor, constant: -20),
            
            doneButton.topAnchor.constraint(equalTo: pickerVC.view.topAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor, constant: -20)
        ])

        // Handle selection with Done button
        doneButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            self.dateTextField.text = formatter.string(from: datePicker.date)
            self.validateForm()
            self.dismiss(animated: true)
        }, for: .touchUpInside)

        // Sheet style (iOS 15+)
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }

        present(pickerVC, animated: true)
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
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


