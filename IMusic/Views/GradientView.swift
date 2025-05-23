import UIKit

class GradientView: UIView {
    private var gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    private func setupGradient() {
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientLayer.locations = [0.5, 1.0]
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setGradient(colors: [CGColor], locations: [NSNumber]? = nil) {
        gradientLayer.colors = colors
        if let locations = locations {
            gradientLayer.locations = locations
        }
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
