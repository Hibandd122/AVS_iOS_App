import UIKit

/// Màn hình Cài đặt VIP mang phong cách Dark Glassmorphism
/// Quản lý Domain, Cấu hình AniSkip, Tùy chỉnh Player và Dọn dẹp Cache.
final class SettingsViewController: UIViewController {

    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    private let cacheSizeLabel = UILabel()
    private let domainStatusLabel = UILabel()
    private let domainValueLabel = UILabel()

    // Switches
    private let autoSkipIntroSwitch = UISwitch()
    private let autoSkipOutroSwitch = UISwitch()
    private let skipToastSwitch = UISwitch()
    private let autoNextEpisodeSwitch = UISwitch()

    // Segmented Controls
    private let seekIntervalSegment = UISegmentedControl(items: ["5s", "10s", "15s", "30s"])
    private let playbackSpeedSegment = UISegmentedControl(items: ["1.0x", "1.25x", "1.5x", "2.0x"])

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentSettings()
        updateCacheSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        domainValueLabel.text = NetworkManager.shared.resolvedDomain
        updateCacheSize()
    }

    // MARK: - UI Setup
    private func setupUI() {
        title = "Cài đặt"
        view.backgroundColor = AppTheme.backgroundDark

        let bgView = BackgroundView()
        bgView.setStyle(.accent)
        bgView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bgView)
        view.sendSubviewToBack(bgView)
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: view.topAnchor),
            bgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentView.axis = .vertical
        contentView.spacing = 20
        contentView.alignment = .fill
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        // Build Sections
        contentView.addArrangedSubview(buildDomainSection())
        contentView.addArrangedSubview(buildAniSkipSection())
        contentView.addArrangedSubview(buildPlayerSection())
        contentView.addArrangedSubview(buildStorageSection())
        contentView.addArrangedSubview(buildAboutSection())
    }

    // MARK: - Section Builders

    /// Section 1: Quản lý Domain AnimeVietsub
    private func buildDomainSection() -> UIView {
        let card = createCardView()
        let stack = createVerticalStack()

        let header = createSectionHeader(title: "MẠNG & NGUỒN PHIM", icon: "network")
        stack.addArrangedSubview(header)

        domainValueLabel.font = AppTheme.Fonts.subhead(size: 14)
        domainValueLabel.textColor = AppTheme.textPrimary
        domainValueLabel.text = NetworkManager.shared.resolvedDomain
        domainValueLabel.numberOfLines = 1

        domainStatusLabel.font = AppTheme.Fonts.caption(size: 12)
        domainStatusLabel.textColor = AppTheme.emeraldSuccess
        domainStatusLabel.text = "● Kết nối hoạt động"

        let domainInfoRow = UIStackView(arrangedSubviews: [domainValueLabel, domainStatusLabel])
        domainInfoRow.axis = .vertical
        domainInfoRow.spacing = 4
        stack.addArrangedSubview(domainInfoRow)

        // Buttons row
        let changeDomainBtn = createActionButton(title: "Đổi Domain", icon: "pencil", accent: false)
        changeDomainBtn.addTarget(self, action: #selector(promptChangeDomain), for: .touchUpInside)

        let probeDomainBtn = createActionButton(title: "Dò Tự Động", icon: "arrow.clockwise", accent: true)
        probeDomainBtn.addTarget(self, action: #selector(forceProbeDomain), for: .touchUpInside)

        let btnRow = UIStackView(arrangedSubviews: [changeDomainBtn, probeDomainBtn])
        btnRow.axis = .horizontal
        btnRow.spacing = 10
        btnRow.distribution = .fillEqually
        stack.addArrangedSubview(btnRow)

        card.addSubview(stack)
        pinStackToCard(stack, in: card)
        return card
    }

    /// Section 2: AniSkip (Bỏ qua Intro / Outro)
    private func buildAniSkipSection() -> UIView {
        let card = createCardView()
        let stack = createVerticalStack()

        let header = createSectionHeader(title: "TỰ ĐỘNG BỎ QUA (ANISKIP)", icon: "forward.end.fill")
        stack.addArrangedSubview(header)

        autoSkipIntroSwitch.onTintColor = AppTheme.primaryAccent
        autoSkipIntroSwitch.addTarget(self, action: #selector(toggleSkipIntro), for: .valueChanged)
        stack.addArrangedSubview(createSwitchRow(title: "Tự động bỏ qua Intro (OP)",
                                                subtitle: "Bỏ qua bài hát mở đầu theo dữ liệu AniSkip",
                                                switchControl: autoSkipIntroSwitch))

        autoSkipOutroSwitch.onTintColor = AppTheme.primaryAccent
        autoSkipOutroSwitch.addTarget(self, action: #selector(toggleSkipOutro), for: .valueChanged)
        stack.addArrangedSubview(createSwitchRow(title: "Tự động bỏ qua Outro (ED)",
                                                subtitle: "Tự động tua qua bài hát kết thúc phim",
                                                switchControl: autoSkipOutroSwitch))

        skipToastSwitch.onTintColor = AppTheme.primaryAccent
        skipToastSwitch.addTarget(self, action: #selector(toggleSkipToast), for: .valueChanged)
        stack.addArrangedSubview(createSwitchRow(title: "Thông báo khi bỏ qua",
                                                subtitle: "Hiển thị HUD nhỏ trên video khi tự động skip",
                                                switchControl: skipToastSwitch))

        card.addSubview(stack)
        pinStackToCard(stack, in: card)
        return card
    }

    /// Section 3: Cấu hình Trình phát Video (Player)
    private func buildPlayerSection() -> UIView {
        let card = createCardView()
        let stack = createVerticalStack()

        let header = createSectionHeader(title: "TRÌNH PHÁT VIDEO", icon: "play.circle.fill")
        stack.addArrangedSubview(header)

        // Tua nhanh Double-Tap
        let seekLabel = UILabel()
        seekLabel.text = "Thời gian tua (Chạm 2 lần hai bên)"
        seekLabel.font = AppTheme.Fonts.subhead(size: 14)
        seekLabel.textColor = AppTheme.textPrimary

        seekIntervalSegment.selectedSegmentTintColor = AppTheme.primaryAccent
        seekIntervalSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        seekIntervalSegment.setTitleTextAttributes([.foregroundColor: AppTheme.textSecondary], for: .normal)
        seekIntervalSegment.backgroundColor = AppTheme.cardBackgroundLighter
        seekIntervalSegment.addTarget(self, action: #selector(changeSeekInterval), for: .valueChanged)

        let seekStack = UIStackView(arrangedSubviews: [seekLabel, seekIntervalSegment])
        seekStack.axis = .vertical
        seekStack.spacing = 8
        stack.addArrangedSubview(seekStack)

        // Tốc độ phát mặc định
        let speedLabel = UILabel()
        speedLabel.text = "Tốc độ phát mặc định"
        speedLabel.font = AppTheme.Fonts.subhead(size: 14)
        speedLabel.textColor = AppTheme.textPrimary

        playbackSpeedSegment.selectedSegmentTintColor = AppTheme.primaryAccent
        playbackSpeedSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        playbackSpeedSegment.setTitleTextAttributes([.foregroundColor: AppTheme.textSecondary], for: .normal)
        playbackSpeedSegment.backgroundColor = AppTheme.cardBackgroundLighter
        playbackSpeedSegment.addTarget(self, action: #selector(changePlaybackSpeed), for: .valueChanged)

        let speedStack = UIStackView(arrangedSubviews: [speedLabel, playbackSpeedSegment])
        speedStack.axis = .vertical
        speedStack.spacing = 8
        stack.addArrangedSubview(speedStack)

        // Tự chuyển tập tiếp theo
        autoNextEpisodeSwitch.onTintColor = AppTheme.primaryAccent
        autoNextEpisodeSwitch.addTarget(self, action: #selector(toggleAutoNextEpisode), for: .valueChanged)
        stack.addArrangedSubview(createSwitchRow(title: "Tự động chuyển tập",
                                                subtitle: "Phát tập kế tiếp khi xem hết tập hiện tại",
                                                switchControl: autoNextEpisodeSwitch))

        card.addSubview(stack)
        pinStackToCard(stack, in: card)
        return card
    }

    /// Section 4: Dọn dẹp Bộ nhớ Cache & Lịch sử
    private func buildStorageSection() -> UIView {
        let card = createCardView()
        let stack = createVerticalStack()

        let header = createSectionHeader(title: "BỘ NHỚ ĐỆM & DỮ LIỆU", icon: "internaldrive.fill")
        stack.addArrangedSubview(header)

        cacheSizeLabel.font = AppTheme.Fonts.subhead(size: 14)
        cacheSizeLabel.textColor = AppTheme.textSecondary
        cacheSizeLabel.text = "Đang tính dung lượng..."
        stack.addArrangedSubview(cacheSizeLabel)

        let clearCacheBtn = createActionButton(title: "Xóa Bộ Nhớ Đệm (Ảnh & Dữ Liệu)", icon: "trash", accent: false)
        clearCacheBtn.addTarget(self, action: #selector(clearCache), for: .touchUpInside)
        stack.addArrangedSubview(clearCacheBtn)

        let clearHistoryBtn = createActionButton(title: "Xóa Toàn Bộ Lịch Sử Xem", icon: "clock.arrow.circlepath", accent: false)
        clearHistoryBtn.setTitleColor(.systemRed, for: .normal)
        clearHistoryBtn.tintColor = .systemRed
        clearHistoryBtn.addTarget(self, action: #selector(clearWatchHistory), for: .touchUpInside)
        stack.addArrangedSubview(clearHistoryBtn)

        card.addSubview(stack)
        pinStackToCard(stack, in: card)
        return card
    }

    /// Section 5: Thông tin ứng dụng
    private func buildAboutSection() -> UIView {
        let card = createCardView()
        let stack = createVerticalStack()

        let header = createSectionHeader(title: "THÔNG TIN ỨNG DỤNG", icon: "info.circle.fill")
        stack.addArrangedSubview(header)

        let appName = UILabel()
        appName.text = "AnimeVietsub iOS (AVS VIP Edition)"
        appName.font = AppTheme.Fonts.title(size: 16)
        appName.textColor = AppTheme.textPrimary

        let version = UILabel()
        let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
        let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2"
        version.text = "Phiên bản: \(appVer) (Build \(buildNum))\nThiết kế Dark Glassmorphism, HLS Stream, AniSkip Native."
        version.font = AppTheme.Fonts.caption(size: 13)
        version.textColor = AppTheme.textMuted
        version.numberOfLines = 0

        stack.addArrangedSubview(appName)
        stack.addArrangedSubview(version)

        card.addSubview(stack)
        pinStackToCard(stack, in: card)
        return card
    }

    // MARK: - Helper UI Constructors
    private func createCardView() -> UIView {
        let card = UIView()
        card.backgroundColor = AppTheme.cardBackground
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = AppTheme.borderGlass.cgColor
        card.clipsToBounds = true
        return card
    }

    private func createVerticalStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func pinStackToCard(_ stack: UIStackView, in card: UIView) {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    private func createSectionHeader(title: String, icon: String) -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = AppTheme.primaryAccent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let label = UILabel()
        label.text = title
        label.font = AppTheme.Fonts.badge(size: 12)
        label.textColor = AppTheme.primaryAccent

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }

    private func createSwitchRow(title: String, subtitle: String, switchControl: UISwitch) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppTheme.Fonts.subhead(size: 15)
        titleLabel.textColor = AppTheme.textPrimary

        let subLabel = UILabel()
        subLabel.text = subtitle
        subLabel.font = AppTheme.Fonts.caption(size: 12)
        subLabel.textColor = AppTheme.textMuted
        subLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [textStack, switchControl])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        switchControl.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func createActionButton(title: String, icon: String, accent: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("  \(title)", for: .normal)
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.titleLabel?.font = AppTheme.Fonts.subhead(size: 14)
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        if accent {
            btn.backgroundColor = AppTheme.primaryAccent
            btn.setTitleColor(.white, for: .normal)
            btn.tintColor = .white
        } else {
            btn.backgroundColor = AppTheme.cardBackgroundLighter
            btn.setTitleColor(AppTheme.textPrimary, for: .normal)
            btn.tintColor = AppTheme.secondaryAccent
            btn.layer.borderWidth = 1
            btn.layer.borderColor = AppTheme.borderGlass.cgColor
        }
        return btn
    }

    // MARK: - Settings State Management
    private func loadCurrentSettings() {
        let defaults = UserDefaults.standard

        // AniSkip settings
        let skipIntro = defaults.object(forKey: "auto_skip_intro") == nil ? true : defaults.bool(forKey: "auto_skip_intro")
        autoSkipIntroSwitch.isOn = skipIntro

        let skipOutro = defaults.object(forKey: "auto_skip_outro") == nil ? true : defaults.bool(forKey: "auto_skip_outro")
        autoSkipOutroSwitch.isOn = skipOutro

        let skipToast = defaults.object(forKey: "show_skip_toast") == nil ? true : defaults.bool(forKey: "show_skip_toast")
        skipToastSwitch.isOn = skipToast

        // Player settings
        let autoNext = defaults.object(forKey: "player_auto_next") == nil ? true : defaults.bool(forKey: "player_auto_next")
        autoNextEpisodeSwitch.isOn = autoNext

        let seekInterval = defaults.integer(forKey: "player_seek_interval") // default 0 -> 10s
        switch seekInterval {
        case 5: seekIntervalSegment.selectedSegmentIndex = 0
        case 15: seekIntervalSegment.selectedSegmentIndex = 2
        case 30: seekIntervalSegment.selectedSegmentIndex = 3
        default: seekIntervalSegment.selectedSegmentIndex = 1 // 10s
        }

        let speed = defaults.float(forKey: "player_default_speed")
        if speed == 1.25 {
            playbackSpeedSegment.selectedSegmentIndex = 1
        } else if speed == 1.5 {
            playbackSpeedSegment.selectedSegmentIndex = 2
        } else if speed == 2.0 {
            playbackSpeedSegment.selectedSegmentIndex = 3
        } else {
            playbackSpeedSegment.selectedSegmentIndex = 0
        }
    }

    // MARK: - Actions
    @objc private func toggleSkipIntro(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "auto_skip_intro")
    }

    @objc private func toggleSkipOutro(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "auto_skip_outro")
    }

    @objc private func toggleSkipToast(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "show_skip_toast")
    }

    @objc private func toggleAutoNextEpisode(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "player_auto_next")
    }

    @objc private func changeSeekInterval(_ sender: UISegmentedControl) {
        let seconds: Int
        switch sender.selectedSegmentIndex {
        case 0: seconds = 5
        case 2: seconds = 15
        case 3: seconds = 30
        default: seconds = 10
        }
        UserDefaults.standard.set(seconds, forKey: "player_seek_interval")
    }

    @objc private func changePlaybackSpeed(_ sender: UISegmentedControl) {
        let speed: Float
        switch sender.selectedSegmentIndex {
        case 1: speed = 1.25
        case 2: speed = 1.5
        case 3: speed = 2.0
        default: speed = 1.0
        }
        UserDefaults.standard.set(speed, forKey: "player_default_speed")
    }

    @objc private func promptChangeDomain() {
        let alert = UIAlertController(title: "Đổi Domain AnimeVietsub",
                                      message: "Nhập địa chỉ domain mới khi trang web đổi domain:",
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "https://animevietsub.li"
            tf.text = NetworkManager.shared.resolvedDomain
            tf.keyboardType = .URL
        }
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return }
            guard let url = URL(string: text),
                  let scheme = url.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https"),
                  url.host != nil else {
                self?.showErrorAlert("Domain không hợp lệ. Vui lòng nhập đầy đủ https://...")
                return
            }
            NetworkManager.shared.resolvedDomain = text
            self?.domainValueLabel.text = text
            self?.updateCacheSize()
        })
        present(alert, animated: true)
    }

    @objc private func forceProbeDomain() {
        domainStatusLabel.textColor = AppTheme.vipGold
        domainStatusLabel.text = "◌ Đang kiểm tra link chuyển hướng bit.ly..."

        NetworkManager.shared.autoDetectDomain(force: true) { [weak self] detected in
            DispatchQueue.main.async {
                self?.domainValueLabel.text = detected
                self?.domainStatusLabel.textColor = AppTheme.emeraldSuccess
                self?.domainStatusLabel.text = "● Đã cập nhật domain mới nhất"
            }
        }
    }

    private func updateCacheSize() {
        DispatchQueue.global(qos: .utility).async {
            let diskUsage = URLCache.shared.currentDiskUsage
            let mb = Double(diskUsage) / (1024 * 1024)
            let formatted = String(format: "Dung lượng bộ nhớ tạm hiện tại: %.1f MB", mb)
            DispatchQueue.main.async {
                self.cacheSizeLabel.text = formatted
            }
        }
    }

    @objc private func clearCache() {
        let alert = UIAlertController(title: "Dọn dẹp Cache",
                                      message: "Thao tác này sẽ xoá bộ nhớ tạm của ảnh và danh sách phim để giải phóng dung lượng.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa ngay", style: .destructive) { [weak self] _ in
            DiskCache.shared.removeAll()
            ImageLoader.shared.purge()
            URLCache.shared.removeAllCachedResponses()
            self?.updateCacheSize()

            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        })
        present(alert, animated: true)
    }

    @objc private func clearWatchHistory() {
        let alert = UIAlertController(title: "Xóa Lịch Sử Xem",
                                      message: "Bạn có chắc chắn muốn xóa toàn bộ danh sách anime đã xem không?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa tất cả", style: .destructive) { _ in
            PlaybackStore.shared.clearAllHistory()
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        })
        present(alert, animated: true)
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Lỗi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}
