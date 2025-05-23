import UIKit
import AVFoundation

class NowPlayingViewController: UIViewController {
    
    // MARK: - Properties
    var musicLibraryService: MusicLibraryService!
    var musicPlayerService: MusicPlayerService!
    
    private var updateTimer: Timer?
    private var interactiveDismissController: InteractiveDismissController?
    
    // UI Components
    private lazy var artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.image = UIImage.iconDefaultArtwork
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .appText
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .appSubtext
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var albumLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .appSubtext
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var timeSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        return slider
    }()
    
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .appSubtext
        label.text = "00:00"
        return label
    }()
    
    private lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .appSubtext
        label.text = "00:00"
        label.textAlignment = .right
        return label
    }()
    
    private lazy var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.playIcon, for: .normal)
        button.tintColor = .appPrimary
        button.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.skipBackIcon, for: .normal)
        button.tintColor = .appPrimary
        button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.skipForwardIcon, for: .normal)
        button.tintColor = .appPrimary
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var shuffleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.shuffleIcon, for: .normal)
        button.tintColor = .appSubtext
        button.addTarget(self, action: #selector(shuffleButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var repeatButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.repeatIcon, for: .normal)
        button.tintColor = .appSubtext
        button.addTarget(self, action: #selector(repeatButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var volumeSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.7
        slider.addTarget(self, action: #selector(volumeSliderChanged(_:)), for: .valueChanged)
        return slider
    }()
    
    private lazy var volumeMinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "speaker.fill")
        imageView.tintColor = .appSubtext
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var volumeMaxImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "speaker.wave.3.fill")
        imageView.tintColor = .appSubtext
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .appText
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var playlistButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.playlistIcon, for: .normal)
        button.tintColor = .appText
        button.addTarget(self, action: #selector(playlistButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
        setupCustomTransition()
        
        // Register for track changed notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackChanged),
            name: MusicPlayerService.trackChangedNotification,
            object: nil
        )
    }
    
    private func setupCustomTransition() {
        // Setup interactive dismiss controller with custom configuration
        interactiveDismissController = addInteractiveDismiss(
            progressThreshold: 0.3,
            velocityThreshold: 1000,
            allowTopEdgePan: true,
            allowLeftEdgePan: true
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startUpdateTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopUpdateTimer()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        // Add subviews
        view.addSubview(closeButton)
        view.addSubview(playlistButton)
        view.addSubview(artworkImageView)
        view.addSubview(titleLabel)
        view.addSubview(artistLabel)
        view.addSubview(albumLabel)
        view.addSubview(timeSlider)
        view.addSubview(currentTimeLabel)
        view.addSubview(totalTimeLabel)
        view.addSubview(previousButton)
        view.addSubview(playPauseButton)
        view.addSubview(nextButton)
        view.addSubview(shuffleButton)
        view.addSubview(repeatButton)
        view.addSubview(volumeSlider)
        view.addSubview(volumeMinImageView)
        view.addSubview(volumeMaxImageView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            playlistButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            playlistButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playlistButton.widthAnchor.constraint(equalToConstant: 44),
            playlistButton.heightAnchor.constraint(equalToConstant: 44),
            
            artworkImageView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            artworkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: artworkImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            artistLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            artistLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            albumLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 4),
            albumLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            albumLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            currentTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentTimeLabel.bottomAnchor.constraint(equalTo: timeSlider.topAnchor, constant: -4),
            
            totalTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            totalTimeLabel.bottomAnchor.constraint(equalTo: timeSlider.topAnchor, constant: -4),
            
            timeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timeSlider.topAnchor.constraint(equalTo: albumLabel.bottomAnchor, constant: 24),
            
            shuffleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            shuffleButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            shuffleButton.widthAnchor.constraint(equalToConstant: 44),
            shuffleButton.heightAnchor.constraint(equalToConstant: 44),
            
            previousButton.leadingAnchor.constraint(equalTo: shuffleButton.trailingAnchor, constant: 16),
            previousButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 44),
            previousButton.heightAnchor.constraint(equalToConstant: 44),
            
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.topAnchor.constraint(equalTo: timeSlider.bottomAnchor, constant: 24),
            playPauseButton.widthAnchor.constraint(equalToConstant: 60),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),
            
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 16),
            nextButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            repeatButton.leadingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: 16),
            repeatButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            repeatButton.widthAnchor.constraint(equalToConstant: 44),
            repeatButton.heightAnchor.constraint(equalToConstant: 44),
            
            volumeMinImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            volumeMinImageView.centerYAnchor.constraint(equalTo: volumeSlider.centerYAnchor),
            volumeMinImageView.widthAnchor.constraint(equalToConstant: 20),
            volumeMinImageView.heightAnchor.constraint(equalToConstant: 20),
            
            volumeSlider.leadingAnchor.constraint(equalTo: volumeMinImageView.trailingAnchor, constant: 8),
            volumeSlider.trailingAnchor.constraint(equalTo: volumeMaxImageView.leadingAnchor, constant: -8),
            volumeSlider.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 32),
            
            volumeMaxImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            volumeMaxImageView.centerYAnchor.constraint(equalTo: volumeSlider.centerYAnchor),
            volumeMaxImageView.widthAnchor.constraint(equalToConstant: 20),
            volumeMaxImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func updateUI() {
        guard let currentItem = musicPlayerService.currentItem else {
            dismiss(animated: true)
            return
        }
        
        // Update labels
        titleLabel.text = currentItem.title
        artistLabel.text = currentItem.artist ?? "Unknown Artist"
        albumLabel.text = currentItem.album ?? "Unknown Album"
        
        // Update artwork
        if let artworkData = currentItem.artworkData, let image = UIImage(data: artworkData) {
            artworkImageView.image = image
        } else {
            artworkImageView.image = UIImage.iconDefaultArtwork
        }
        
        // Update time labels
        updateTimeLabels()
        
        // Update play/pause button
        updatePlayPauseButton()
        
        // Update shuffle and repeat buttons
        updateShuffleButton()
        updateRepeatButton()
        
        // Update volume slider
        volumeSlider.value = musicPlayerService.volume
    }
    
    private func updateTimeLabels() {
        let currentTime = musicPlayerService.currentTime
        let duration = musicPlayerService.duration
        
        currentTimeLabel.text = currentTime.formatAsPlaybackTime()
        totalTimeLabel.text = duration.formatAsPlaybackTime()
        
        if !timeSlider.isTracking {
            timeSlider.value = Float(currentTime / max(duration, 1))
        }
    }
    
    private func updatePlayPauseButton() {
        let isPlaying = musicPlayerService.playbackState == .playing
        let image = isPlaying ? UIImage.pauseIcon : UIImage.playIcon
        playPauseButton.setImage(image, for: .normal)
    }
    
    private func updateShuffleButton() {
        shuffleButton.tintColor = musicPlayerService.isShuffleEnabled ? .appPrimary : .appSubtext
    }
    
    private func updateRepeatButton() {
        switch musicPlayerService.repeatMode {
        case .none:
            repeatButton.setImage(UIImage.repeatIcon, for: .normal)
            repeatButton.tintColor = .appSubtext
        case .all:
            repeatButton.setImage(UIImage.repeatIcon, for: .normal)
            repeatButton.tintColor = .appPrimary
        case .one:
            repeatButton.setImage(UIImage.repeatOneIcon, for: .normal)
            repeatButton.tintColor = .appPrimary
        }
    }
    
    private func startUpdateTimer() {
        stopUpdateTimer()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateTimeLabels()
            self?.updatePlayPauseButton()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func playlistButtonTapped() {
        // Show queue/playlist
        let queueVC = QueueViewController()
        queueVC.musicPlayerService = musicPlayerService
        queueVC.musicLibraryService = musicLibraryService
        let navController = UINavigationController(rootViewController: queueVC)
        present(navController, animated: true)
    }
    
    @objc private func playPauseButtonTapped() {
        musicPlayerService.togglePlayPause()
        updatePlayPauseButton()
    }
    
    @objc private func previousButtonTapped() {
        musicPlayerService.playPrevious()
        updateUI()
    }
    
    @objc private func nextButtonTapped() {
        musicPlayerService.playNext()
        updateUI()
    }
    
    @objc private func shuffleButtonTapped() {
        musicPlayerService.toggleShuffle()
        updateShuffleButton()
    }
    
    @objc private func repeatButtonTapped() {
        musicPlayerService.toggleRepeatMode()
        updateRepeatButton()
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        // Update current time label while dragging
        let seekTime = Double(slider.value) * musicPlayerService.duration
        currentTimeLabel.text = seekTime.formatAsPlaybackTime()
    }
    
    @objc private func sliderTouchUp(_ slider: UISlider) {
        // Seek to position when slider is released
        musicPlayerService.seekToPercent(slider.value)
    }
    
    @objc private func volumeSliderChanged(_ slider: UISlider) {
        musicPlayerService.setVolume(slider.value)
    }
    
    // Handle track changed notification
    @objc private func trackChanged() {
        print("Track changed notification received in NowPlayingViewController")
        updateUI()
    }
    
    // MARK: - Interactive Transition
    


}


