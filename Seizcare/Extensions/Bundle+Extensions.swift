//
//  Bundle+Extensions.swift
//  Seizcare
//
//  Created by Antigravity on 02/18/26.
//

import Foundation
import ObjectiveC

private var kBundleKey: UInt8 = 0

class LanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &kBundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ bundle: Bundle?) {
        object_setClass(Bundle.main, LanguageBundle.self)
        objc_setAssociatedObject(Bundle.main, &kBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
