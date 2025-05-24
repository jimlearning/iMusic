import UIKit

protocol MiniPlayerViewDelegate: AnyObject {
    func miniPlayerViewDidTapPlayPause(_ miniPlayerView: MiniPlayerView)
    func miniPlayerViewDidTapView(_ miniPlayerView: MiniPlayerView)
}

class MiniPlayerView: UIView {
    
    // MARK: - Properties
    weak var delegate: MiniPlayerViewDelegate?
    
    // MARK: - UI Components
    
    private let artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.image = UIImage.iconDefaultArtwork
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .appText
        return label
    }()
    
    private let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .appSubtext
        return label
    }()
    
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.playIcon, for: .normal)
        button.tintColor = .appPrimary
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
        backgroundColor = .systemBackground
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 4
        
        // Add top separator
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .systemGray5
        
        // Add subviews
        addSubview(separator)
        addSubview(artworkImageView)
        addSubview(titleLabel)
        addSubview(artistLabel)
        addSubview(playPauseButton)
        
        // Add constraints
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            
            artworkImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            artworkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            artworkImageView.widthAnchor.constraint(equalToConstant: 40),
            artworkImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: playPauseButton.leadingAnchor, constant: -12),
            
            artistLabel.leadingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: 12),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: playPauseButton.leadingAnchor, constant: -12),
            
            playPauseButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            playPauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add tap gestures
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Configuration
    
    func configure(with item: MusicItem, playbackState: PlaybackState) {
        titleLabel.text = item.title
        artistLabel.text = item.artist ?? "未知艺术家"
        
        if let artworkData = item.artworkData, let image = UIImage(data: artworkData) {
            artworkImageView.image = image
        } else {
            artworkImageView.image = UIImage.iconDefaultArtwork
        }
        
        let isPlaying = playbackState == .playing
        let image = isPlaying ? UIImage.pauseIcon : UIImage.playIcon
        playPauseButton.setImage(image, for: .normal)
    }
    
    // MARK: - Actions
    
    @objc private func playPauseButtonTapped() {
        delegate?.miniPlayerViewDidTapPlayPause(self)
    }
    
    @objc private func viewTapped() {
        delegate?.miniPlayerViewDidTapView(self)
    }
}
