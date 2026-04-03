//
//  UIImageView+Remote.swift
//  Seizcare
//

import UIKit
import ObjectiveC

// Shared image cache
let sharedImageCache = NSCache<NSString, UIImage>()

// Key for the associated load token
private var loadTokenKey = "UIImageView.LoadToken"

extension UIImageView {

    // MARK: - Load Token (cancels in-flight async fetches)

    private var loadToken: Int {
        get { (objc_getAssociatedObject(self, &loadTokenKey) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &loadTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - Public API

    /// Loads a remote image asynchronously.
    /// Any previously in-flight load for THIS image view is automatically cancelled.
    /// - Parameters:
    ///   - urlString: Remote URL. Nil or empty shows a placeholder.
    ///   - showPlaceholder: Set false to keep the current image while the new one loads.
    func load(urlString: String?, showPlaceholder: Bool = true) {
        applyCircle()
        contentMode = .scaleAspectFill

        if showPlaceholder {
            image = UIImage(systemName: "person.circle.fill")?
                .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        }

        guard let urlString, !urlString.isEmpty, let url = URL(string: urlString) else { return }

        // Serve from cache instantly (no network needed)
        if let cached = sharedImageCache.object(forKey: urlString as NSString) {
            self.image = cached
            return
        }

        // Mint a new token — any previous async fetch that completes will see a mismatch and discard its result
        let token = loadToken + 1
        loadToken = token

        Task { @MainActor in
            do {
                let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
                let (data, _) = try await URLSession.shared.data(for: req)
                guard let img = UIImage(data: data), self.loadToken == token else { return }
                sharedImageCache.setObject(img, forKey: urlString as NSString)
                UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.image = img
                })
            } catch {
                print("⚠️ [UIImageView.load] \(error.localizedDescription)")
            }
        }
    }

    /// Sets an image directly and **cancels any pending async load** for this view.
    /// Use this for optimistic/immediate updates so a later network response cannot overwrite them.
    func setImmediately(_ image: UIImage) {
        loadToken += 1          // invalidates any in-flight load
        applyCircle()
        contentMode = .scaleAspectFill
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.image = image
        })
        print("✅ Image selected and shown immediately")
    }

    /// Removes the cached entry so the next `load` fetches a fresh copy.
    static func bustCache(for urlString: String) {
        sharedImageCache.removeObject(forKey: urlString as NSString)
    }

    /// Clips the image view to a perfect circle.
    func applyCircle() {
        clipsToBounds = true
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}
