import UIKit

class MovieInfoViewController: UIViewController {

    var movie: Movie!

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let bannerImage = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let descLabel = InsetLabel()
    private let expandDescriptionButton = UIButton(type: .system)
    private let genreStack = UIStackView()
    private let watchButton = UIButton(type: .system)
    private let favButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)
    private let loader = UIActivityIndicatorView(style: .medium)
    private let descSkeleton = SkeletonView()

    private let episodesContainer = UIView()
    private let quickEpisodesTitle = UILabel()
    private let viewAllEpisodesLink = UIButton(type: .system)
    private let quickEpisodeScroll = UIScrollView()
    private let quickEpisodeStack = UIStackView()

    private var episodes: [Episode] = []
    private var details: MovieDetails?
    private var resumeEpisodeIndex: Int?
    private var isDescriptionExpanded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        guard movie != nil else {
            Logger.shared.log("[MovieInfo] Thiếu dữ liệu movie, đóng màn hình an toàn")
            navigationController?.popViewController(animated: true)
            return
        }
        title = movie.title

        view.backgroundColor = AppTheme.backgroundDark

        let bg = BackgroundView()
        bg.setStyle(.accent)
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bg)
        view.sendSubviewToBack(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupNavBar()
        setupViews()
        bindMovie()
        fetchDetails()
        fetchEpisodes()
        loadResumeIfAny()

        // Lịch sử được ghi khi user thực sự bấm play, không phải mở info → ko log ở đây.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard movie != nil else { return }
        loadResumeIfAny()    // Quay lại từ player → refresh nút "Tiếp tục"
        refreshFavButton()
    }

    private func setupNavBar() {
        favButton.translatesAutoresizingMaskIntoConstraints = false
        favButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        favButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        favButton.accessibilityLabel = "Yêu thích"
        favButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)

        let shareButton = UIButton(type: .system)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        shareButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = AppTheme.textPrimary
        shareButton.accessibilityLabel = "Chia sẻ"
        shareButton.addTarget(self, action: #selector(shareMovie), for: .touchUpInside)

        let favBarItem = UIBarButtonItem(customView: favButton)
        let shareBarItem = UIBarButtonItem(customView: shareButton)
        navigationItem.rightBarButtonItems = [favBarItem, shareBarItem]
        refreshFavButton()
    }

    @objc private func shareMovie() {
        guard let movie = movie else { return }
        let shareUrl = movie.link.hasPrefix("http") ? movie.link : "\(NetworkManager.shared.resolvedDomain)\(movie.link)"
        let text = "Xem anime \(movie.title) trên AnimeVietsub:"
        let activityVC = UIActivityViewController(activityItems: [text, shareUrl], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        present(activityVC, animated: true)
    }

    private func refreshFavButton() {
        let isFav = PlaybackStore.shared.isFavorite(movie)
        let img = UIImage(systemName: isFav ? "heart.fill" : "heart")
        favButton.setImage(img, for: .normal)
        favButton.tintColor = isFav ? .systemRed : .label
        favButton.accessibilityValue = isFav ? "Đã thêm vào yêu thích" : "Chưa thêm vào yêu thích"
    }

    @objc private func toggleFavorite() {
        _ = PlaybackStore.shared.toggleFavorite(movie)
        refreshFavButton()
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        favButton.transform = CGAffineTransform(scaleX: 0.72, y: 0.72)
        UIView.animate(withDuration: 0.38,
                       delay: 0,
                       usingSpringWithDamping: 0.52,
                       initialSpringVelocity: 0.8,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.favButton.transform = .identity
        }
    }

    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let bannerHeightConstraint: NSLayoutConstraint
        bannerImage.contentMode = .scaleAspectFill
        bannerImage.clipsToBounds = true
        bannerImage.backgroundColor = .tertiarySystemFill
        bannerImage.translatesAutoresizingMaskIntoConstraints = false
        let bannerWrap = UIView()
        bannerWrap.backgroundColor = AppTheme.cardBackground
        bannerWrap.layer.cornerRadius = 22
        bannerWrap.clipsToBounds = true
        bannerWrap.addSubview(bannerImage)
        bannerHeightConstraint = bannerImage.heightAnchor.constraint(equalTo: bannerImage.widthAnchor, multiplier: 9.0/16.0)
        NSLayoutConstraint.activate([
            bannerImage.topAnchor.constraint(equalTo: bannerWrap.topAnchor),
            bannerImage.leadingAnchor.constraint(equalTo: bannerWrap.leadingAnchor),
            bannerImage.trailingAnchor.constraint(equalTo: bannerWrap.trailingAnchor),
            bannerImage.bottomAnchor.constraint(equalTo: bannerWrap.bottomAnchor),
            bannerHeightConstraint
        ])

        titleLabel.font = AppTheme.Fonts.heroTitle(size: 26)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        metaLabel.font = AppTheme.Fonts.subhead(size: 14)
        metaLabel.adjustsFontForContentSizeCategory = true
        metaLabel.textColor = AppTheme.textSecondary
        metaLabel.numberOfLines = 1
        metaLabel.backgroundColor = AppTheme.surfaceGlass
        metaLabel.layer.cornerRadius = 10
        metaLabel.clipsToBounds = true

        descLabel.font = AppTheme.Fonts.body(size: 15)
        descLabel.adjustsFontForContentSizeCategory = true
        descLabel.textColor = AppTheme.textPrimary
        descLabel.numberOfLines = 4
        descLabel.backgroundColor = AppTheme.surfaceGlass
        descLabel.layer.cornerRadius = 16
        descLabel.clipsToBounds = true

        expandDescriptionButton.titleLabel?.font = AppTheme.Fonts.subhead(size: 14)
        expandDescriptionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        expandDescriptionButton.tintColor = AppTheme.secondaryAccent
        expandDescriptionButton.contentHorizontalAlignment = .leading
        expandDescriptionButton.setTitle("Xem thêm", for: .normal)
        expandDescriptionButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        expandDescriptionButton.semanticContentAttribute = .forceRightToLeft
        expandDescriptionButton.accessibilityLabel = "Mở rộng mô tả"
        expandDescriptionButton.addTarget(self, action: #selector(toggleDescription), for: .touchUpInside)
        expandDescriptionButton.isHidden = true

        genreStack.axis = .horizontal
        genreStack.spacing = 8
        genreStack.distribution = .fillProportionally
        let genreScroll = UIScrollView()
        genreScroll.showsHorizontalScrollIndicator = false
        genreScroll.translatesAutoresizingMaskIntoConstraints = false
        genreScroll.addSubview(genreStack)
        genreStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            genreStack.topAnchor.constraint(equalTo: genreScroll.topAnchor),
            genreStack.leadingAnchor.constraint(equalTo: genreScroll.leadingAnchor),
            genreStack.trailingAnchor.constraint(equalTo: genreScroll.trailingAnchor),
            genreStack.bottomAnchor.constraint(equalTo: genreScroll.bottomAnchor),
            genreStack.heightAnchor.constraint(equalTo: genreScroll.heightAnchor)
        ])

        watchButton.setTitle("▶  Xem từ đầu", for: .normal)
        watchButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        watchButton.accessibilityLabel = "Xem từ đầu"
        styleAccentButton(watchButton)
        watchButton.addTarget(self, action: #selector(watchFromBeginning), for: .touchUpInside)

        continueButton.setTitle("⏵ Đang tải...", for: .normal)
        continueButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        continueButton.accessibilityLabel = "Tiếp tục xem"
        styleAccentButton(continueButton, accent: false)
        continueButton.addTarget(self, action: #selector(continueWatching), for: .touchUpInside)
        continueButton.isHidden = true

        let buttonsRow = UIStackView(arrangedSubviews: [continueButton, watchButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.distribution = .fillEqually

        loader.startAnimating()

        // Quick Episode Carousel Container
        episodesContainer.translatesAutoresizingMaskIntoConstraints = false
        episodesContainer.isHidden = true

        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .equalSpacing
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let headerIndicator = UIView()
        headerIndicator.backgroundColor = AppTheme.primaryAccent
        headerIndicator.layer.cornerRadius = 2
        headerIndicator.clipsToBounds = true
        headerIndicator.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.applyGlow(to: headerIndicator, color: AppTheme.primaryAccent, radius: 4, opacity: 0.8)

        quickEpisodesTitle.font = AppTheme.Fonts.sectionHeader(size: 16)
        quickEpisodesTitle.textColor = AppTheme.textPrimary
        quickEpisodesTitle.text = "TẬP PHIM"

        let titleGroup = UIStackView(arrangedSubviews: [headerIndicator, quickEpisodesTitle])
        titleGroup.axis = .horizontal
        titleGroup.spacing = 8
        titleGroup.alignment = .center

        viewAllEpisodesLink.setTitle("Xem tất cả ›", for: .normal)
        viewAllEpisodesLink.setTitleColor(AppTheme.secondaryAccent, for: .normal)
        viewAllEpisodesLink.titleLabel?.font = AppTheme.Fonts.subhead(size: 14)
        viewAllEpisodesLink.addTarget(self, action: #selector(showAllEpisodes), for: .touchUpInside)

        headerRow.addArrangedSubview(titleGroup)
        headerRow.addArrangedSubview(viewAllEpisodesLink)

        quickEpisodeScroll.showsHorizontalScrollIndicator = false
        quickEpisodeScroll.alwaysBounceHorizontal = true
        quickEpisodeScroll.translatesAutoresizingMaskIntoConstraints = false

        quickEpisodeStack.axis = .horizontal
        quickEpisodeStack.spacing = 10
        quickEpisodeStack.alignment = .center
        quickEpisodeStack.translatesAutoresizingMaskIntoConstraints = false
        quickEpisodeScroll.addSubview(quickEpisodeStack)

        episodesContainer.addSubview(headerRow)
        episodesContainer.addSubview(quickEpisodeScroll)

        NSLayoutConstraint.activate([
            headerIndicator.widthAnchor.constraint(equalToConstant: 4),
            headerIndicator.heightAnchor.constraint(equalToConstant: 16),

            headerRow.topAnchor.constraint(equalTo: episodesContainer.topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: episodesContainer.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: episodesContainer.trailingAnchor),

            quickEpisodeScroll.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 10),
            quickEpisodeScroll.leadingAnchor.constraint(equalTo: episodesContainer.leadingAnchor),
            quickEpisodeScroll.trailingAnchor.constraint(equalTo: episodesContainer.trailingAnchor),
            quickEpisodeScroll.bottomAnchor.constraint(equalTo: episodesContainer.bottomAnchor),
            quickEpisodeScroll.heightAnchor.constraint(equalToConstant: 48),

            quickEpisodeStack.topAnchor.constraint(equalTo: quickEpisodeScroll.topAnchor),
            quickEpisodeStack.leadingAnchor.constraint(equalTo: quickEpisodeScroll.leadingAnchor),
            quickEpisodeStack.trailingAnchor.constraint(equalTo: quickEpisodeScroll.trailingAnchor),
            quickEpisodeStack.bottomAnchor.constraint(equalTo: quickEpisodeScroll.bottomAnchor),
            quickEpisodeStack.heightAnchor.constraint(equalTo: quickEpisodeScroll.heightAnchor)
        ])

        descSkeleton.translatesAutoresizingMaskIntoConstraints = false
        descSkeleton.layer.cornerRadius = 16
        descSkeleton.clipsToBounds = true
        descSkeleton.startShimmer()

        [bannerWrap, titleLabel, metaLabel, genreScroll, buttonsRow, episodesContainer, descSkeleton, descLabel, expandDescriptionButton, loader].forEach { stack.addArrangedSubview($0) }

        descLabel.isHidden = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            genreScroll.heightAnchor.constraint(equalToConstant: 34),
            descSkeleton.heightAnchor.constraint(equalToConstant: 78)
        ])
    }

    private func styleAccentButton(_ btn: UIButton, accent: Bool = true) {
        btn.titleLabel?.font = AppTheme.Fonts.subhead(size: 15)
        btn.backgroundColor = accent ? AppTheme.primaryAccent : AppTheme.cardBackgroundLighter
        btn.setTitleColor(accent ? .white : AppTheme.textPrimary, for: .normal)
        btn.tintColor = accent ? .white : AppTheme.secondaryAccent
        btn.semanticContentAttribute = .forceLeftToRight
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = accent ? 0 : 1
        btn.layer.borderColor = AppTheme.borderGlass.cgColor
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        btn.imageView?.contentMode = .scaleAspectFit
        if accent {
            AppTheme.applyGlow(to: btn, color: AppTheme.primaryAccent, radius: 10, opacity: 0.45)
        }
    }

    private func bindMovie() {
        titleLabel.text = movie.title
        metaLabel.text = movie.episodeStatus
        // Dùng poster làm placeholder banner cho đến khi có ảnh chính từ details.
        if let url = URL(string: movie.thumbUrl) {
            ImageLoader.shared.load(url, into: bannerImage)
        }
    }

    private func fetchDetails() {
        NetworkManager.shared.fetchMovieDetails(movieUrl: movie.link) { [weak self] details in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let d = details else {
                    self.descLabel.text = "(Không thể tải thông tin chi tiết phim)"
                    return
                }
                self.populateDetails(d)
            }
        }
    }

    private func populateDetails(_ d: MovieDetails) {
        var metaParts: [String] = []
        if !d.rating.isEmpty { metaParts.append("⭐ \(d.rating)") }
        if !d.year.isEmpty { metaParts.append("📅 \(d.year)") }
        if !movie.episodeStatus.isEmpty {
            metaParts.append(movie.episodeStatus)
        }
        metaLabel.text = metaParts.joined(separator: "   •   ")

        descSkeleton.stopShimmer()
        descSkeleton.isHidden = true
        descLabel.isHidden = false

        descLabel.text = d.description.isEmpty ? "(Chưa có mô tả)" : d.description
        isDescriptionExpanded = false
        descLabel.numberOfLines = 4
        expandDescriptionButton.isHidden = d.description.count < 170
        updateDescriptionButton()

        // Banner thật từ details nếu có.
        if !d.bannerUrl.isEmpty, let url = URL(string: d.bannerUrl) {
            ImageLoader.shared.load(url, into: bannerImage)
        }

        // Genre chips VIP phong cách Capsule kính mờ
        genreStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for g in d.genres.prefix(8) {
            let chip = UILabel()
            chip.text = "   \(g)   "
            chip.font = AppTheme.Fonts.caption(size: 12)
            chip.textColor = AppTheme.textPrimary
            chip.backgroundColor = AppTheme.cardBackgroundLighter
            chip.layer.cornerRadius = 14
            chip.layer.borderWidth = 1
            chip.layer.borderColor = AppTheme.borderGlass.cgColor
            chip.clipsToBounds = true
            genreStack.addArrangedSubview(chip)
        }
    }

    private func fetchEpisodes() {
        NetworkManager.shared.fetchEpisodes(movieUrl: movie.link) { [weak self] eps in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.episodes = eps
                self.loader.stopAnimating()
                self.loader.isHidden = true
                if eps.isEmpty {
                    self.watchButton.setTitle("Không có tập nào", for: .normal)
                    self.watchButton.isEnabled = false
                } else {
                    self.watchButton.setTitle("▶  Xem tập 1", for: .normal)
                    self.watchButton.isEnabled = true
                }
                self.loadResumeIfAny()
                self.populateQuickEpisodes()
            }
        }
    }

    private func populateQuickEpisodes() {
        quickEpisodeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !episodes.isEmpty else {
            episodesContainer.isHidden = true
            return
        }
        episodesContainer.isHidden = false
        viewAllEpisodesLink.setTitle("Xem tất cả (\(episodes.count)) ›", for: .normal)

        for (index, ep) in episodes.prefix(40).enumerated() {
            let btn = UIButton(type: .system)
            let isCurrent = (index == resumeEpisodeIndex)
            let progress = PlaybackStore.shared.progress(for: ep.link) ?? 0
            let isWatched = progress > 0.85

            let title = "\(index + 1)"
            btn.setTitle(isCurrent ? "▶ \(title)" : title, for: .normal)
            btn.titleLabel?.font = isCurrent ? AppTheme.Fonts.badge(size: 14) : AppTheme.Fonts.subhead(size: 14)
            btn.tag = index
            btn.layer.cornerRadius = 14
            btn.clipsToBounds = true
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)

            if isCurrent {
                btn.backgroundColor = AppTheme.primaryAccent
                btn.setTitleColor(.white, for: .normal)
                AppTheme.applyGlow(to: btn, color: AppTheme.primaryAccent, radius: 8, opacity: 0.6)
            } else if isWatched {
                btn.backgroundColor = AppTheme.cardBackgroundLighter
                btn.layer.borderWidth = 1
                btn.layer.borderColor = AppTheme.emeraldSuccess.withAlphaComponent(0.4).cgColor
                btn.setTitleColor(AppTheme.textSecondary, for: .normal)
            } else {
                btn.backgroundColor = AppTheme.cardBackgroundLighter
                btn.layer.borderWidth = 1
                btn.layer.borderColor = AppTheme.borderGlass.cgColor
                btn.setTitleColor(AppTheme.textPrimary, for: .normal)
            }

            btn.addTarget(self, action: #selector(quickEpisodeTapped(_:)), for: .touchUpInside)
            quickEpisodeStack.addArrangedSubview(btn)
        }
    }

    @objc private func quickEpisodeTapped(_ sender: UIButton) {
        let index = sender.tag
        AppTheme.triggerImpactHaptic(style: .medium)
        openPlayer(at: index)
    }

    private func loadResumeIfAny() {
        // Tìm tập gần nhất user đã xem từ HistoryEntry; nếu không có, check
        // positionMap cho từng episode trong danh sách.
        let history = PlaybackStore.shared.history()
        if let h = history.first(where: { $0.movie.persistenceID == movie.persistenceID && $0.isCompleted != true }) {
            let matchedIndex = h.lastEpisodeURL.flatMap { url in
                let identifier = ContentIdentifier.make(from: url)
                return episodes.firstIndex(where: { $0.persistenceID == identifier })
            }
            guard let index = matchedIndex ?? (episodes.indices.contains(h.lastEpisodeIndex) ? h.lastEpisodeIndex : nil) else {
                continueButton.isHidden = true
                resumeEpisodeIndex = nil
                populateQuickEpisodes()
                return
            }
            resumeEpisodeIndex = index
            continueButton.setTitle("⏵ Tiếp tục \(h.lastEpisodeTitle)", for: .normal)
            continueButton.isHidden = false
            populateQuickEpisodes()
            return
        }
        continueButton.isHidden = true
        resumeEpisodeIndex = nil
        populateQuickEpisodes()
    }

    // MARK: - Actions

    @objc private func watchFromBeginning() {
        guard !episodes.isEmpty else { return }
        openPlayer(at: 0, resume: false)
    }

    @objc private func toggleDescription() {
        isDescriptionExpanded.toggle()
        descLabel.numberOfLines = isDescriptionExpanded ? 0 : 4
        updateDescriptionButton()

        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: 0.24,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateDescriptionButton() {
        let title = isDescriptionExpanded ? "Thu gọn" : "Xem thêm"
        let image = UIImage(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
        expandDescriptionButton.setTitle(title, for: .normal)
        expandDescriptionButton.setImage(image, for: .normal)
        expandDescriptionButton.accessibilityLabel = isDescriptionExpanded ? "Thu gọn mô tả" : "Mở rộng mô tả"
        expandDescriptionButton.accessibilityValue = isDescriptionExpanded ? "Đang mở rộng" : "Đang thu gọn"
    }

    @objc private func continueWatching() {
        guard let idx = resumeEpisodeIndex, episodes.indices.contains(idx) else { return }
        openPlayer(at: idx)
    }

    @objc private func showAllEpisodes() {
        let listVC = EpisodeListViewController()
        listVC.movie = movie
        if !episodes.isEmpty {
            listVC.episodes = episodes
        }
        navigationController?.pushViewController(listVC, animated: true)
    }

    private func openPlayer(at index: Int, resume: Bool = true) {
        guard episodes.indices.contains(index) else { return }
        if !resume {
            PlaybackStore.shared.clearPosition(for: episodes[index].link)
        }
        let playerVC = PlayerController()
        playerVC.episodes = episodes
        playerVC.currentIndex = index
        playerVC.episodeUrl = episodes[index].link
        playerVC.movie = movie
        playerVC.shouldResumePlayback = resume
        navigationController?.pushViewController(playerVC, animated: true)
    }
}

private final class InsetLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + contentInsets.left + contentInsets.right,
                      height: size.height + contentInsets.top + contentInsets.bottom)
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: contentInsets)
        let textRect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)
        return CGRect(x: textRect.origin.x - contentInsets.left,
                      y: textRect.origin.y - contentInsets.top,
                      width: textRect.width + contentInsets.left + contentInsets.right,
                      height: textRect.height + contentInsets.top + contentInsets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
}
