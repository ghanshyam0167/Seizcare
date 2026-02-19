import UIKit

class IntroViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // Tag 101: Logo ImageView
        // Tag 102: Title Label
        // Tag 103: Subtitle Label
        // Tag 104: Text Group Stack (Logo+Title+Subtitle)
        // Tag 107: Main Content Stack (contains TextGroup, Feature1, Feature2)
        
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
            // Max width 85% handled by parent stack padding or explicit constraint?
            // Let's rely on stack padding first, or add constraint if needed.
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
            // Stack contains [Logo, Title, Subtitle]
            // Default spacing might be set in Storyboard (e.g. 20)
            
            // Logo (index 0) -> Title (index 1): 12pt
            if textStack.arrangedSubviews.count >= 2 {
                let logoView = textStack.arrangedSubviews[0]
                textStack.setCustomSpacing(12, after: logoView)
            }
            
            // Title (index 1) -> Subtitle (index 2): 20pt
            if textStack.arrangedSubviews.count >= 3 {
                let titleView = textStack.arrangedSubviews[1]
                textStack.setCustomSpacing(20, after: titleView)
            }
        }
        
        if let mainContentStack = view.viewWithTag(107) as? UIStackView {
            // Stack contains [TextStack, Feature1, Feature2]
            
            // TextStack -> Feature 1: 24pt
            if mainContentStack.arrangedSubviews.count >= 1 {
                let textStackView = mainContentStack.arrangedSubviews[0]
                mainContentStack.setCustomSpacing(24, after: textStackView)
            }
            
            // Feature 1 -> Feature 2: 28pt
            if mainContentStack.arrangedSubviews.count >= 2 {
                let feature1 = mainContentStack.arrangedSubviews[1]
                mainContentStack.setCustomSpacing(28, after: feature1)
            }
        }
        
        // 5. Feature Styling (Recursively find feature labels if tags obscure)
        // We know Feature 1 Stack is Tag 105, Feature 2 is Tag 106.
        // Inside them, we have icon and logic.
        // Let's refine based on the known structure.
        
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
