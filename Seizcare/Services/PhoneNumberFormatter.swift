//
//  PhoneNumberFormatter.swift
//  Seizcare
//
//  Normalizes user-entered phone numbers to E.164 format required by Twilio.
//

import Foundation

/// Normalizes any phone number string to E.164 format (e.g. "+918929394085").
///
/// Rules applied in order:
/// 1. Strip all characters except digits and a leading "+"
/// 2. If it already starts with "+"  → return as-is (already has country code)
/// 3. Strip a leading "0"            → removes trunk prefix
/// 4. Prepend "+91"                  → assumes India if no country code present
///
/// Examples:
/// ```
/// "8929394085"      → "+918929394085"
/// " 89293 94085 "   → "+918929394085"
/// "08929394085"     → "+918929394085"
/// "+918929394085"   → "+918929394085"
/// "(89293)-94085"   → "+918929394085"
/// ```
///
/// - Parameter raw: The phone number string as entered by the user.
/// - Returns: A formatted E.164 phone number string, or the cleaned string
///            unchanged if it cannot be normalised (never crashes).
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
