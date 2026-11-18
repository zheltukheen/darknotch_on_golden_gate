import Foundation

/// UI strings loaded from Resources/i18n/<language>.json.
/// Falls back to English when the system language has no file.
enum L10n {
    private static let languageCode: String = resolveLanguage()
    private static let strings: [String: String] = load(languageCode)
    private static let english: [String: String] = load("en")

    static func t(_ key: String, _ args: CVarArg...) -> String {
        let format = strings[key] ?? english[key] ?? key
        guard !args.isEmpty else { return format }
        return String(format: format, arguments: args)
    }

    private static func resolveLanguage() -> String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        var parts = preferred.split(separator: "-").map(String.init)
        var candidates: [String] = []
        while !parts.isEmpty {
            candidates.append(parts.joined(separator: "-"))
            parts.removeLast()
        }
        candidates.append("en")
        return candidates.first { fileExists($0) } ?? "en"
    }

    private static func fileExists(_ code: String) -> Bool {
        Bundle.main.url(forResource: code, withExtension: "json", subdirectory: "i18n") != nil
    }

    private static func load(_ code: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: code, withExtension: "json", subdirectory: "i18n"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = root["strings"] as? [String: String]
        else { return [:] }
        return strings
    }
}
