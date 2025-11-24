//
//  RecordsDummy.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

//
//  RecordsDummy.swift
//  Seizcare
//

import Foundation

struct Record {
    let title: String          // Severe, Moderate, Mild
    let date: String           // "13 OCT"
    let duration: String       // "1 min 45 sec"
    let severity: Int          // 0 = Mild, 1 = Moderate, 2 = Severe
    let symptoms: [String]     // ["Dizziness", "Nausea"]
    let notes: String          // User notes

    // ADDITIONAL FIELDS for Detail Screen
    let location: String       // "Chandigarh, Sector 14"
    let heartRate: Int         // e.g. 110
    let spo2: Int              // e.g. 96
}

