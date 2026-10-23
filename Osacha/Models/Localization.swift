//
//  Localization.swift
//  Osacha
//
//  Switches the app between English and Japanese while it runs. iOS only
//  picks an app's language at launch, so the main bundle is pointed at the
//  chosen translations instead: `Text("…")` then finds them by itself, and
//  text built outside a view goes through `localized(_:)`.
//

import Foundation

extension AppLanguage {
    /// The language the app is showing. Mirrors the session's setting so
    /// model code, which has no view environment, can follow it too.
    static var current: AppLanguage = .english

    var code: String {
        switch self {
        case .english: return "en"
        case .japanese: return "ja"
        }
    }

    var locale: Locale { Locale(identifier: code) }

    /// The compiled translations for this language.
    fileprivate var bundle: Bundle? {
        Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:))
    }
}

extension Bundle {
    /// Sends the main bundle's string lookups to the chosen language from now
    /// on. Called once at launch.
    static func followAppLanguage() {
        object_setClass(Bundle.main, AppLanguageBundle.self)
    }
}

/// The main bundle, answering string lookups from the chosen language's
/// translations. A key with no entry comes back as itself, which is already
/// its English text.
private final class AppLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = AppLanguage.current.bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

/// `key` in the app's chosen language, for text built outside a view.
func localized(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

/// Dates written the way the chosen language writes them. Each pattern is
/// fixed rather than left to the device, whose 12/24-hour setting would
/// otherwise override it.
enum AppDate {
    /// "Oct 23, 8:45 PM" or "10月23日 20:45".
    static func dayAndTime(_ date: Date) -> String {
        format(date, english: "MMM d, h:mm a", japanese: "M月d日 H:mm")
    }

    /// "8:45 PM" or "20:45".
    static func time(_ date: Date) -> String {
        format(date, english: "h:mm a", japanese: "H:mm")
    }

    /// "Oct 23" or "10月23日".
    static func day(_ date: Date) -> String {
        format(date, english: "MMM d", japanese: "M月d日")
    }

    private static var formatters: [String: DateFormatter] = [:]

    private static func format(_ date: Date, english: String, japanese: String) -> String {
        let language = AppLanguage.current
        let pattern = language == .japanese ? japanese : english
        let key = language.code + pattern
        if let formatter = formatters[key] { return formatter.string(from: date) }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .japanese ? "ja_JP" : "en_US_POSIX")
        formatter.dateFormat = pattern
        formatters[key] = formatter
        return formatter.string(from: date)
    }
}
