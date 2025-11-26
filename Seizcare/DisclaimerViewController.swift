//
//  disclaimerViewController.swift
//  Seizcare
//
//  Created by Student on 25/11/25.
//

import UIKit

class DisclaimerViewController: UIViewController {

    // ADD THESE TWO PROPERTIES
    var receivedEmail: String?
    var receivedPassword: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Email received: \(receivedEmail ?? "")")
        print("Password received: \(receivedPassword ?? "")")
    }
}
