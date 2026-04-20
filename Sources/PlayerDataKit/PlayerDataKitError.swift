import Foundation

enum PlayerDataKitError: Error, Sendable {
    case nbtEmptyData
    case nbtInvalidRoot
    case nbtInsufficientData
    case nbtStringOutOfRange
    case nbtByteArrayOutOfRange
    case nbtUnexpectedEndTag
    case nbtGzipEmpty
    case nbtDecompressionFailed
}

extension PlayerDataKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .nbtEmptyData:
            return PDKL10n.string("error.nbt.emptyData")
        case .nbtInvalidRoot:
            return PDKL10n.string("error.nbt.invalidRoot")
        case .nbtInsufficientData:
            return PDKL10n.string("error.nbt.insufficientData")
        case .nbtStringOutOfRange:
            return PDKL10n.string("error.nbt.stringOutOfRange")
        case .nbtByteArrayOutOfRange:
            return PDKL10n.string("error.nbt.byteArrayOutOfRange")
        case .nbtUnexpectedEndTag:
            return PDKL10n.string("error.nbt.unexpectedEndTag")
        case .nbtGzipEmpty:
            return PDKL10n.string("error.nbt.gzipEmpty")
        case .nbtDecompressionFailed:
            return PDKL10n.string("error.nbt.decompressionFailed")
        }
    }
}
