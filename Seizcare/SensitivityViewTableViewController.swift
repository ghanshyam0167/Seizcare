import UIKit

class SensitivityViewTableViewController: UIViewController {

    // MARK: - Data
    // MARK: - Data
    private let sensitivities = ["Low".localized(), "Medium".localized(), "High".localized()]

    private let descriptions = [
        "Triggers alerts only for strong seizure patterns".localized(),
        "Balanced detection for everyday use".localized(),
        "Highly sensitive, detects even mild activity".localized()
    ]

    private var selectedIndex = 1 // Default = Medium

    // MARK: - Views
    private let cardView: UIView = {
        let v = UIView()
        // Pure white card background
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = false
        // Subtle shadow for elevation
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 0
        return sv
    }()

    private var rowControls: [SensitivityRowView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Title centered in nav bar
        let titleLabel = UILabel()
        titleLabel.text = "Sensitivity".localized()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel

        view.backgroundColor = .systemGroupedBackground

        loadSavedPreference()
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Horizontal padding 16–20pt, use 16
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28)
        ])

        // Build stack
        cardView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])

        // Create rows
        for i in 0..<sensitivities.count {
            let row = SensitivityRowView(title: sensitivities[i], subtitle: descriptions[i])
            row.tag = i
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            rowControls.append(row)

            stackView.addArrangedSubview(row)

            if i < sensitivities.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }

        // Ensure selected state reflects saved index
        for (i, r) in rowControls.enumerated() {
            r.setChecked(i == selectedIndex, animated: false)
        }
    }

    // MARK: - Actions

    @objc private func rowTapped(_ sender: SensitivityRowView) {
        let index = sender.tag
        guard index != selectedIndex else { return }

        let previous = selectedIndex
        selectedIndex = index

        // Persist
        UserDefaults.standard.set(sensitivities[selectedIndex], forKey: "sensitivityLevel")

        // Animate change
        rowControls[previous].setChecked(false, animated: true)
        rowControls[selectedIndex].setChecked(true, animated: true)
    }

    // MARK: - Persistence

    private func loadSavedPreference() {
        if let savedLevel = UserDefaults.standard.string(forKey: "sensitivityLevel"),
           let index = sensitivities.firstIndex(of: savedLevel) {
            selectedIndex = index
        }
    }
}

// MARK: - SensitivityRowView

private class SensitivityRowView: UIControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let checkImageView = UIImageView()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "", subtitle: "")
    }

    private func setup(title: String, subtitle: String) {
        // UIControl configuration for reliable touch detection
        self.isUserInteractionEnabled = true
        self.isExclusiveTouch = true
        self.backgroundColor = .clear
        
        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits = .button

        // Title Label
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        // Subtitle Label
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        // Checkmark ImageView
        checkImageView.image = UIImage(systemName: "checkmark")
        checkImageView.tintColor = .systemBlue
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.alpha = 0

        // Labels vertical stack
        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.alignment = .leading
        labelsStack.isUserInteractionEnabled = false

        // Main horizontal stack
        let hStack = UIStackView(arrangedSubviews: [labelsStack, checkImageView])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 12
        hStack.isUserInteractionEnabled = false

        addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            checkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func setChecked(_ checked: Bool, animated: Bool) {
        let animations = {
            self.checkImageView.alpha = checked ? 1.0 : 0.0
        }

        if animated {
            UIView.transition(with: checkImageView, duration: 0.22, options: [.transitionCrossDissolve], animations: animations, completion: nil)
        } else {
            animations()
        }
        accessibilityValue = checked ? "Selected" : "Not selected"
    }
}

