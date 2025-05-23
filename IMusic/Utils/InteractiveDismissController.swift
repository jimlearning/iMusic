import UIKit

/// A controller that adds interactive dismissal gestures to a view controller
class InteractiveDismissController: NSObject {
    
    // MARK: - Properties
    
    private weak var viewController: UIViewController?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var edgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var interactiveTransition: UIPercentDrivenInteractiveTransition?
    private var initialTouchPoint: CGPoint = .zero
    private var isDismissing = false
    
    // Configuration options
    private let dismissProgressThreshold: CGFloat
    private let dismissVelocityThreshold: CGFloat
    private let allowTopEdgePan: Bool
    private let allowLeftEdgePan: Bool
    
    // MARK: - Initialization
    
    /// Creates a new interactive dismiss controller
    /// - Parameters:
    ///   - viewController: The view controller to add gestures to
    ///   - progressThreshold: The progress threshold to complete dismissal (0.0-1.0)
    ///   - velocityThreshold: The velocity threshold to complete dismissal (points/second)
    ///   - allowTopEdgePan: Whether to allow pan from top half of the screen
    ///   - allowLeftEdgePan: Whether to allow pan from left edge of the screen
    init(
        viewController: UIViewController,
        progressThreshold: CGFloat = 0.3,
        velocityThreshold: CGFloat = 1000,
        allowTopEdgePan: Bool = true,
        allowLeftEdgePan: Bool = true
    ) {
        self.viewController = viewController
        self.dismissProgressThreshold = progressThreshold
        self.dismissVelocityThreshold = velocityThreshold
        self.allowTopEdgePan = allowTopEdgePan
        self.allowLeftEdgePan = allowLeftEdgePan
        
        super.init()
        
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupGestures() {
        guard let viewController = viewController else { return }
        
        // Setup for custom transition
        viewController.modalPresentationStyle = .fullScreen
        viewController.transitioningDelegate = self
        
        // Add vertical pan gesture if enabled
        if allowTopEdgePan {
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            panGestureRecognizer?.delegate = self
            viewController.view.addGestureRecognizer(panGestureRecognizer!)
        }
        
        // Add edge pan gesture if enabled
        if allowLeftEdgePan {
            edgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePanGesture(_:)))
            edgePanGestureRecognizer?.edges = .left
            edgePanGestureRecognizer?.delegate = self
            viewController.view.addGestureRecognizer(edgePanGestureRecognizer!)
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = viewController?.view else { return }
        
        let translation = gesture.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let progress = min(max(verticalMovement, 0.0), 1.0)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: view)
            // Only allow interaction when gesture begins in the top half of the screen
            if initialTouchPoint.y < view.bounds.height / 2 && !isDismissing {
                startDismiss()
            }
        case .changed:
            if interactiveTransition != nil && isDismissing {
                interactiveTransition?.update(progress)
            }
        case .ended, .cancelled:
            if interactiveTransition != nil && isDismissing {
                // Complete dismissal if progress exceeds threshold OR velocity is high enough
                if progress > dismissProgressThreshold || velocity.y > dismissVelocityThreshold {
                    finishDismiss()
                } else {
                    cancelDismiss()
                }
            }
        default:
            break
        }
    }
    
    @objc private func handleEdgePanGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard let view = viewController?.view else { return }
        
        let translation = gesture.translation(in: view)
        let horizontalMovement = translation.x / view.bounds.width
        let progress = min(max(horizontalMovement, 0.0), 1.0)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            if !isDismissing {
                startDismiss()
            }
        case .changed:
            if interactiveTransition != nil && isDismissing {
                interactiveTransition?.update(progress)
            }
        case .ended, .cancelled:
            if interactiveTransition != nil && isDismissing {
                // Complete dismissal if progress exceeds threshold OR velocity is high enough
                if progress > dismissProgressThreshold || velocity.x > dismissVelocityThreshold {
                    finishDismiss()
                } else {
                    cancelDismiss()
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Dismiss Helpers
    
    private func startDismiss() {
        isDismissing = true
        interactiveTransition = UIPercentDrivenInteractiveTransition()
        interactiveTransition?.completionCurve = .easeOut
        interactiveTransition?.completionSpeed = 0.6
        viewController?.dismiss(animated: true)
    }
    
    private func finishDismiss() {
        interactiveTransition?.finish()
        interactiveTransition = nil
        isDismissing = false
    }
    
    private func cancelDismiss() {
        interactiveTransition?.cancel()
        interactiveTransition = nil
        isDismissing = false
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension InteractiveDismissController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimationController()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
}

// MARK: - UIGestureRecognizerDelegate

extension InteractiveDismissController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Edge pan gesture always begins when activated
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return true
        }
        
        // For regular pan gesture, check direction
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
           let view = viewController?.view {
            let velocity = panGesture.velocity(in: view)
            
            // Only allow vertical gestures that are primarily downward
            let isVertical = abs(velocity.y) > abs(velocity.x)
            let isDownward = velocity.y > 0
            
            return isVertical && isDownward
        }
        
        return true
    }
}

// MARK: - Custom Animation Controller

class DismissAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        let screenBounds = UIScreen.main.bounds
        let finalFrame = CGRect(x: 0, y: screenBounds.height, width: screenBounds.width, height: screenBounds.height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
            fromVC.view.frame = finalFrame
        }, completion: { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    /// Adds interactive dismissal gestures to this view controller
    /// - Parameters:
    ///   - progressThreshold: The progress threshold to complete dismissal (0.0-1.0)
    ///   - velocityThreshold: The velocity threshold to complete dismissal (points/second)
    ///   - allowTopEdgePan: Whether to allow pan from top half of the screen
    ///   - allowLeftEdgePan: Whether to allow pan from left edge of the screen
    /// - Returns: The created interactive dismiss controller
    @discardableResult
    func addInteractiveDismiss(
        progressThreshold: CGFloat = 0.3,
        velocityThreshold: CGFloat = 1000,
        allowTopEdgePan: Bool = true,
        allowLeftEdgePan: Bool = true
    ) -> InteractiveDismissController {
        return InteractiveDismissController(
            viewController: self,
            progressThreshold: progressThreshold,
            velocityThreshold: velocityThreshold,
            allowTopEdgePan: allowTopEdgePan,
            allowLeftEdgePan: allowLeftEdgePan
        )
    }
}
