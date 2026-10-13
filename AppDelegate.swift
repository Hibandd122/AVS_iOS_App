import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

        // Khởi động warmup WAF session ngay khi mở app để sẵn sàng các request Fast Path
        NetworkManager.shared.warmupWAFSessionIfNeeded { _ in }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.titleTextAttributes = [
            .font: AppTheme.Fonts.title(size: 18),
            .foregroundColor: AppTheme.textPrimary
        ]
        appearance.largeTitleTextAttributes = [
            .font: AppTheme.Fonts.heroTitle(size: 28),
            .foregroundColor: AppTheme.textPrimary
        ]
        appearance.shadowColor = UIColor(white: 1.0, alpha: 0.08)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = AppTheme.primaryAccent

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 0.92)
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        tabAppearance.shadowColor = UIColor(white: 1.0, alpha: 0.12)
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.55, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = AppTheme.primaryAccent
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryAccent,
            .font: AppTheme.Fonts.caption(size: 11)
        ]
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = AppTheme.primaryAccent
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.55, alpha: 1.0)

        return true
    }
}
