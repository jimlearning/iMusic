import UIKit

class AccountLoginViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "欢迎来到I—MUsic"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "请输入账号"
        textField.borderStyle = .none
        textField.backgroundColor = .systemBackground
        textField.layer.cornerRadius = 25
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray5.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "请输入密码"
        textField.borderStyle = .none
        textField.backgroundColor = .systemBackground
        textField.layer.cornerRadius = 25
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray5.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("登录", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .black
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var otherLoginMethodsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "使用其他方式进行注册/登录"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private lazy var socialButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var wechatButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 95/255, green: 186/255, blue: 125/255, alpha: 1.0) // Green
        button.layer.cornerRadius = 25
        button.tintColor = .white
        button.setImage(UIImage(systemName: "message.fill"), for: .normal)
        button.addTarget(self, action: #selector(wechatButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var appleButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black
        button.layer.cornerRadius = 25
        button.tintColor = .white
        button.setImage(UIImage(systemName: "apple.logo"), for: .normal)
        button.addTarget(self, action: #selector(appleButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add UI components to the view
        view.addSubview(backButton)
        view.addSubview(welcomeLabel)
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(otherLoginMethodsLabel)
        view.addSubview(socialButtonsStackView)
        
        // Add social buttons to stack view
        socialButtonsStackView.addArrangedSubview(wechatButton)
        socialButtonsStackView.addArrangedSubview(appleButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            // Back button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Welcome label
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Username text field
            usernameTextField.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 60),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password text field
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Login button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 40),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Other login methods label
            otherLoginMethodsLabel.bottomAnchor.constraint(equalTo: socialButtonsStackView.topAnchor, constant: -20),
            otherLoginMethodsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Social buttons stack view
            socialButtonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            socialButtonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            socialButtonsStackView.widthAnchor.constraint(equalToConstant: 150),
            socialButtonsStackView.heightAnchor.constraint(equalToConstant: 50),
            
            // Social buttons
            wechatButton.widthAnchor.constraint(equalToConstant: 50),
            wechatButton.heightAnchor.constraint(equalToConstant: 50),
            
            appleButton.widthAnchor.constraint(equalToConstant: 50),
            appleButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add bottom indicator
        addBottomIndicator()
    }
    
    private func addBottomIndicator() {
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = 2
        
        view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 40),
            indicator.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func loginButtonTapped() {
        // Validate input
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Input Error", message: "Please enter both username and password")
            return
        }
        
        // Set user as logged in
        UserDefaults.standard.set(true, forKey: "com.imusic.userLoggedIn")
        
        // For now, accept any valid input
        let mainTabBarController = MainTabBarController()
        mainTabBarController.modalPresentationStyle = .fullScreen
        present(mainTabBarController, animated: true)
    }
    
    @objc private func wechatButtonTapped() {
        // Implement WeChat login logic
        print("WeChat login tapped")
    }
    
    @objc private func appleButtonTapped() {
        // Implement Apple login logic
        print("Apple login tapped")
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
