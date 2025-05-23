import UIKit

class MusicPreferencesViewController: UIViewController {
    
    // MARK: - Properties
    
    private let musicGenres = ["R&B", "说唱", "流行", "摇滚", "古典", "电子", "爵士", "民谣"]
    private var selectedGenres: [String] = []
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("跳过", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "想要I-MUSic为你带来什么样的音乐"
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("确定", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var genreStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add scroll view and content view
        view.addSubview(skipButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(genreStackView)
        view.addSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -20),
            
            // Content view constraints - same width as scroll view but dynamic height
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Genre stack view constraints
            genreStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            genreStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            genreStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            genreStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 300),
            confirmButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        setupGenreOptions()
    }
    
    private func setupGenreOptions() {
        for genre in musicGenres {
            let containerView = createGenreOptionView(genre: genre)
            genreStackView.addArrangedSubview(containerView)
        }
    }
    
    private func createGenreOptionView(genre: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12
        
        let radioButton = UIButton(type: .custom)
        radioButton.translatesAutoresizingMaskIntoConstraints = false
        radioButton.setImage(UIImage(systemName: "circle"), for: .normal)
        radioButton.setImage(UIImage(systemName: "circle.fill"), for: .selected)
        radioButton.tintColor = .label
        radioButton.tag = musicGenres.firstIndex(of: genre) ?? 0
        radioButton.addTarget(self, action: #selector(genreButtonTapped(_:)), for: .touchUpInside)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = genre
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .label
        
        // Add accent view (red line on the right)
        let accentView = UIView()
        accentView.translatesAutoresizingMaskIntoConstraints = false
        accentView.backgroundColor = .systemRed
        accentView.layer.cornerRadius = 1
        
        containerView.addSubview(radioButton)
        containerView.addSubview(label)
        containerView.addSubview(accentView)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 60),
            
            radioButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            radioButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 24),
            radioButton.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            accentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            accentView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            accentView.widthAnchor.constraint(equalToConstant: 2),
            accentView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Add tap gesture to the entire container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(containerTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.tag = radioButton.tag
        containerView.isUserInteractionEnabled = true
        
        return containerView
    }
    
    // MARK: - Actions
    @objc private func containerTapped(_ gesture: UITapGestureRecognizer) {
        if let containerView = gesture.view {
            let tag = containerView.tag
            if tag < musicGenres.count {
                // Find the radio button in the container and toggle it
                for subview in containerView.subviews {
                    if let radioButton = subview as? UIButton {
                        genreButtonTapped(radioButton)
                        break
                    }
                }
            }
        }
    }
    
    @objc private func genreButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        let genre = musicGenres[sender.tag]
        if sender.isSelected {
            if !selectedGenres.contains(genre) {
                selectedGenres.append(genre)
            }
        } else {
            selectedGenres.removeAll { $0 == genre }
        }
        
        // Enable confirm button if at least one genre is selected
        confirmButton.isEnabled = !selectedGenres.isEmpty
        confirmButton.alpha = selectedGenres.isEmpty ? 0.7 : 1.0
    }
    
    @objc private func confirmButtonTapped() {
        // Save selected genres to user defaults
        UserDefaults.standard.set(selectedGenres, forKey: "userMusicPreferences")
        UserDefaults.standard.set(true, forKey: "hasCompletedMusicPreferences")
        
        // Present the main tab bar controller
        let mainTabBarController = MainTabBarController()
        mainTabBarController.modalPresentationStyle = .fullScreen
        
        present(mainTabBarController, animated: true)
    }
    
    @objc private func skipButtonTapped() {
        // Mark preferences as completed but with empty selection
        UserDefaults.standard.set([], forKey: "userMusicPreferences")
        UserDefaults.standard.set(true, forKey: "hasCompletedMusicPreferences")
        
        // Present the main tab bar controller
        let mainTabBarController = MainTabBarController()
        mainTabBarController.modalPresentationStyle = .fullScreen
        
        present(mainTabBarController, animated: true)
    }
}
