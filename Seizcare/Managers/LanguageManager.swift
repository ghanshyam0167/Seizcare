//
//  LanguageManager.swift
//  Seizcare
//
//  Created by Antigravity on 02/18/26.
//

import UIKit

enum Language: String, CaseIterable {
    case english = "en"
    case hindi = "hi"
    case marathi = "mr"
    case bengali = "bn"
    case tamil = "ta"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिंदी (Hindi)"
        case .marathi: return "मराठी (Marathi)"
        case .bengali: return "বাংলা (Bengali)"
        case .tamil: return "தமிழ் (Tamil)"
        }
    }
    
    var code: String {
        return rawValue
    }
}

class LanguageManager {
    static let shared = LanguageManager()
    private let kLanguageKey = "SeizcareSelectedLanguage"
    
    var currentLanguage: Language {
        get {
            if let savedCode = UserDefaults.standard.string(forKey: kLanguageKey),
               let language = Language(rawValue: savedCode) {
                return language
            }
            return .english
        }
        set {
            UserDefaults.standard.set(newValue.code, forKey: kLanguageKey)
            UserDefaults.standard.synchronize()
            applyLanguage(newValue)
        }
    }
    
    private init() {
        applyLanguage(currentLanguage)
    }
    
    /// Applies the language bundle to the app
    private func applyLanguage(_ language: Language) {
        let path = Bundle.main.path(forResource: language.code, ofType: "lproj")
        if let path = path {
            let bundle = Bundle(path: path)
            Bundle.setLanguage(bundle)
        } else {
            Bundle.setLanguage(Bundle.main)
        }
    }
    
    /// Reloads the entire app via SceneDelegate
    func setLanguage(_ language: Language) {
        currentLanguage = language
        
        // Reload root view controller safely
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
            return
        }
        sceneDelegate.reloadRootViewController()
    }
}
