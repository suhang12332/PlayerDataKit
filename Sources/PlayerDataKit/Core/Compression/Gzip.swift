import Foundation
import Darwin

#if canImport(zlib)
import zlib
#endif

enum Gzip {
    static func decompressIfNeeded(_ data: Data) throws -> Data {
        guard data.count >= 2, data[0] == 0x1F, data[1] == 0x8B else {
            return data
        }
        #if canImport(zlib)
        return try gunzip(data)
        #else
        throw PlayerDataKitError.nbtDecompressionFailed
        #endif
    }

    #if canImport(zlib)
    private static func gunzip(_ data: Data) throws -> Data {
        guard !data.isEmpty else { throw PlayerDataKitError.nbtGzipEmpty }

        var stream = z_stream()
        memset(&stream, 0, MemoryLayout<z_stream>.size)

        let initCode = inflateInit2_(
            &stream,
            MAX_WBITS + 16,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initCode == Z_OK else {
            throw PlayerDataKitError.nbtDecompressionFailed
        }
        defer { inflateEnd(&stream) }

        var output = Data(capacity: data.count * 4)
        let chunkSize = 65_536
        var buffer = [UInt8](repeating: 0, count: chunkSize)

        try data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.bindMemory(to: Bytef.self).baseAddress else {
                throw PlayerDataKitError.nbtInsufficientData
            }
            stream.next_in = UnsafeMutablePointer(mutating: base)
            stream.avail_in = uInt(data.count)

            var status: Int32
            repeat {
                status = buffer.withUnsafeMutableBytes { outRaw in
                    guard let outBase = outRaw.bindMemory(to: Bytef.self).baseAddress else {
                        return Z_BUF_ERROR
                    }
                    stream.next_out = outBase
                    stream.avail_out = uInt(chunkSize)
                    return inflate(&stream, Z_NO_FLUSH)
                }
                let produced = chunkSize - Int(stream.avail_out)
                if produced > 0 {
                    output.append(buffer, count: produced)
                }
            } while status == Z_OK

            guard status == Z_STREAM_END else {
                throw PlayerDataKitError.nbtDecompressionFailed
            }
        }

        guard !output.isEmpty else { throw PlayerDataKitError.nbtGzipEmpty }
        return output
    }
    #endif
}

