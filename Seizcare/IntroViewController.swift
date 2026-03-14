import UIKit

class IntroViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.subviews.forEach { $0.isHidden = true }
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Build UI

    private func buildUI() {

        // ── Centering wrapper ──
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wrapper)

        NSLayoutConstraint.activate([
            wrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            wrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            wrapper.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20)
        ])

        // ── Main stack ──
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: wrapper.topAnchor),
            stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

        // ── 1. App Logo ──
        let logo = UIImageView(image: UIImage(named: "Image"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.layer.shadowColor = UIColor.black.cgColor
        logo.layer.shadowOpacity = 0.08
        logo.layer.shadowRadius = 12
        logo.layer.shadowOffset = CGSize(width: 0, height: 6)
        stack.addArrangedSubview(logo)
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 250),
            logo.heightAnchor.constraint(equalToConstant: 250)
        ])
        stack.setCustomSpacing(28, after: logo)

        // ── 2. Title ──
        let titleLabel = UILabel()
        titleLabel.text = "Your Seizure Safety\nCompanion"
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(titleLabel)
        titleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stack.setCustomSpacing(12, after: titleLabel)

        // ── 3. Subtitle ──
        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 5
        para.alignment = .center
        subtitleLabel.attributedText = NSAttributedString(
            string: "Real-time vitals from your Apple Watch with smart detection to help manage epilepsy confidently.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: para
            ])
        stack.addArrangedSubview(subtitleLabel)
        subtitleLabel.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24).isActive = true
        stack.setCustomSpacing(32, after: subtitleLabel)

        // ── 4. Features Card ──
        let featuresCard = makeFeaturesCard()
        stack.addArrangedSubview(featuresCard)
        featuresCard.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stack.setCustomSpacing(36, after: featuresCard)

        // ── 5. CTA Button ──
        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle("Start Setup", for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.backgroundColor = .systemBlue
        ctaButton.layer.cornerRadius = 26
        ctaButton.layer.shadowColor = UIColor.black.cgColor
        ctaButton.layer.shadowOpacity = 0.12
        ctaButton.layer.shadowRadius = 10
        ctaButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        ctaButton.layer.masksToBounds = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        stack.addArrangedSubview(ctaButton)
        NSLayoutConstraint.activate([
            ctaButton.widthAnchor.constraint(equalTo: stack.widthAnchor),
            ctaButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    // MARK: - Features Card

    private func makeFeaturesCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.translatesAutoresizingMaskIntoConstraints = false

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 0
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        // Feature Row 1
        let row1 = makeFeatureRow(
            icon: "heart.circle.fill",
            title: "Real-Time Vitals",
            desc: "Continuous tracking of key health metrics"
        )
        cardStack.addArrangedSubview(row1)
        cardStack.setCustomSpacing(14, after: row1)

        // Separator
        let sep = UIView()
        sep.backgroundColor = .separator.withAlphaComponent(0.3)
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        cardStack.addArrangedSubview(sep)
        cardStack.setCustomSpacing(14, after: sep)

        // Feature Row 2
        let row2 = makeFeatureRow(
            icon: "exclamationmark.triangle.fill",
            title: "Swift Alerts",
            desc: "Instantly notify emergency contacts"
        )
        cardStack.addArrangedSubview(row2)

        return card
    }

    private func makeFeatureRow(icon: String, title: String, desc: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        row.addSubview(iconView)

        // Title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        row.addSubview(titleLabel)

        // Desc
        let descLabel = UILabel()
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.text = desc
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        row.addSubview(descLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: row.topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: row.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }

    // MARK: - Actions

    @objc private func ctaTapped() {
        performSegue(withIdentifier: "startSetupSegue", sender: self)
    }
}
