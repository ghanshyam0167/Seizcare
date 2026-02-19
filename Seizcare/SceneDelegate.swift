//
//  SceneDelegate.swift
//  Seizcare
//
//  Created by Student on 19/11/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    // MARK: - Safe Root Reload
    
    func reloadRootViewController() {
        guard let window = window else { return }
        
        // 1. Determine which storyboard to load.
        // Ideally, check if user is logged in. optimize for your app logic.
        // For Seizcare, usually starts with "Dashboard" if logged in, or "Main" (Login) if not.
        // Let's assume user is logged in since they are changing language from settings
        
        let storyboardName = "Dashboard" // Adjust this if your entry point varies
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        // 2. Instantiate Initial View Controller
        // Ensure your Dashboard storyboard has an Initial View Controller set
        let rootVC = storyboard.instantiateInitialViewController()
        
        // 3. Ensure it's a Navigation Controller to fix "navbar disappear" issue
        // If the storyboard's initial VC is NOT a Nav Controller, wrap it.
        let connectionVC: UIViewController
        
        if rootVC is UINavigationController {
            connectionVC = rootVC!
        } else {
            // Check if we need to wrap it
            // Assuming DashboardVC needs a nav controller
            let nav = UINavigationController(rootViewController: rootVC!)
            // Apply white navbar style if needed
            // nav.applyWhiteNavBar() // usage depends on your extensions
            connectionVC = nav
        }
        
        // 4. Animate the transition
        let transition = CATransition()
        transition.type = .fade // Fade is smoother for language change
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        window.layer.add(transition, forKey: "root-switch")
        window.rootViewController = connectionVC
        
        // 5. Localize TabBar if present
        if let nav = connectionVC as? UINavigationController,
           let tabBarVC = nav.viewControllers.first as? UITabBarController {
            localizeTabBar(tabBarVC)
        } else if let tabBarVC = connectionVC as? UITabBarController {
             localizeTabBar(tabBarVC)
        }
        
        window.makeKeyAndVisible()
    }
    
    private func localizeTabBar(_ tabBarVC: UITabBarController) {
        guard let items = tabBarVC.tabBar.items else { return }
        
        // Iterate and localize based on tag or index or fallback to known titles
        // Since we don't have subclass, we assume order or check titles
        // Assuming order: 0: Dashboard, 1: Records, 2: Profile (Adjust based on actual app)
        
        // Safer way: Check if title is "Dashboard" (English) then localize
        // But title might be empty if only icon.
        
        for (index, item) in items.enumerated() {
            // fallback logic based on index if titles are missing
            switch index {
            case 0: item.title = "Dashboard".localized()
            case 1: item.title = "Records".localized()
            case 2: item.title = "Profile".localized() // Or "Settings" depending on app
            default: break
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

