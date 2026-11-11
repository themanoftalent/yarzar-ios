import Combine
import Foundation

struct GitHubReleaseInfo: Identifiable, Equatable {
    var id: String { version }
    let version: String
    let htmlURL: URL
    let body: String
}

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var isChecking = false
    @Published var statusMessage: String?
    @Published var isUpToDate = true
    @Published var pendingRelease: GitHubReleaseInfo?

    var currentVersion: String {
        AppVersion.current.displayString
    }

    func checkNow() {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = nil

        Task {
            defer { isChecking = false }
            guard let url = URL(string: "https://api.github.com/repos/themanoftalent/Yarzar/releases/latest") else { return }
            var req = URLRequest(url: url, timeoutInterval: 8)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            req.setValue("Yarzar/\(currentVersion)", forHTTPHeaderField: "User-Agent")

            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse else { return }
                if http.statusCode == 200,
                   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String,
                   let htmlUrlStr = json["html_url"] as? String,
                   let htmlURL = URL(string: htmlUrlStr) {
                    let cleanTag = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                    if cleanTag.compare(currentVersion, options: .numeric) == .orderedDescending {
                        isUpToDate = false
                        statusMessage = L("Update available: v\(cleanTag)")
                        pendingRelease = GitHubReleaseInfo(
                            version: cleanTag,
                            htmlURL: htmlURL,
                            body: (json["body"] as? String) ?? ""
                        )
                    } else {
                        isUpToDate = true
                        statusMessage = L("You're up to date (v\(currentVersion))")
                    }
                } else {
                    isUpToDate = true
                    statusMessage = L("You're up to date (v\(currentVersion))")
                }
            } catch {
                isUpToDate = true
                statusMessage = L("You're up to date (v\(currentVersion))")
            }
        }
    }
}
