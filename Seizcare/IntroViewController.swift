import UIKit

class IntroViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        
        
        // 1. Logo Styling
        if let logo = view.viewWithTag(101) as? UIImageView {
             // Logo size is handled in Storyboard constraints (280x280)
             // Ensure content mode if needed, but it looked fine.
        }
        
        // 2. Title Styling
        if let titleLabel = view.viewWithTag(102) as? UILabel {
            titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            
        }
        
        // 3. Subtitle Styling
        if let subtitleLabel = view.viewWithTag(103) as? UILabel {
            subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.numberOfLines = 3
            subtitleLabel.textAlignment = .center
            
            // Paragraph style for line spacing
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.alignment = .center
            let attrString = NSMutableAttributedString(string: subtitleLabel.text ?? "")
            attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
            subtitleLabel.attributedText = attrString
        }
        
        // 4. Spacing Configuration
        if let textStack = view.viewWithTag(104) as? UIStackView {
           
            
            if textStack.arrangedSubviews.count >= 2 {
                let logoView = textStack.arrangedSubviews[0]
                textStack.setCustomSpacing(12, after: logoView)
            }
            
          
            if textStack.arrangedSubviews.count >= 3 {
                let titleView = textStack.arrangedSubviews[1]
                textStack.setCustomSpacing(20, after: titleView)
            }
        }
        
        if let mainContentStack = view.viewWithTag(107) as? UIStackView {
           
            
            
            if mainContentStack.arrangedSubviews.count >= 1 {
                let textStackView = mainContentStack.arrangedSubviews[0]
                mainContentStack.setCustomSpacing(24, after: textStackView)
            }
            
           
            if mainContentStack.arrangedSubviews.count >= 2 {
                let feature1 = mainContentStack.arrangedSubviews[1]
                mainContentStack.setCustomSpacing(28, after: feature1)
            }
        }
        
        
        styleFeatureStack(tag: 105)
        styleFeatureStack(tag: 106)
    }
    
    private func styleFeatureStack(tag: Int) {
        guard let stack = view.viewWithTag(tag) as? UIStackView else { return }
        
        // Spacing between Icon and TextStack: 12pt
        stack.spacing = 12
        stack.alignment = .top // Ensure top alignment
        
        // The text stack is the second arranged subview usually
        if stack.arrangedSubviews.count > 1, let textStack = stack.arrangedSubviews[1] as? UIStackView {
            textStack.spacing = 8 // Feature Title -> Description
            
            // Title Label (First item in textStack)
            if let titleLabel = textStack.arrangedSubviews.first as? UILabel {
                titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
            }
            
            // Desc Label (Second item)
            if textStack.arrangedSubviews.count > 1, let descLabel = textStack.arrangedSubviews[1] as? UILabel {
                descLabel.font = .systemFont(ofSize: 15, weight: .regular)
                descLabel.textColor = .secondaryLabel
            }
        }
    }
}
