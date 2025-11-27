//
//  DummySensitivityViewTableViewController.swift
//  Seizcare
//
//  Created by Diya Sharma on 25/11/25.
//

import UIKit

class SensitivityViewTableViewController: UITableViewController {

    @IBOutlet weak var highDescriptionLabel: UILabel!
    @IBOutlet weak var highTitleLabel: UILabel!
    @IBOutlet weak var mediumDescriptionLabel: UILabel!
    @IBOutlet weak var mediumTitleLabel: UILabel!
    @IBOutlet weak var horizontalStackView: UIStackView!
    @IBOutlet weak var verticalStack: UIStackView!

    @IBOutlet weak var lowDescriptionLabel: UILabel!
    @IBOutlet weak var lowTitleLabel: UILabel!
    @IBOutlet weak var bulletLabel: UILabel!
    @IBOutlet weak var highStackView: UIStackView!
    @IBOutlet weak var mediumStackView: UIStackView!
    @IBOutlet weak var lowStackView: UIStackView!
    @IBOutlet weak var highCheckMarkImageView: UIImageView!
    @IBOutlet weak var mediumCheckMarkImageView: UIImageView!
    @IBOutlet weak var lowCheckMarkImageView: UIImageView!
    @IBOutlet weak var upperCardView: UIView!
    private var selectedIndex: Int = 0   // 0 = Low, 1 = Medium, 2 = High

       
       override func viewDidLoad() {
           super.viewDidLoad()
           tableView.backgroundColor = UIColor.systemGray6   // full screen gray
           view.backgroundColor = UIColor.systemGray6        // just in case
           tableView.separatorStyle = .none                  // no default lines
           tableView.tableFooterView = UIView()              // removes extra space
          
           verticalStack.spacing = 14   // perfect

           
           setupCardView()
           setupInitialState()
           setupTapGestures()
           addSeparators()
           setupView()
           configureAllSections()

       }
       
       // UI Setup
       
    func setupCardView() {
        upperCardView.backgroundColor = .white
        upperCardView.layer.cornerRadius = 20
        upperCardView.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        upperCardView.layer.shadowOpacity = 0.2
        upperCardView.layer.shadowRadius = 10
        upperCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
    }

       
       
       func setupInitialState() {
           
           selectedIndex = 0
           updateCheckmarks()
       }
       
       
       func setupTapGestures() {
           lowStackView.tag = 0
           mediumStackView.tag = 1
           highStackView.tag = 2
           
           lowStackView.isUserInteractionEnabled = true
           mediumStackView.isUserInteractionEnabled = true
           highStackView.isUserInteractionEnabled = true
           
           lowStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:))))
           mediumStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:))))
           highStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:))))
       }
       
       
       // Actions
       
       @objc func optionTapped(_ sender: UITapGestureRecognizer) {
           guard let view = sender.view else { return }
           
           selectedIndex = view.tag
           updateCheckmarks()
       }
       
       
       func updateCheckmarks() {
           lowCheckMarkImageView.isHidden = selectedIndex != 0
           mediumCheckMarkImageView.isHidden = selectedIndex != 1
           highCheckMarkImageView.isHidden = selectedIndex != 2
           
           // Optional: animate checkmark
           UIView.animate(withDuration: 0.15) {
               self.view.layoutIfNeeded()
           }
       }

            
    
    func addSeparators() {
        let topLine = UIView()
        topLine.backgroundColor = UIColor.systemGray4
        topLine.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.systemGray4
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        
        upperCardView.addSubview(topLine)
        upperCardView.addSubview(bottomLine)
        
        NSLayoutConstraint.activate([
            
            topLine.leadingAnchor.constraint(equalTo: upperCardView.leadingAnchor, constant: 16),
            topLine.trailingAnchor.constraint(equalTo: upperCardView.trailingAnchor, constant: -16),
            topLine.topAnchor.constraint(equalTo: mediumStackView.topAnchor, constant: -5),
            topLine.heightAnchor.constraint(equalToConstant: 1),
            
            
            bottomLine.leadingAnchor.constraint(equalTo: upperCardView.leadingAnchor, constant: 16),
            bottomLine.trailingAnchor.constraint(equalTo: upperCardView.trailingAnchor, constant: -16),
            bottomLine.topAnchor.constraint(equalTo: mediumStackView.bottomAnchor, constant: 5),
            bottomLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    private func setupView() {

        // Bullet
        bulletLabel.text = "•"
        bulletLabel.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        bulletLabel.textColor = UIColor.darkGray

        // LOW section
        lowTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        lowTitleLabel.textColor = .black
        lowDescriptionLabel.font = UIFont.systemFont(ofSize: 15)
        lowDescriptionLabel.textColor = UIColor.darkGray
        lowDescriptionLabel.numberOfLines = 0

        // MEDIUM section
        mediumTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        mediumTitleLabel.textColor = .black
        mediumDescriptionLabel.font = UIFont.systemFont(ofSize: 15)
        mediumDescriptionLabel.textColor = UIColor.darkGray
        mediumDescriptionLabel.numberOfLines = 0

        // HIGH section
        highTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        highTitleLabel.textColor = .black
        highDescriptionLabel.font = UIFont.systemFont(ofSize: 15)
        highDescriptionLabel.textColor = UIColor.darkGray
        highDescriptionLabel.numberOfLines = 0
        
        // Remove extra padding inside stack views
        lowStackView.layoutMargins = .zero
        lowStackView.isLayoutMarginsRelativeArrangement = true

        mediumStackView.layoutMargins = .zero
        mediumStackView.isLayoutMarginsRelativeArrangement = true

        highStackView.layoutMargins = .zero
        highStackView.isLayoutMarginsRelativeArrangement = true

    }


    func configureAllSections() {

        // LOW
        lowTitleLabel.text = "Low"
        lowDescriptionLabel.text = """
        For users with less frequent or mild seizures.
        Fewer alerts, only for strong activity.
        Reduces false alarms.
        """

        // MEDIUM
        mediumTitleLabel.text = "Medium"
        mediumDescriptionLabel.text = """
        Balanced setting for most users.
        Detects typical seizure patterns.
        Good balance of accuracy and fewer false alerts.
        """

        // HIGH
        highTitleLabel.text = "High"
        highDescriptionLabel.text = """
        For users with frequent or high-risk seizures.
        Detects even small changes.
        May trigger more frequent alerts.
        """
    }


   }
