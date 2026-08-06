import Foundation
import Testing

@testable import SideBell

// 測試案例直接取自 openspec 的 `call-wire-format` spec 中的 Example 表格，
// 不自行增補案例——那些值是規格的一部分。

@Suite("CallMessage 二進位編碼")
struct CallMessageEncodingTests {
    /// spec: Encoding a normal call — 欄位偏移量表
    @Test("欄位偏移量與內容符合 wire format")
    func fieldOffsets() throws {
        let id = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!
        let timestamp = Date(timeIntervalSince1970: 1_754_000_000)
        let message = CallMessage(
            id: id,
            commandCode: "WATER",
            title: "喝水",
            isUrgent: false,
            timestamp: timestamp
        )

        let frame = try CallMessageCodec.encode(message)

        #expect(frame.count == 37)  // 31 位元組固定前綴 + 「喝水」的 6 位元組

        #expect(frame[0] == 0x01)  // version
        #expect(frame[1] == 0x00)  // flags：非緊急

        let idBytes = frame[2..<18]
        #expect(Array(idBytes) == Array(withUnsafeBytes(of: id.uuid) { Data($0) }))

        let timestampBytes = frame[18..<22]
        let expectedSeconds = UInt32(timestamp.timeIntervalSince1970)
        #expect(Array(timestampBytes) == Array(withUnsafeBytes(of: expectedSeconds.littleEndian) { Data($0) }))

        let commandBytes = Array(frame[22..<30])
        #expect(commandBytes == [0x57, 0x41, 0x54, 0x45, 0x52, 0x00, 0x00, 0x00])

        #expect(frame[30] == 0x06)  // titleLen

        let titleBytes = Data(frame[31...])
        #expect(String(data: titleBytes, encoding: .utf8) == "喝水")
    }

    /// spec: Encoding an urgent call
    @Test("緊急旗標寫入 flags 的 bit 0")
    func urgentFlag() throws {
        let frame = try CallMessageCodec.encode(
            CallMessage(id: UUID(), commandCode: "TURN", title: "翻身", isUrgent: true, timestamp: .init())
        )
        #expect(frame[1] & 0x01 == 0x01)
    }

    /// spec: Command code shorter than eight bytes
    @Test("指令代碼不足八位元組時以 0x00 右補齊")
    func commandCodePadding() throws {
        let frame = try CallMessageCodec.encode(
            CallMessage(id: UUID(), commandCode: "SOS", title: "", isUrgent: false, timestamp: .init())
        )
        #expect(Array(frame[22..<30]) == [0x53, 0x4F, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00])
    }

    /// design 的 Implementation Contract：逾長標題在編碼前即拒絕，不得截斷後送出
    @Test("標題超過 100 位元組時在編碼前拋錯而非截斷")
    func overlongTitleRejected() {
        let message = CallMessage(
            id: UUID(),
            commandCode: "HELP",
            title: String(repeating: "A", count: 101),
            isUrgent: false,
            timestamp: .init()
        )
        #expect(throws: WireFormatError.self) {
            _ = try CallMessageCodec.encode(message)
        }
    }

    @Test("指令代碼超過八位元組時拋錯")
    func overlongCommandCodeRejected() {
        let message = CallMessage(
            id: UUID(),
            commandCode: "TOOLONGCODE",
            title: "",
            isUrgent: false,
            timestamp: .init()
        )
        #expect(throws: WireFormatError.self) {
            _ = try CallMessageCodec.encode(message)
        }
    }
}

@Suite("CallMessage 二進位解碼")
struct CallMessageDecodingTests {
    /// spec: Round-trip preserves every field — 四組案例
    @Test(
        "round-trip 保留每個欄位",
        arguments: [
            (title: "喝水", command: "WATER", urgent: false, expectedSize: 37),
            (title: "翻身", command: "TURN", urgent: true, expectedSize: 37),
            (title: String(repeating: "A", count: 100), command: "HELP", urgent: true, expectedSize: 131),
            (title: "", command: "PING", urgent: false, expectedSize: 31),
        ]
    )
    func roundTrip(title: String, command: String, urgent: Bool, expectedSize: Int) throws {
        let original = CallMessage(
            id: UUID(),
            commandCode: command,
            title: title,
            isUrgent: urgent,
            timestamp: Date(timeIntervalSince1970: 1_754_000_000)
        )

        let frame = try CallMessageCodec.encode(original)
        #expect(frame.count == expectedSize)

        let decoded = try CallMessageCodec.decode(frame)
        #expect(decoded == original)
    }

    /// wire format 的時間戳為整秒，次秒精度不保證保留
    @Test("時間戳 round-trip 後截斷至整秒")
    func timestampTruncatedToWholeSeconds() throws {
        let original = CallMessage(
            id: UUID(),
            commandCode: "WATER",
            title: "喝水",
            isUrgent: false,
            timestamp: Date(timeIntervalSince1970: 1_754_000_000.75)
        )

        let decoded = try CallMessageCodec.decode(try CallMessageCodec.encode(original))
        #expect(decoded.timestamp.timeIntervalSince1970 == 1_754_000_000)
    }

    /// 解碼必須能處理 startIndex 非 0 的 Data slice（BLE 回傳的 payload 常是 slice）
    @Test("非零起始索引的 Data slice 可正確解碼")
    func decodesFromNonZeroIndexedSlice() throws {
        let original = CallMessage(
            id: UUID(),
            commandCode: "WATER",
            title: "喝水",
            isUrgent: false,
            timestamp: Date(timeIntervalSince1970: 1_754_000_000)
        )
        let frame = try CallMessageCodec.encode(original)
        let padded = Data([0xFF, 0xFF]) + frame
        let slice = padded[2...]

        #expect(slice.startIndex != 0)
        #expect(try CallMessageCodec.decode(slice) == original)
    }
}

@Suite("畸形封包防禦")
struct MalformedFrameDefenseTests {
    /// 產生一份合法 frame，供各拒絕案例改寫個別位元組。
    private static func validFrame(title: String = "喝水") throws -> Data {
        try CallMessageCodec.encode(
            CallMessage(
                id: UUID(),
                commandCode: "WATER",
                title: title,
                isUrgent: false,
                timestamp: Date(timeIntervalSince1970: 1_754_000_000)
            )
        )
    }

    /// spec: Truncated frame is rejected
    @Test("短於 31 位元組固定前綴的封包被拒絕且不崩潰")
    func truncatedFrameRejected() {
        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(Data())
        }
        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(Data(repeating: 0x00, count: 30))
        }
    }

    /// spec: rejection cases —— 宣告長度與實際位元組不符
    @Test("宣告的標題長度與實際位元組不符時被拒絕")
    func titleLengthMismatchRejected() throws {
        var frame = try Self.validFrame()
        frame = frame.prefix(31)  // 砍掉標題本體
        frame[30] = 10  // 仍宣告有 10 位元組標題

        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(frame)
        }
    }

    /// spec: rejection cases —— titleLen 超過 100 上限
    @Test("宣告的標題長度超過 100 時被拒絕")
    func titleLengthAboveLimitRejected() throws {
        var frame = try Self.validFrame(title: String(repeating: "A", count: 100))
        frame[30] = 101

        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(frame)
        }
    }

    /// spec: Unknown version is rejected —— 與 malformedFrame 可區分
    @Test("未知版本回傳可區分的錯誤")
    func unknownVersionRejected() throws {
        var frame = try Self.validFrame()
        frame[0] = 0x02

        #expect(throws: WireFormatError.unsupportedVersion(2)) {
            _ = try CallMessageCodec.decode(frame)
        }
    }

    /// spec: rejection cases —— 非法 UTF-8 標題
    @Test("標題並非合法 UTF-8 時被拒絕")
    func invalidUTF8TitleRejected() throws {
        var frame = try Self.validFrame()
        frame[31] = 0xFF  // 0xFF 不可能出現在合法 UTF-8 序列中
        frame[32] = 0xFE

        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(frame)
        }
    }

    /// spec: rejection cases —— 總長超過 131 位元組上限
    @Test("超過 131 位元組上限的封包被拒絕")
    func overlongFrameRejected() {
        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(Data(repeating: 0x01, count: 132))
        }
    }

    /// spec: Trailing padding is rejected rather than ignored
    @Test("宣告長度之後的多餘位元組被拒絕而非忽略")
    func trailingPaddingRejected() throws {
        let frame = try Self.validFrame() + Data([0x00, 0x00])

        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decode(frame)
        }
    }
}

@Suite("確認封包")
struct AcknowledgementPayloadTests {
    /// spec: Acknowledgement round-trip
    @Test("確認封包為 16 位元組且可還原原始識別碼")
    func ackRoundTrip() throws {
        let callID = UUID()
        let payload = CallMessageCodec.encodeAck(callID)

        #expect(payload.count == 16)
        #expect(try CallMessageCodec.decodeAck(payload) == callID)
    }

    /// spec: Wrong-length acknowledgement is rejected
    @Test("長度非 16 位元組的確認封包被拒絕", arguments: [0, 15, 17, 32])
    func wrongLengthAckRejected(byteCount: Int) {
        #expect(throws: WireFormatError.malformedFrame) {
            _ = try CallMessageCodec.decodeAck(Data(repeating: 0x00, count: byteCount))
        }
    }

    @Test("非零起始索引的確認封包 slice 可正確解碼")
    func ackDecodesFromNonZeroIndexedSlice() throws {
        let callID = UUID()
        let padded = Data([0xFF]) + CallMessageCodec.encodeAck(callID)

        #expect(try CallMessageCodec.decodeAck(padded[1...]) == callID)
    }
}
