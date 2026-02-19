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
            self.updateTimeBucket(from: datePicker.date)
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
    
    // MARK: - Duration Picker Logic (Custom UIPickerView)
    @objc private func openDurationPicker() {
        let pickerVC = UIViewController()
        pickerVC.view.backgroundColor = .systemBackground
        pickerVC.modalPresentationStyle = .pageSheet
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "Select Duration"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(titleLabel)
        
        // Picker
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(pickerView)
        
        // Done Button
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: pickerVC.view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: pickerVC.view.centerXAnchor),
            
            doneButton.topAnchor.constraint(equalTo: pickerVC.view.topAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor, constant: -20),
            
            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            pickerView.leadingAnchor.constraint(equalTo: pickerVC.view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let adapter = DurationPickerAdapter(initialDuration: duration) { [weak self] newDuration in
            self?.duration = newDuration
        }
        
        // Hold strong reference to adapter in pickerVC (via objc association or wrapping)
        // Only for this simple task, we can use a closure-based wrapper or just a nested class.
        // Let's use a nested controller to keep it clean, or assign it as a property if possible.
        // Swift limitation: cannot easily attach arbitrary objects to UIViewController instance without subclassing.
        // Alternate approach: Embed the logic in a small subclass or closure. Use a helper logic carrier.
        
        // Better: Make AddRecordTableViewController the delegate? No, complicates it.
        // Let's use a wrapper property on the picker view itself using Associative Objects or just subclass UIPickerView.
        // Simpler: Just assign the delegate/dataSource to a persisted helper object.
        
        // Trick: The picker view holds a strong ref to delegate? No, it's weak.
        // WE need to hold the adapter.
        
        // Let's create a custom ViewController subclass inline or just add a property to the main class to hold the current adapter?
        // Adding `var currentDurationAdapter: DurationPickerAdapter?` to main class.
        self.currentDurationAdapter = adapter
        pickerView.delegate = adapter
        pickerView.dataSource = adapter
        
        // Select current row
        let min = Int(duration) / 60
        let sec = Int(duration) % 60
        pickerView.selectRow(min, inComponent: 0, animated: false)
        pickerView.selectRow(sec, inComponent: 1, animated: false)
        
        doneButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
            self?.currentDurationAdapter = nil // Cleanup
        }, for: .touchUpInside)

        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(pickerVC, animated: true)
    }
    
    // Hold reference to the adapter
    var currentDurationAdapter: DurationPickerAdapter?

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


// MARK: - Duration Picker Adapter
class DurationPickerAdapter: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    let onUpdate: (TimeInterval) -> Void
    
    init(initialDuration: TimeInterval, onUpdate: @escaping (TimeInterval) -> Void) {
        self.onUpdate = onUpdate
        super.init()
    }
    
    // 0: Minutes (0-59), 1: Seconds (0-59)
    // Actually, Minutes can go up to say 60 or 120? Let's say 60 for now based on "wheels" style usually cycling or fixed.
    // Let's go 0-300 min (5 hours) to be safe? Or just 0-60?
    // User request: "Count down timer style". usually 0-23 hours, 0-59 min.
    // But for seizure, maybe 0-59 min, 0-59 sec is typical.
    // Let's do Minutes (0-120), Seconds (0-59).
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 { return 121 } // 0-120 mins
        return 60 // 0-59 secs
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(row) min"
        } else {
            return "\(row) sec"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let min = pickerView.selectedRow(inComponent: 0)
        let sec = pickerView.selectedRow(inComponent: 1)
        let totalSeconds = TimeInterval((min * 60) + sec)
        onUpdate(totalSeconds)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 100
    }
}
