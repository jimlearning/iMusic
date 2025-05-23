import UIKit

class PlaylistCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage.defaultAlbumArtwork
        imageView.tintColor = .appPrimary
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .appText
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .appSubtext
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .appSubtext
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        countLabel.text = nil
        dateLabel.text = nil
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),
            
            countLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),
            
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            dateLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with playlist: PlaylistItem) {
        nameLabel.text = playlist.name
        
        let count = playlist.count
        countLabel.text = "\(count) \(count == 1 ? "song" : "songs"), \(playlist.formattedTotalDuration)"
        
        dateLabel.text = playlist.dateCreated.formatAsDateString()
        
        // Get first music item in playlist for artwork
        if let firstItem = playlist.musicItems.first, let artworkData = firstItem.artworkData, let image = UIImage(data: artworkData) {
            iconImageView.image = image
            iconImageView.backgroundColor = .clear
        } else {
            setupDefaultImage(with: playlist.name)
        }
    }
    
    private func setupDefaultImage(with playlistName: String) {
        if !playlistName.isEmpty {
            iconImageView.backgroundColor = colorBasedOnString(playlistName)
        } else {
            iconImageView.backgroundColor = randomPredefinedColor()
        }
        
        iconImageView.image = UIImage.defaultAlbumArtwork
        iconImageView.tintColor = .white
    }
}
