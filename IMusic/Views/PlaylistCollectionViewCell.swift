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
            artistLabel.text = firstItem.artist ?? "未知艺术家"
            
            if let artworkData = firstItem.artworkData, let image = UIImage(data: artworkData) {
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
            } else {
                setupDefaultImage()
                imageView.contentMode = .scaleAspectFit
            }
        } else {
            artistLabel.text = "合辑"
            setupDefaultImage()
        }
    }
    
    private func setupDefaultImage() {
        if let playlistName = titleLabel.text, !playlistName.isEmpty {
            imageView.backgroundColor = colorBasedOnString(playlistName)
        } else {
            imageView.backgroundColor = randomPredefinedColor()
        }
        
        imageView.image = UIImage.iconDefaultAlbum
        imageView.tintColor = .white
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
