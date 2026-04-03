//
//  PhoneNumberFormatter.swift
//  Seizcare
//
//  Normalizes user-entered phone numbers to E.164 format required by Twilio.
//

import Foundation


func formatPhoneNumber(_ raw: String) -> String {
    // Step 1: Preserve leading "+" then strip all non-digit characters
    let hasPlus = raw.hasPrefix("+")
    let digitsOnly = raw.unicodeScalars
        .filter { CharacterSet.decimalDigits.contains($0) }
        .map { Character($0) }
    let digits = String(digitsOnly)

    // Step 2: Already has a country code (started with "+")
    if hasPlus {
        return "+\(digits)"
    }

    // Step 3 & 4: No country code — strip leading zero then prepend +91
    let number = digits.hasPrefix("0") ? String(digits.dropFirst()) : digits
    return "+91\(number)"
}
