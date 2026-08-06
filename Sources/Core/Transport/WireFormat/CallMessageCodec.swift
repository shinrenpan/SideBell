import Foundation

/// wire format 的編解碼失敗原因。
///
/// 全部以 `throws` 表達而非可選值或布林值——解碼失敗若能被忽略，
/// 症狀會是「偶爾收不到呼叫」，那是本專案最難追的失敗模式。
nonisolated enum WireFormatError: Error, Equatable, Sendable {
    /// 封包長度、宣告長度或內容編碼不合法。
    case malformedFrame
    /// 版本位元組非本實作支援的版本。與 `malformedFrame` 分開，
    /// 讓未來的版本協商能區分「壞掉的封包」與「比較新的對端」。
    case unsupportedVersion(UInt8)
    /// 標題超過 100 位元組上限。在編碼前拒絕，不截斷後送出。
    case titleTooLong(byteCount: Int)
    /// 指令代碼超過 8 位元組上限。
    case commandCodeTooLong(byteCount: Int)
    /// 指令代碼含非 ASCII 位元組。
    case commandCodeNotASCII
    /// 時間戳超出 UInt32 epoch 秒可表達的範圍。
    case timestampOutOfRange
}

/// 呼叫訊息與確認的緊湊二進位編解碼器。
///
/// 全部為不接觸任何隔離狀態的純函式，因此標注 `nonisolated`——
/// 本模組預設 MainActor 隔離，但編解碼會在 Bluetooth 回呼與測試中直接呼叫。
nonisolated enum CallMessageCodec {
    /// wire format 版本。
    static let version: UInt8 = 1
    /// 固定前綴長度：version(1) + flags(1) + id(16) + timestamp(4) + commandCode(8) + titleLen(1)。
    static let fixedPrefixSize = 31
    static let maxTitleByteCount = 100
    static let commandCodeSize = 8
    /// 單一封包上限，據此確保不需要分片。
    static let maxFrameSize = fixedPrefixSize + maxTitleByteCount
    /// 確認封包長度：僅 16 位元組的呼叫識別碼，無標頭。
    static let ackSize = 16

    private enum Offset {
        static let version = 0
        static let flags = 1
        static let id = 2
        static let timestamp = 18
        static let commandCode = 22
        static let titleLength = 30
        static let title = 31
    }

    private static let urgentFlagMask: UInt8 = 0x01
}

// MARK: - 呼叫訊息

extension CallMessageCodec {
    static func encode(_ message: CallMessage) throws -> Data {
        let titleBytes = Data(message.title.utf8)
        guard titleBytes.count <= maxTitleByteCount else {
            throw WireFormatError.titleTooLong(byteCount: titleBytes.count)
        }

        let commandBytes = Data(message.commandCode.utf8)
        guard commandBytes.count <= commandCodeSize else {
            throw WireFormatError.commandCodeTooLong(byteCount: commandBytes.count)
        }
        guard commandBytes.allSatisfy({ $0 < 0x80 }) else {
            throw WireFormatError.commandCodeNotASCII
        }

        let seconds = message.timestamp.timeIntervalSince1970.rounded(.down)
        guard seconds >= 0, let epochSeconds = UInt32(exactly: seconds) else {
            throw WireFormatError.timestampOutOfRange
        }

        var frame = Data()
        frame.reserveCapacity(fixedPrefixSize + titleBytes.count)
        frame.append(version)
        frame.append(message.isUrgent ? urgentFlagMask : 0x00)
        frame.append(contentsOf: withUnsafeBytes(of: message.id.uuid) { Array($0) })
        frame.append(contentsOf: withUnsafeBytes(of: epochSeconds.littleEndian) { Array($0) })
        frame.append(commandBytes)
        frame.append(contentsOf: Array(repeating: 0x00, count: commandCodeSize - commandBytes.count))
        frame.append(UInt8(titleBytes.count))
        frame.append(titleBytes)

        return frame
    }

    static func decode(_ data: Data) throws -> CallMessage {
        // 正規化為零起始索引。BLE 交來的 payload 常是 slice，
        // 直接用原始索引存取是這類編解碼器最典型的越界來源。
        let bytes = Data(data)

        guard bytes.count >= fixedPrefixSize, bytes.count <= maxFrameSize else {
            throw WireFormatError.malformedFrame
        }

        let frameVersion = bytes[Offset.version]
        guard frameVersion == version else {
            throw WireFormatError.unsupportedVersion(frameVersion)
        }

        let titleLength = Int(bytes[Offset.titleLength])
        guard titleLength <= maxTitleByteCount else {
            throw WireFormatError.malformedFrame
        }
        // 同時擋掉截斷（宣告長度大於實際）與尾端夾帶（實際大於宣告）。
        guard bytes.count == fixedPrefixSize + titleLength else {
            throw WireFormatError.malformedFrame
        }

        let isUrgent = bytes[Offset.flags] & urgentFlagMask != 0

        let id = try decodeUUID(from: bytes, at: Offset.id)

        let epochSeconds = bytes[Offset.timestamp..<(Offset.timestamp + 4)]
            .reversed()
            .reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }

        let commandCode = try decodeCommandCode(from: bytes)

        let titleBytes = bytes[Offset.title..<(Offset.title + titleLength)]
        guard let title = String(data: titleBytes, encoding: .utf8) else {
            throw WireFormatError.malformedFrame
        }

        return CallMessage(
            id: id,
            commandCode: commandCode,
            title: title,
            isUrgent: isUrgent,
            timestamp: Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        )
    }
}

// MARK: - 確認

extension CallMessageCodec {
    static func encodeAck(_ callID: UUID) -> Data {
        Data(withUnsafeBytes(of: callID.uuid) { Array($0) })
    }

    static func decodeAck(_ data: Data) throws -> UUID {
        let bytes = Data(data)
        guard bytes.count == ackSize else {
            throw WireFormatError.malformedFrame
        }
        return try decodeUUID(from: bytes, at: 0)
    }
}

// MARK: - 私有輔助

private extension CallMessageCodec {
    static func decodeUUID(from bytes: Data, at offset: Int) throws -> UUID {
        guard bytes.count >= offset + 16 else {
            throw WireFormatError.malformedFrame
        }
        let b = Array(bytes[offset..<(offset + 16)])
        return UUID(
            uuid: (
                b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]
            )
        )
    }

    /// 讀取 8 位元組指令代碼欄位。
    ///
    /// 右側填充區必須全為 0x00：容忍填充區夾帶資料等於開一條旁通道，
    /// 讓偽造者能在看似合法的封包裡藏內容。
    static func decodeCommandCode(from bytes: Data) throws -> String {
        let field = Array(bytes[Offset.commandCode..<(Offset.commandCode + commandCodeSize)])
        let contentLength = field.firstIndex(of: 0x00) ?? field.count

        guard field[contentLength...].allSatisfy({ $0 == 0x00 }) else {
            throw WireFormatError.malformedFrame
        }
        let content = field[..<contentLength]
        guard content.allSatisfy({ $0 < 0x80 }) else {
            throw WireFormatError.malformedFrame
        }
        guard let code = String(bytes: content, encoding: .utf8) else {
            throw WireFormatError.malformedFrame
        }
        return code
    }
}
