import SwiftUI

@main
struct YarzarApp: App {
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            MobileMainView()
                .environment(\.locale, lang.locale)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
