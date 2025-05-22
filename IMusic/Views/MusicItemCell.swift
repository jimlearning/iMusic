import UIKit

class MusicItemCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.image = UIImage.defaultArtwork
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .appText
        return label
    }()
    
    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .appSubtext
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
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
        artworkImageView.image = UIImage.defaultArtwork
        titleLabel.text = nil
        artistLabel.text = nil
        durationLabel.text = nil
        accessoryType = .none
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.addSubview(artworkImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            artworkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            artworkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            artworkImageView.widthAnchor.constraint(equalToConstant: 50),
            artworkImageView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            
            artistLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            artistLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with item: MusicItem) {
        titleLabel.text = item.title
        artistLabel.text = item.artist ?? "Unknown Artist"
        durationLabel.text = item.formattedDuration
        
        if let artworkData = item.artworkData, let image = UIImage(data: artworkData) {
            artworkImageView.image = image
        } else {
            artworkImageView.image = UIImage.defaultArtwork
        }
    }
}
