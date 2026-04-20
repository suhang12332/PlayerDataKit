import Foundation

enum PDKL10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(
            key,
            tableName: nil,
            bundle: .module,
            value: key,
            comment: ""
        )
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale.current,
            arguments: args
        )
    }
}
