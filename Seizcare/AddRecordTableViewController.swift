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

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        [topInputsCardView, symptompsCardView, notesCardView].forEach {
            $0?.applyRecordCard()
        }
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
        guard let title = titleTextField.text, !title.isEmpty else { return }
            guard let dateString = dateTextField.text, !dateString.isEmpty else { return }
            guard let durationString = durationTextField.text, !durationString.isEmpty else { return }


            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            guard let date = formatter.date(from: dateString) else { return }
        print("coming2")
            // NEW: parse "1min 30sec"
            guard let durationSeconds = parseDuration(durationString) else {
                print("❌ Invalid duration")
                return
            }
    

            let symptoms = selectedSymptoms.map { $0.rawValue }
            let notes = notesTextView.text

            let severity: SeizureType = {
                switch severitySegment.selectedSegmentIndex {
                case 0: return .mild
                case 1: return .moderate
                default: return .severe
                }
            }()

            guard let user = UserDataModel.shared.getCurrentUser() else { return }
     

            let newRecord = SeizureRecord(
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
        let lower = text.lowercased()

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




    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
