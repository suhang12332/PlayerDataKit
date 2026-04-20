import Foundation

/// Minecraft NBT 解析（只读），用于 `level.dat` 等 GZIP 压缩的 Compound 根文件。
final class NBTParser {
    private var data: Data
    private var offset: Int = 0

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> [String: Any] {
        var payload = data
        if payload.count >= 2, payload[0] == 0x1F, payload[1] == 0x8B {
            payload = try Gzip.decompressIfNeeded(payload)
        }
        offset = 0
        self.data = payload

        guard !data.isEmpty else { throw PlayerDataKitError.nbtEmptyData }

        let tagType = NBTType(rawValue: data[offset]) ?? .end
        guard tagType == .compound else { throw PlayerDataKitError.nbtInvalidRoot }
        offset += 1
        _ = try readString()
        return try readCompound() as [String: Any]
    }

    private func readString() throws -> String {
        guard offset + 2 <= data.count else { throw PlayerDataKitError.nbtInsufficientData }
        let length = Int(readShort())
        guard offset + length <= data.count else { throw PlayerDataKitError.nbtStringOutOfRange }
        let stringData = data.subdata(in: offset..<(offset + length))
        offset += length
        return String(data: stringData, encoding: .utf8) ?? ""
    }

    private func readShort() -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        let value = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        return value
    }

    private func readInt() -> Int32 {
        guard offset + 4 <= data.count else { return 0 }
        var value: Int32 = 0
        for i in 0..<4 {
            value = (value << 8) | Int32(data[offset + i])
        }
        offset += 4
        return value
    }

    private func readByte() -> UInt8 {
        guard offset < data.count else { return 0 }
        let value = data[offset]
        offset += 1
        return value
    }

    private func readCompound() throws -> [String: Any] {
        var result: [String: Any] = [:]
        while offset < data.count {
            let tagType = NBTType(rawValue: data[offset]) ?? .end
            offset += 1
            if tagType == .end { break }
            let name = try readString()
            let value = try readTagValue(type: tagType)
            result[name] = value
        }
        return result
    }

    private func readTagValue(type: NBTType) throws -> Any {
        switch type {
        case .byte:
            return Int8(bitPattern: readByte())
        case .short:
            return Int16(bitPattern: readShort())
        case .int:
            return readInt()
        case .long:
            return readLong()
        case .float:
            return readFloat()
        case .double:
            return readDouble()
        case .string:
            return try readString()
        case .list:
            return try readList()
        case .compound:
            return try readCompound()
        case .byteArray:
            let length = Int(readInt())
            guard offset + length <= data.count else { throw PlayerDataKitError.nbtByteArrayOutOfRange }
            let array = Array(data.subdata(in: offset..<(offset + length)))
            offset += length
            return array
        case .intArray:
            let length = Int(readInt())
            var array: [Int32] = []
            for _ in 0..<length { array.append(readInt()) }
            return array
        case .longArray:
            let length = Int(readInt())
            var array: [Int64] = []
            for _ in 0..<length { array.append(readLong()) }
            return array
        case .end:
            throw PlayerDataKitError.nbtUnexpectedEndTag
        }
    }

    private func readLong() -> Int64 {
        guard offset + 8 <= data.count else { return 0 }
        var value: Int64 = 0
        for i in 0..<8 {
            value = (value << 8) | Int64(data[offset + i])
        }
        offset += 8
        return value
    }

    private func readFloat() -> Float {
        guard offset + 4 <= data.count else { return 0 }
        let intValue = readInt()
        return Float(bitPattern: UInt32(bitPattern: intValue))
    }

    private func readDouble() -> Double {
        guard offset + 8 <= data.count else { return 0 }
        let longValue = readLong()
        return Double(bitPattern: UInt64(bitPattern: longValue))
    }

    private func readList() throws -> [Any] {
        guard offset < data.count else { throw PlayerDataKitError.nbtInsufficientData }
        let listType = NBTType(rawValue: data[offset]) ?? .end
        offset += 1
        let length = Int(readInt())
        var result: [Any] = []
        for _ in 0..<length {
            let value = try readTagValue(type: listType)
            result.append(value)
        }
        return result
    }
}

private enum NBTType: UInt8 {
    case end = 0
    case byte = 1
    case short = 2
    case int = 3
    case long = 4
    case float = 5
    case double = 6
    case byteArray = 7
    case string = 8
    case list = 9
    case compound = 10
    case intArray = 11
    case longArray = 12
}

