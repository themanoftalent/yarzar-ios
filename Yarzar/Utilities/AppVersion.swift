import Foundation

enum AppLinks {
    static let repoURL = URL(string: "https://github.com/themanoftalent/Yarzar")!
    static let helpURL = URL(string: "https://github.com/themanoftalent/Yarzar#readme")!
    static let releasesURL = URL(string: "https://github.com/themanoftalent/Yarzar/releases")!
}

struct AppVersion: Equatable {
    let raw: String

    static var current: AppVersion {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.3"
        return AppVersion(raw: v)
    }

    var displayString: String {
        raw
    }
}
