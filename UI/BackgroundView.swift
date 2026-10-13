import UIKit

/// BackgroundView tạo hiệu ứng nền OLED Ambient Aurora sang trọng chuẩn điện ảnh VIP
final class BackgroundView: UIView {
    private let primaryGradient = CAGradientLayer()
    private let ambientGlowLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayers() {
        // Lớp nền chính: Dark OLED chuyển màu từ sắc đen ánh xanh/tím huyền bí
        primaryGradient.colors = [
            UIColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1.0).cgColor,
            UIColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1.0).cgColor,
            UIColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1.0).cgColor
        ]
        primaryGradient.locations = [0.0, 0.5, 1.0]
        primaryGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        primaryGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(primaryGradient)

        // Lớp ánh sáng rạp chiếu phim (Ambient Aurora Glow) tạo chiều sâu 3D
        ambientGlowLayer.type = .radial
        ambientGlowLayer.colors = [
            UIColor(red: 0.88, green: 0.04, blue: 0.12, alpha: 0.15).cgColor, // Crimson glow
            UIColor(red: 0.40, green: 0.05, blue: 0.35, alpha: 0.08).cgColor, // Deep purple aura
            UIColor.clear.cgColor
        ]
        ambientGlowLayer.startPoint = CGPoint(x: 0.85, y: 0.10) // Tỏa ra từ góc trên bên phải
        ambientGlowLayer.endPoint = CGPoint(x: 0.0, y: 0.95)
        layer.addSublayer(ambientGlowLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        primaryGradient.frame = bounds
        ambientGlowLayer.frame = bounds
        CATransaction.commit()
    }

    func setStyle(_ style: BackgroundStyle) {
        primaryGradient.colors = style.colors
        primaryGradient.locations = style.locations
    }
}

enum BackgroundStyle {
    case `default`
    case dark
    case accent

    var colors: [CGColor] {
        switch self {
        case .default:
            return [
                UIColor(red: 0.05, green: 0.04, blue: 0.09, alpha: 1.0).cgColor,
                UIColor(red: 0.03, green: 0.02, blue: 0.05, alpha: 1.0).cgColor,
                UIColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1.0).cgColor
            ]
        case .dark:
            return [
                UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0).cgColor,
                UIColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1.0).cgColor
            ]
        case .accent:
            return [
                UIColor(red: 0.10, green: 0.02, blue: 0.05, alpha: 1.0).cgColor,
                UIColor(red: 0.04, green: 0.02, blue: 0.04, alpha: 1.0).cgColor,
                UIColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1.0).cgColor
            ]
        }
    }

    var locations: [NSNumber] {
        switch self {
        case .default, .accent:
            return [0.0, 0.45, 1.0]
        case .dark:
            return [0.0, 1.0]
        }
    }
}
