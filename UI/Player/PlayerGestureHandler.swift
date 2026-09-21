import UIKit
import MediaPlayer

public protocol PlayerGestureHandlerDelegate: AnyObject {
    func didDoubleTapSeek(isForward: Bool)
    func didChangeBrightness(level: CGFloat)
    func didChangeVolume(delta: Float)
    func didEndGesture()
}

/// Control handler xử lý các cử chỉ vuốt, chạm kép trên Player Screen với độ nhạy mượt mà
public final class PlayerGestureHandler: NSObject, UIGestureRecognizerDelegate {
    private weak var containerView: UIView?
    public weak var delegate: PlayerGestureHandlerDelegate?

    private var initialTouchLocation: CGPoint = .zero

    public init(containerView: UIView) {
        self.containerView = containerView
        super.init()
        setupGestureRecognizers()
    }

    private func setupGestureRecognizers() {
        guard let view = containerView else { return }

        // Double Tap Gesture Seek (+10s / -10s)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)

        // Pan Gesture (Brightness & Volume)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = containerView else { return }
        let touchPoint = gesture.location(in: view)
        let isForward = touchPoint.x > (view.bounds.width / 2.0)
        delegate?.didDoubleTapSeek(isForward: isForward)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = containerView else { return }
        let location = gesture.location(in: view)
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            initialTouchLocation = location
        case .changed:
            let deltaY = Float(-translation.y / view.bounds.height)
            gesture.setTranslation(.zero, in: view)

            if initialTouchLocation.x < (view.bounds.width / 2.0) {
                // Nửa màn hình bên trái -> Điều chỉnh Độ Sáng (Brightness)
                let current = UIScreen.main.brightness
                let newLevel = max(0.0, min(1.0, current + CGFloat(deltaY * 1.5)))
                UIScreen.main.brightness = newLevel
                delegate?.didChangeBrightness(level: newLevel)
            } else {
                // Nửa màn hình bên phải -> Điều chỉnh Âm Lượng (Volume)
                delegate?.didChangeVolume(delta: deltaY * 1.5)
            }
        case .ended, .cancelled:
            delegate?.didEndGesture()
        default:
            break
        }
    }
}
