import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

extension Coordinator {
    func addChild(_ child: Coordinator) {
        childCoordinators.append(child)
    }

    func removeChild(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }
}

final class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
        navigationController = UINavigationController()
    }

    func start() {
        let tabCoordinator = TabCoordinator(navigationController: navigationController)
        addChild(tabCoordinator)
        tabCoordinator.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

final class TabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let tabBarController = UITabBarController()

        let homeNav = UINavigationController()
        let homeCoordinator = HomeCoordinator(navigationController: homeNav)
        addChild(homeCoordinator)
        homeCoordinator.start()
        homeNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        homeNav.tabBarItem.accessibilityLabel = "Trang chủ"
        homeNav.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        let historyVC = MovieListViewController()
        historyVC.source = .history
        let historyNav = UINavigationController(rootViewController: historyVC)
        historyNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "clock"), selectedImage: UIImage(systemName: "clock.fill"))
        historyNav.tabBarItem.accessibilityLabel = "Lịch sử xem"
        historyNav.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        let favoritesVC = MovieListViewController()
        favoritesVC.source = .favorites
        let favoritesNav = UINavigationController(rootViewController: favoritesVC)
        favoritesNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "heart"), selectedImage: UIImage(systemName: "heart.fill"))
        favoritesNav.tabBarItem.accessibilityLabel = "Phim yêu thích"
        favoritesNav.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
        settingsNav.tabBarItem.accessibilityLabel = "Cài đặt"
        settingsNav.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.92)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.shadowColor = UIColor(white: 1.0, alpha: 0.12) // Subtle glowing top border

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(white: 0.55, alpha: 1.0)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.55, alpha: 1.0),
            .font: AppTheme.Fonts.caption(size: 11)
        ]
        itemAppearance.selected.iconColor = AppTheme.primaryAccent
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryAccent,
            .font: AppTheme.Fonts.caption(size: 11)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        tabBarController.tabBar.tintColor = AppTheme.primaryAccent
        tabBarController.tabBar.unselectedItemTintColor = UIColor(white: 0.55, alpha: 1.0)

        tabBarController.viewControllers = [homeNav, historyNav, favoritesNav, settingsNav]
        tabBarController.selectedIndex = 0

        navigationController.setViewControllers([tabBarController], animated: false)
        navigationController.setNavigationBarHidden(true, animated: false)
    }
}

final class HomeCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let homeVC = HomeViewController()
        homeVC.coordinator = self
        navigationController.setViewControllers([homeVC], animated: false)
    }

    func showDetail(for movie: Movie) {
        let detailVC = MovieInfoViewController()
        detailVC.movie = movie
        navigationController.pushViewController(detailVC, animated: true)
    }

    func showPlayer(episodeUrl: String, episodes: [Episode], index: Int, movie: Movie?) {
        guard episodes.indices.contains(index) else {
            Logger.shared.log("[HomeCoordinator] Bỏ qua yêu cầu mở tập có chỉ số không hợp lệ: \(index)/\(episodes.count)")
            return
        }
        let playerVC = PlayerController()
        playerVC.episodeUrl = episodes[index].link
        playerVC.episodes = episodes
        playerVC.currentIndex = index
        playerVC.movie = movie
        navigationController.pushViewController(playerVC, animated: true)
    }
}
