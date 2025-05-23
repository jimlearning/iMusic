import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "你好，"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "欢迎来到I-MUsic!"
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var wechatLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("微信登录/注册", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor(red: 95/255, green: 186/255, blue: 125/255, alpha: 1.0) // Green
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(wechatLoginTapped), for: .touchUpInside)
        
        // 添加微信图标
        if let wechatImage = UIImage(systemName: "message.fill") {
            button.setImage(wechatImage, for: .normal)
            button.tintColor = .white
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        
        return button
    }()
    
    private lazy var appleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Apple登录/注册", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .black
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
        
        // 添加Apple图标
        if let appleImage = UIImage(systemName: "apple.logo") {
            button.setImage(appleImage, for: .normal)
            button.tintColor = .white
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        
        return button
    }()
    
    private lazy var passwordLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("账号密码登录", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0) // Light gray
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(passwordLoginTapped), for: .touchUpInside)
        
        // 添加手机图标
        if let phoneImage = UIImage(systemName: "person.fill") {
            button.setImage(phoneImage, for: .normal)
            button.tintColor = .darkGray
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        
        return button
    }()
    
    private lazy var termsCheckbox: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.tintColor = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1.0) // Red
        button.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var termsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "我已阅读并同意《用户协议》和《隐私政策》"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        
        // Add different colors for specific parts of the text
        let attributedString = NSMutableAttributedString(string: label.text!)
        attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: (label.text! as NSString).range(of: "《用户协议》"))
        attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: (label.text! as NSString).range(of: "《隐私政策》"))
        label.attributedText = attributedString
        
        return label
    }()
    
    private lazy var termsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private var isTermsAccepted = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add UI components to the view
        view.addSubview(welcomeLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(wechatLoginButton)
        view.addSubview(appleLoginButton)
        view.addSubview(passwordLoginButton)
        
        // Add terms container
        view.addSubview(termsContainer)
        termsContainer.addSubview(termsCheckbox)
        termsContainer.addSubview(termsLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Welcome label
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
            
            // WeChat login button
            wechatLoginButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 100),
            wechatLoginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            wechatLoginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            wechatLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Apple login button
            appleLoginButton.topAnchor.constraint(equalTo: wechatLoginButton.bottomAnchor, constant: 20),
            appleLoginButton.leadingAnchor.constraint(equalTo: wechatLoginButton.leadingAnchor),
            appleLoginButton.trailingAnchor.constraint(equalTo: wechatLoginButton.trailingAnchor),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Username/password login button
            passwordLoginButton.topAnchor.constraint(equalTo: appleLoginButton.bottomAnchor, constant: 20),
            passwordLoginButton.leadingAnchor.constraint(equalTo: wechatLoginButton.leadingAnchor),
            passwordLoginButton.trailingAnchor.constraint(equalTo: wechatLoginButton.trailingAnchor),
            passwordLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Terms container
            termsContainer.topAnchor.constraint(equalTo: passwordLoginButton.bottomAnchor, constant: 30),
            termsContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            termsContainer.heightAnchor.constraint(equalToConstant: 30),
            
            // Checkbox
            termsCheckbox.leadingAnchor.constraint(equalTo: termsContainer.leadingAnchor),
            termsCheckbox.centerYAnchor.constraint(equalTo: termsContainer.centerYAnchor),
            termsCheckbox.widthAnchor.constraint(equalToConstant: 24),
            termsCheckbox.heightAnchor.constraint(equalToConstant: 24),
            
            // Terms text
            termsLabel.leadingAnchor.constraint(equalTo: termsCheckbox.trailingAnchor, constant: 8),
            termsLabel.centerYAnchor.constraint(equalTo: termsContainer.centerYAnchor),
            termsLabel.trailingAnchor.constraint(equalTo: termsContainer.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func wechatLoginTapped() {
        if !isTermsAccepted {
            showTermsAlert()
            return
        }
        
        // Implement WeChat login logic
        print("微信登录被点击")
    }
    
    @objc private func appleLoginTapped() {
        if !isTermsAccepted {
            showTermsAlert()
            return
        }
        
        // Implement Apple login logic
        print("Apple登录被点击")
    }
    
    @objc private func passwordLoginTapped() {
        if !isTermsAccepted {
            showTermsAlert()
            return
        }
        
        // Present the account login view controller
        let accountLoginVC = AccountLoginViewController()
        accountLoginVC.modalPresentationStyle = .fullScreen
        present(accountLoginVC, animated: true)
    }
    
    @objc private func checkboxTapped() {
        isTermsAccepted.toggle()
        
        if isTermsAccepted {
            termsCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        } else {
            termsCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        }
    }
    
    private func showTermsAlert() {
        let alert = UIAlertController(
            title: "请先同意条款",
            message: "请先阅读并同意《用户协议》和《隐私政策》",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
