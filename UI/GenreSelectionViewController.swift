import UIKit

class GenreSelectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var genres: [GenreOption] = [
        GenreOption(name: "Hành Động", slug: "hanh-dong"), GenreOption(name: "Phiêu Lưu", slug: "phieu-luu"),
        GenreOption(name: "Hài Hước", slug: "hai-huoc"), GenreOption(name: "Tình Cảm", slug: "tinh-cam"),
        GenreOption(name: "Ma Thuật", slug: "ma-thuat"), GenreOption(name: "Viễn Tưởng", slug: "vien-tuong"),
        GenreOption(name: "Kinh Dị", slug: "kinh-di"), GenreOption(name: "Đời Thường", slug: "doi-thuong"),
        GenreOption(name: "Trường Học", slug: "truong-hoc"), GenreOption(name: "Thể Thao", slug: "the-thao"),
        GenreOption(name: "Drama", slug: "drama"), GenreOption(name: "Fantasy", slug: "fantasy"),
        GenreOption(name: "Harem", slug: "harem"), GenreOption(name: "Shounen", slug: "shounen"),
        GenreOption(name: "Mecha", slug: "mecha"), GenreOption(name: "Ecchi", slug: "ecchi"),
        GenreOption(name: "Mystery", slug: "mystery"), GenreOption(name: "Siêu Nhiên", slug: "sieu-nhien"),
        GenreOption(name: "Âm Nhạc", slug: "am-nhac"), GenreOption(name: "Lịch Sử", slug: "lich-su"),
        GenreOption(name: "Trò Chơi", slug: "tro-choi")
    ]
    
    var selectedSlugs = Set<String>()
    var onApply: (([GenreOption]) -> Void)?
    
    private var collectionView: UICollectionView!
    private var applyButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chọn Thể Loại"

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

        let applyBtn = UIBarButtonItem(title: "Áp Dụng", style: .done, target: self, action: #selector(applyTapped))
        applyButton = applyBtn
        navigationItem.rightBarButtonItem = applyButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Hủy", style: .plain, target: self, action: #selector(cancelTapped))
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.estimatedItemSize = CGSize(width: 100, height: 40)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GenreCell.self, forCellWithReuseIdentifier: "GenreCell")
        collectionView.allowsMultipleSelection = true
        view.addSubview(collectionView)
        updateApplyButton()

        NetworkManager.shared.fetchGenres { [weak self] fetched in
            guard let self = self, !fetched.isEmpty else { return }
            self.genres = fetched
            self.selectedSlugs = self.selectedSlugs.intersection(Set(fetched.map(\.slug)))
            self.updateApplyButton()
            // `reloadData()` recreates cells, but it does not restore the
            // collection view's selection model. Without this, a chip can look
            // selected while the next tap is treated as a new selection instead
            // of a deselection.
            self.collectionView.indexPathsForSelectedItems?.forEach {
                self.collectionView.deselectItem(at: $0, animated: false)
            }
            self.collectionView.reloadData()
            for (index, genre) in self.genres.enumerated() where self.selectedSlugs.contains(genre.slug) {
                self.collectionView.selectItem(at: IndexPath(item: index, section: 0),
                                               animated: false,
                                               scrollPosition: [])
            }
        }
    }
    
    @objc private func applyTapped() {
        let selected = genres.filter { selectedSlugs.contains($0.slug) }
        dismiss(animated: true) {
            self.onApply?(selected)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func updateApplyButton() {
        let count = selectedSlugs.count
        applyButton.title = count == 0 ? "Áp Dụng" : "Áp Dụng (\(count))"
        applyButton.accessibilityLabel = count == 0
            ? "Áp dụng bộ lọc"
            : "Áp dụng \(count) thể loại"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return genres.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreCell", for: indexPath) as! GenreCell
        let genre = genres[indexPath.row]
        cell.titleLabel.text = genre.name
        cell.isSelected = selectedSlugs.contains(genre.slug)
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = genre.name
        cell.accessibilityTraits = cell.isSelected ? [.button, .selected] : [.button]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedSlugs.insert(genres[indexPath.row].slug)
        updateApplyButton()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        selectedSlugs.remove(genres[indexPath.row].slug)
        updateApplyButton()
    }
}

class GenreCell: UICollectionViewCell {
    let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = AppTheme.cardBackgroundLighter
        contentView.layer.cornerRadius = 20
        contentView.layer.borderWidth = 1.2
        contentView.layer.borderColor = AppTheme.borderGlass.cgColor
        contentView.clipsToBounds = true
        
        titleLabel.font = AppTheme.Fonts.caption(size: 13)
        titleLabel.textColor = AppTheme.textSecondary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override var isSelected: Bool {
        didSet {
            accessibilityTraits = isSelected ? [.button, .selected] : [.button]
            let update = {
                if self.isSelected {
                    self.contentView.backgroundColor = AppTheme.primaryAccent.withAlphaComponent(0.25)
                    self.contentView.layer.borderColor = AppTheme.primaryAccent.cgColor
                    self.titleLabel.textColor = .white
                    self.titleLabel.font = AppTheme.Fonts.subhead(size: 13)
                    AppTheme.applyGlow(to: self.contentView, color: AppTheme.primaryAccent, radius: 8, opacity: 0.5)
                } else {
                    self.contentView.backgroundColor = AppTheme.cardBackgroundLighter
                    self.contentView.layer.borderColor = AppTheme.borderGlass.cgColor
                    self.titleLabel.textColor = AppTheme.textSecondary
                    self.titleLabel.font = AppTheme.Fonts.caption(size: 13)
                    self.contentView.layer.shadowOpacity = 0
                }
            }
            guard !UIAccessibility.isReduceMotionEnabled else { update(); return }
            UIView.animate(withDuration: 0.22, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: update)
        }
    }
}
