import UIKit
import SwiftUI

class DisclaimerViewController: UIViewController {

    // MARK: - Properties
    var receivedEmail: String?
    var receivedPassword: String?
    var currentUser: User?

    //  Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Email received: \(receivedEmail ?? "")")
        print("Password received: \(receivedPassword ?? "")")
        
        // Remove back button
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Host SwiftUI View
        setupSwiftUIInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Disable interactive pop gesture
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    private func setupSwiftUIInterface() {
        // Create the SwiftUI view with the navigation callback
        let disclaimerView = DisclaimerView { [weak self] in
            self?.navigateToOnboarding()
        }
        
        // Host it
        let hostingController = UIHostingController(rootView: disclaimerView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    // MARK: - Actions
    
    private func navigateToOnboarding() {
        // Navigate to NewUserOnboarding storyboard
        let onboardingStoryboard = UIStoryboard(name: "NewUserOnboarding", bundle: nil)
        if let onboardingVC = onboardingStoryboard.instantiateInitialViewController() {
            onboardingVC.modalPresentationStyle = .fullScreen
            present(onboardingVC, animated: true, completion: nil)
        }
    }
}
