import Foundation

enum L10n {
    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        let format = String(localized: String.LocalizationValue(key))
        return String(format: format, locale: .current, arguments: args)
    }
}
