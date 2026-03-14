//
//  ProfilePhotoManager.swift
//  Seizcare
//
//  Saves and loads the user's profile photo from the app's documents directory.
//

import UIKit

class ProfilePhotoManager {

    static let shared = ProfilePhotoManager()
    private init() {}

    private var fileName: String {
        // Per-user photo file
        if let user = UserDataModel.shared.getCurrentUser() {
            return "profile_photo_\(user.id.uuidString).jpg"
        }
        return "profile_photo.jpg"
    }

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    /// Save a profile photo to disk.
    func save(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: fileURL)
        }
    }

    /// Load the saved profile photo, or nil if none exists.
    func load() -> UIImage? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
}
