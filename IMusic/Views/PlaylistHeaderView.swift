import UIKit

class PlaylistHeaderView: UIView {
    
    // MARK: - UI Components
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage(systemName: "music.note.list")
        imageView.tintColor = .appPrimary
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .appText
        label.numberOfLines = 0
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .appSubtext
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .appSubtext
        return label
    }()
    
    let playAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Play All", for: .normal)
        button.setImage(UIImage.playIcon, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .appPrimary
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        return button
    }()
    
    let shuffleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Shuffle", for: .normal)
        button.setImage(UIImage.shuffleIcon, for: .normal)
        button.tintColor = .appPrimary
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
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
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .appBackground
        
        // Add subviews
        addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(infoLabel)
        addSubview(dateLabel)
        addSubview(playAllButton)
        addSubview(shuffleButton)
        
        // Add constraints
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 100),
            iconImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            infoLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            dateLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            dateLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            playAllButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            playAllButton.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            playAllButton.heightAnchor.constraint(equalToConstant: 44),
            
            shuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 12),
            shuffleButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            shuffleButton.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            shuffleButton.heightAnchor.constraint(equalToConstant: 44),
            shuffleButton.widthAnchor.constraint(equalTo: playAllButton.widthAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with playlist: PlaylistItem) {
        nameLabel.text = playlist.name
        
        let count = playlist.count
        infoLabel.text = "\(count) \(count == 1 ? "song" : "songs"), \(playlist.formattedTotalDuration)"
        
        dateLabel.text = "Created on \(playlist.dateCreated.formatAsDateString())"
        
        // Disable buttons if playlist is empty
        let isEmpty = playlist.musicItems.isEmpty
        playAllButton.isEnabled = !isEmpty
        shuffleButton.isEnabled = !isEmpty
        playAllButton.alpha = isEmpty ? 0.5 : 1.0
        shuffleButton.alpha = isEmpty ? 0.5 : 1.0
    }
}
