import Foundation
import UIKit

// MARK: - UIColor Extensions
extension UIColor {
    static let appPrimary = UIColor(named: "PrimaryColor") ?? UIColor.systemBlue
    static let appSecondary = UIColor(named: "SecondaryColor") ?? UIColor.systemGreen
    static let appBackground = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
    static let appText = UIColor(named: "TextColor") ?? UIColor.label
    static let appSubtext = UIColor(named: "SubtextColor") ?? UIColor.secondaryLabel
}

// MARK: - UIImage Extensions
extension UIImage {
//    static let defaultArtwork = UIImage(named: "DefaultArtwork") ?? UIImage(systemName: "music.note")!
    static let playIcon = UIImage(systemName: "play.fill")!
    static let pauseIcon = UIImage(systemName: "pause.fill")!
    static let skipForwardIcon = UIImage(systemName: "forward.fill")!
    static let skipBackIcon = UIImage(systemName: "backward.fill")!
    static let shuffleIcon = UIImage(systemName: "shuffle")!
    static let repeatIcon = UIImage(systemName: "repeat")!
    static let repeatOneIcon = UIImage(systemName: "repeat.1")!
    static let volumeIcon = UIImage(systemName: "speaker.wave.2.fill")!
    static let playlistIcon = UIImage(systemName: "music.note.list")!
    static let plusIcon = UIImage(systemName: "plus")!
    static let minusIcon = UIImage(systemName: "minus")!
    static let searchIcon = UIImage(systemName: "magnifyingglass")!
    static let settingsIcon = UIImage(systemName: "gear")!
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    func formatAsPlaybackTime() -> String {
        if isNaN || isInfinite {
            return "00:00"
        }
        
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - UIViewController Extensions
extension UIViewController {
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    func showConfirmationAlert(title: String, message: String, confirmAction: @escaping () -> Void, cancelAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            cancelAction?()
        })
        
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            confirmAction()
        })
        
        present(alert, animated: true)
    }
    
    func showTextInputAlert(title: String, message: String, placeholder: String, initialText: String? = nil, confirmAction: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = initialText
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                confirmAction(text)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableView Extensions
extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .appSubtext
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }
    
    func restoreBackgroundView() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}

// MARK: - Date Extensions
extension Date {
    func formatAsDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - UIView Extensions
extension UIView {
    func addShadow(opacity: Float = 0.2, radius: CGFloat = 3, offset: CGSize = CGSize(width: 0, height: 2)) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    func roundCorners(radius: CGFloat = 8) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
    
    func addBorder(width: CGFloat = 1, color: UIColor = .lightGray) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
}
