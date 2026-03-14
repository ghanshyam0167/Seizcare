//
//  SeizPickerSheet.swift
//  Seizcare
//
//  Unified picker bottom-sheet component.
//  Provides consistent styling for all pickers in the app.
//

import UIKit

// MARK: - SeizPickerSheet

class SeizPickerSheet: UIViewController {

    // MARK: - Design Tokens
    private let headerHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 28

    // MARK: - Header Views
    private let cancelButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let doneButton = UIButton(type: .system)
    private let divider = UIView()

    // MARK: - Content
    private var contentView: UIView?
    private var onCancel: (() -> Void)?
    private var onDone: (() -> Void)?

    // MARK: - Init

    init(title: String, content: UIView, onDone: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.titleLabel.text = title
        self.contentView = content
        self.onDone = onDone
        self.onCancel = onCancel
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHeader()
        setupContent()
        configureSheet()
    }

    // MARK: - Sheet Config

    private func configureSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = cornerRadius
        }
    }

    // MARK: - Header

    private func setupHeader() {
        // Cancel
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.tintColor = .systemBlue
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Done
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        doneButton.tintColor = .systemBlue
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)

        // Divider
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    // MARK: - Content

    private func setupContent() {
        guard let contentView = contentView else { return }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        onDone?()
        dismiss(animated: true)
    }
}

// MARK: - Factory: Date Picker

extension SeizPickerSheet {

    static func datePicker(
        title: String,
        mode: UIDatePicker.Mode = .date,
        style: UIDatePickerStyle = .inline,
        current: Date? = nil,
        maximumDate: Date? = nil,
        minimumDate: Date? = nil,
        onDone: @escaping (Date) -> Void
    ) -> SeizPickerSheet {

        let picker = UIDatePicker()
        picker.datePickerMode = mode
        picker.preferredDatePickerStyle = style
        if let current = current { picker.date = current }
        if let max = maximumDate { picker.maximumDate = max }
        if let min = minimumDate { picker.minimumDate = min }

        let sheet = SeizPickerSheet(title: title, content: picker) {
            onDone(picker.date)
        }
        return sheet
    }

    /// Custom styled DOB picker using 3-column UIPickerView (Day / Month / Year)
    /// Matches the same bold/light row styling as other pickers.
    static func dobPicker(
        title: String,
        current: Date,
        minimumYear: Int? = nil,
        maximumYear: Int? = nil,
        onDone: @escaping (Date) -> Void
    ) -> SeizPickerSheet {

        let container = UIView()

        // Column labels
        let labelStack = UIStackView()
        labelStack.axis = .horizontal
        labelStack.distribution = .fillEqually
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        for text in ["Day", "Month", "Year"] {
            let lbl = UILabel()
            lbl.text = text
            lbl.font = .systemFont(ofSize: 12, weight: .semibold)
            lbl.textColor = .secondaryLabel
            lbl.textAlignment = .center
            labelStack.addArrangedSubview(lbl)
        }
        container.addSubview(labelStack)

        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pickerView)

        NSLayoutConstraint.activate([
            labelStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            labelStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            pickerView.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 4),
            pickerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200),
            pickerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let cal = Calendar.current
        let minYear = minimumYear ?? cal.component(.year, from: Date()) - 100
        let maxYear = maximumYear ?? cal.component(.year, from: Date())

        let adapter = StyledDOBAdapter(minYear: minYear, maxYear: maxYear)
        pickerView.delegate = adapter
        pickerView.dataSource = adapter

        // Set current date
        let day = cal.component(.day, from: current)
        let month = cal.component(.month, from: current)
        let year = cal.component(.year, from: current)
        pickerView.selectRow(day - 1, inComponent: 0, animated: false)
        pickerView.selectRow(month - 1, inComponent: 1, animated: false)
        pickerView.selectRow(year - minYear, inComponent: 2, animated: false)

        let sheet = SeizPickerSheet(title: title, content: container) {
            let d = pickerView.selectedRow(inComponent: 0) + 1
            let m = pickerView.selectedRow(inComponent: 1) + 1
            let y = minYear + pickerView.selectedRow(inComponent: 2)
            var comps = DateComponents()
            comps.day = d; comps.month = m; comps.year = y
            if let date = cal.date(from: comps) {
                onDone(date)
            }
        }
        sheet._dobAdapter = adapter
        return sheet
    }

    private static var dobAdapterKey: UInt8 = 0
    var _dobAdapter: StyledDOBAdapter? {
        get { objc_getAssociatedObject(self, &SeizPickerSheet.dobAdapterKey) as? StyledDOBAdapter }
        set { objc_setAssociatedObject(self, &SeizPickerSheet.dobAdapterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - Styled DOB Adapter

class StyledDOBAdapter: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    let minYear: Int
    let maxYear: Int
    private let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

    init(minYear: Int, maxYear: Int) {
        self.minYear = minYear
        self.maxYear = maxYear
        super.init()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return 31       // days
        case 1: return 12       // months
        case 2: return maxYear - minYear + 1  // years
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 40 }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center

        switch component {
        case 0: label.text = "\(row + 1)"
        case 1: label.text = months[row]
        case 2: label.text = "\(minYear + row)"
        default: break
        }

        let isSelected = pickerView.selectedRow(inComponent: component) == row
        label.font = isSelected ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 17, weight: .regular)
        label.textColor = isSelected ? .label : .tertiaryLabel
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadComponent(component)
        pickerView.selectRow(row, inComponent: component, animated: false)
    }
}

// MARK: - Factory: Duration Picker

extension SeizPickerSheet {

    static func durationPicker(
        title: String,
        currentDuration: TimeInterval,
        onDone: @escaping (TimeInterval) -> Void
    ) -> SeizPickerSheet {

        let container = UIView()

        // Column labels
        let labelStack = UIStackView()
        labelStack.axis = .horizontal
        labelStack.distribution = .fillEqually
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        let minutesLabel = UILabel()
        minutesLabel.text = "Minutes"
        minutesLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        minutesLabel.textColor = .secondaryLabel
        minutesLabel.textAlignment = .center

        let secondsLabel = UILabel()
        secondsLabel.text = "Seconds"
        secondsLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        secondsLabel.textColor = .secondaryLabel
        secondsLabel.textAlignment = .center

        labelStack.addArrangedSubview(minutesLabel)
        labelStack.addArrangedSubview(secondsLabel)
        container.addSubview(labelStack)

        // Picker view
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pickerView)

        NSLayoutConstraint.activate([
            labelStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            labelStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            pickerView.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 4),
            pickerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200),
            pickerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Adapter
        let adapter = StyledDurationAdapter(initialDuration: currentDuration)
        pickerView.delegate = adapter
        pickerView.dataSource = adapter

        // Select current values
        let min = Int(currentDuration) / 60
        let sec = Int(currentDuration) % 60
        pickerView.selectRow(min, inComponent: 0, animated: false)
        pickerView.selectRow(sec, inComponent: 1, animated: false)

        let sheet = SeizPickerSheet(title: title, content: container) {
            let selectedMin = pickerView.selectedRow(inComponent: 0)
            let selectedSec = pickerView.selectedRow(inComponent: 1)
            let total = TimeInterval((selectedMin * 60) + selectedSec)
            onDone(total)
        }

        // Hold adapter reference
        sheet._durationAdapter = adapter

        return sheet
    }

    // Strong ref holder to prevent dealloc
    private static var adapterKey: UInt8 = 0
    var _durationAdapter: StyledDurationAdapter? {
        get { objc_getAssociatedObject(self, &SeizPickerSheet.adapterKey) as? StyledDurationAdapter }
        set { objc_setAssociatedObject(self, &SeizPickerSheet.adapterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - Styled Duration Adapter

class StyledDurationAdapter: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {

    private(set) var currentDuration: TimeInterval

    init(initialDuration: TimeInterval) {
        self.currentDuration = initialDuration
        super.init()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        component == 0 ? 121 : 60  // 0-120 min, 0-59 sec
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        40
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        120
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center

        let isSelected = pickerView.selectedRow(inComponent: component) == row
        let unit = component == 0 ? "min" : "sec"
        label.text = "\(row) \(unit)"

        if isSelected {
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.textColor = .label
        } else {
            label.font = .systemFont(ofSize: 17, weight: .regular)
            label.textColor = .tertiaryLabel
        }

        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let min = pickerView.selectedRow(inComponent: 0)
        let sec = pickerView.selectedRow(inComponent: 1)
        currentDuration = TimeInterval((min * 60) + sec)

        // Refresh visible rows to update bold/light styling
        pickerView.reloadComponent(component)
        pickerView.selectRow(row, inComponent: component, animated: false)
    }
}

// MARK: - Factory: Option Picker (single column list)

extension SeizPickerSheet {

    static func optionPicker(
        title: String,
        options: [String],
        selected: String?,
        onDone: @escaping (String) -> Void
    ) -> SeizPickerSheet {

        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(pickerView)

        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            pickerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200),
            pickerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let adapter = StyledOptionAdapter(options: options)
        pickerView.delegate = adapter
        pickerView.dataSource = adapter

        // Select current value
        if let selected = selected, let idx = options.firstIndex(of: selected) {
            pickerView.selectRow(idx, inComponent: 0, animated: false)
        }

        let sheet = SeizPickerSheet(title: title, content: container) {
            let row = pickerView.selectedRow(inComponent: 0)
            onDone(options[row])
        }
        sheet._optionAdapter = adapter
        return sheet
    }

    private static var optionAdapterKey: UInt8 = 0
    var _optionAdapter: StyledOptionAdapter? {
        get { objc_getAssociatedObject(self, &SeizPickerSheet.optionAdapterKey) as? StyledOptionAdapter }
        set { objc_setAssociatedObject(self, &SeizPickerSheet.optionAdapterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - Styled Option Adapter

class StyledOptionAdapter: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    let options: [String]

    init(options: [String]) {
        self.options = options
        super.init()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { options.count }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 40 }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center
        label.text = options[row]
        let isSelected = pickerView.selectedRow(inComponent: 0) == row
        label.font = isSelected ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 17, weight: .regular)
        label.textColor = isSelected ? .label : .tertiaryLabel
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadComponent(0)
        pickerView.selectRow(row, inComponent: 0, animated: false)
    }
}

// MARK: - Factory: Numeric Picker (single value with unit)

extension SeizPickerSheet {

    static func numericPicker(
        title: String,
        unit: String,
        range: ClosedRange<Double>,
        step: Double = 1.0,
        current: Double,
        onDone: @escaping (Double) -> Void
    ) -> SeizPickerSheet {

        let container = UIView()

        // Unit label
        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        unitLabel.textColor = .secondaryLabel
        unitLabel.textAlignment = .center
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(unitLabel)

        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pickerView)

        NSLayoutConstraint.activate([
            unitLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            unitLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            pickerView.topAnchor.constraint(equalTo: unitLabel.bottomAnchor, constant: 4),
            pickerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200),
            pickerView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        let adapter = StyledNumericAdapter(range: range, step: step, unit: unit)
        pickerView.delegate = adapter
        pickerView.dataSource = adapter

        // Select current value
        let idx = adapter.index(for: current)
        pickerView.selectRow(idx, inComponent: 0, animated: false)

        let sheet = SeizPickerSheet(title: title, content: container) {
            let row = pickerView.selectedRow(inComponent: 0)
            onDone(adapter.value(for: row))
        }
        sheet._numericAdapter = adapter
        return sheet
    }

    private static var numericAdapterKey: UInt8 = 0
    var _numericAdapter: StyledNumericAdapter? {
        get { objc_getAssociatedObject(self, &SeizPickerSheet.numericAdapterKey) as? StyledNumericAdapter }
        set { objc_setAssociatedObject(self, &SeizPickerSheet.numericAdapterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - Styled Numeric Adapter

class StyledNumericAdapter: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    let lowerBound: Double
    let step: Double
    let count: Int
    let unit: String

    init(range: ClosedRange<Double>, step: Double, unit: String) {
        self.lowerBound = range.lowerBound
        self.step = step
        self.unit = unit
        self.count = Int((range.upperBound - range.lowerBound) / step) + 1
        super.init()
    }

    func value(for row: Int) -> Double { lowerBound + Double(row) * step }
    func index(for value: Double) -> Int {
        max(0, min(count - 1, Int((value - lowerBound) / step)))
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { count }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 40 }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center
        let val = value(for: row)
        // Show integer if whole number, otherwise 1 decimal
        label.text = val.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(val)) \(unit)" : String(format: "%.1f \(unit)", val)
        let isSelected = pickerView.selectedRow(inComponent: 0) == row
        label.font = isSelected ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 17, weight: .regular)
        label.textColor = isSelected ? .label : .tertiaryLabel
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.reloadComponent(0)
        pickerView.selectRow(row, inComponent: 0, animated: false)
    }
}
