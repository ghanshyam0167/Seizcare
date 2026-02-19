//
//  String+Extensions.swift
//  Seizcare
//
//  Created by Antigravity on 02/18/26.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
