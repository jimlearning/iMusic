import UIKit

class PlaylistCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Components
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 15
        button.isHidden = true
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        artistLabel.text = nil
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        
        // Add UI components to content view
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(playButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Image view
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            // Play button
            playButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Artist label
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artistLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
        
        // Add hover effect
        let hoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(handleHover(_:)))
        contentView.addGestureRecognizer(hoverGesture)
    }
    
    // MARK: - Configuration
    
    func configure(with playlist: PlaylistItem) {
        titleLabel.text = playlist.name
        
        // Get first music item in playlist for artist name and artwork
        if let firstItem = playlist.musicItems.first {
            artistLabel.text = firstItem.artist ?? "Unknown Artist"
            
            if let artworkData = firstItem.artworkData, let image = UIImage(data: artworkData) {
                imageView.image = image
            } else {
                setupDefaultImage()
            }
        } else {
            artistLabel.text = "Various Artists"
            setupDefaultImage()
        }
    }
    
    private func setupDefaultImage() {
        imageView.backgroundColor = randomColor()
        imageView.image = UIImage(systemName: "music.note")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        // imageView.contentMode = .center
    }
    
    private func randomColor() -> UIColor {
        let predefinedColors: [UIColor] = [
            UIColor(red: 0.906, green: 0.298, blue: 0.235, alpha: 1.0),  // 红色
            UIColor(red: 0.204, green: 0.596, blue: 0.859, alpha: 1.0),  // 蓝色
            UIColor(red: 0.180, green: 0.800, blue: 0.443, alpha: 1.0),  // 绿色
            UIColor(red: 0.945, green: 0.769, blue: 0.059, alpha: 1.0),  // 黄色
            UIColor(red: 0.608, green: 0.349, blue: 0.714, alpha: 1.0),  // 紫色
            UIColor(red: 1.000, green: 0.596, blue: 0.000, alpha: 1.0),  // 橙色
            UIColor(red: 0.161, green: 0.502, blue: 0.725, alpha: 1.0),  // 深蓝色
            UIColor(red: 0.827, green: 0.329, blue: 0.510, alpha: 1.0),  // 粉色
            UIColor(red: 0.957, green: 0.263, blue: 0.475, alpha: 1.0),  // 鲜粉色
            UIColor(red: 0.153, green: 0.682, blue: 0.376, alpha: 1.0)   // 翠绿色
        ]
        
        // Generate a unique index from 0-9 based on self's hash value
        let hashValue = abs(ObjectIdentifier(self).hashValue)
        let colorIndex = hashValue % predefinedColors.count
        
        return predefinedColors[colorIndex]
    }
    
    // MARK: - Actions
    
    @objc private func handleHover(_ gesture: UIHoverGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            playButton.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.imageView.alpha = 0.7
            }
        case .ended, .cancelled:
            playButton.isHidden = true
            UIView.animate(withDuration: 0.2) {
                self.imageView.alpha = 1.0
            }
        default:
            break
        }
    }
}
