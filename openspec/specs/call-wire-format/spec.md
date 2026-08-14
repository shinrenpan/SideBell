# call-wire-format Specification

## Purpose

TBD - created by archiving change 'add-project-skeleton-and-ble-poc'. Update Purpose after archive.

## Requirements

### Requirement: Call message binary encoding

The system SHALL encode a call message into a compact little-endian binary frame with a fixed 31-byte prefix followed by a variable-length title, so that a single call always fits in one BLE notification without fragmentation.

The frame layout SHALL be: version (UInt8), flags (UInt8), id (16 raw UUID bytes), timestamp (UInt32 epoch seconds), commandCode (8 ASCII bytes right-padded with 0x00), titleLen (UInt8), title (titleLen UTF-8 bytes). Total frame size SHALL NOT exceed 131 bytes. Bit 0 of flags SHALL carry the urgent marker; all other bits SHALL be zero on encode.

#### Scenario: Encoding a normal call

- **WHEN** a call message with a title, a command code, and urgent set to false is encoded
- **THEN** the resulting frame SHALL be 31 bytes plus the UTF-8 byte count of the title, SHALL start with version byte 1, and SHALL have flags byte 0x00

##### Example: field offsets of an encoded frame

| Field | Offset | Length | Value for a "喝水" / "WATER" non-urgent call |
| ----- | ------ | ------ | ------------------------------------------- |
| version | 0 | 1 | 0x01 |
| flags | 1 | 1 | 0x00 |
| id | 2 | 16 | raw UUID bytes |
| timestamp | 18 | 4 | epoch seconds, little-endian |
| commandCode | 22 | 8 | 0x57 0x41 0x54 0x45 0x52 0x00 0x00 0x00 |
| titleLen | 30 | 1 | 0x06 |
| title | 31 | 6 | UTF-8 bytes of 喝水 |

#### Scenario: Encoding an urgent call

- **WHEN** a call message with urgent set to true is encoded
- **THEN** bit 0 of the flags byte SHALL be 1

#### Scenario: Command code shorter than eight bytes

- **WHEN** a call message whose command code is fewer than 8 ASCII characters is encoded
- **THEN** the command code field SHALL be right-padded with 0x00 to exactly 8 bytes


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/App/Info.plist
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Tests/RoleTests/RoleStoreTests.swift
  - Tests/WireFormatTests/CallMessageCodecTests.swift
  - Sources/Core/Role/RoleStore.swift
  - Sources/Core/Transport/BLE/SideBellGATT.swift
  - .spectra.yaml
  - docs/device-verification/w1-ble-poc.md
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Core/Transport/WireFormat/CallMessageCodec.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/Role/AppRole.swift
  - project.yml
  - Sources/App/AppDelegate.swift
  - Sources/Core/CallCenter.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Core/Transport/TransportEvent.swift
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - DECISIONS.md
-->

---
### Requirement: Call message binary decoding

The system SHALL decode a well-formed binary frame back into a call message whose field values equal those of the message that produced the frame.

#### Scenario: Round-trip preserves every field

- **WHEN** a call message is encoded and the resulting frame is decoded
- **THEN** the decoded message SHALL have the same id, urgent marker, command code, title, and timestamp truncated to whole seconds as the original

##### Example: round-trip cases

| Title | Command code | Urgent | Round-trip result |
| ----- | ------------ | ------ | ----------------- |
| "喝水" | "WATER" | false | all fields equal |
| "翻身" | "TURN" | true | all fields equal, urgent preserved |
| 100-byte UTF-8 title | "HELP" | true | all fields equal, frame is exactly 131 bytes |
| "" | "PING" | false | empty title preserved, frame is exactly 31 bytes |

#### Scenario: Trailing padding is rejected rather than ignored

- **WHEN** a frame carries more bytes after the declared title length
- **THEN** decoding SHALL fail with a malformed-frame error


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/App/Info.plist
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Tests/RoleTests/RoleStoreTests.swift
  - Tests/WireFormatTests/CallMessageCodecTests.swift
  - Sources/Core/Role/RoleStore.swift
  - Sources/Core/Transport/BLE/SideBellGATT.swift
  - .spectra.yaml
  - docs/device-verification/w1-ble-poc.md
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Core/Transport/WireFormat/CallMessageCodec.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/Role/AppRole.swift
  - project.yml
  - Sources/App/AppDelegate.swift
  - Sources/Core/CallCenter.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Core/Transport/TransportEvent.swift
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - DECISIONS.md
-->

---
### Requirement: Malformed frame defense

The system SHALL reject any frame that is truncated, over-length, carries an unknown version, or declares a title length inconsistent with the remaining bytes. Decoding SHALL return a typed failure and SHALL NOT crash, trap, or read outside the received buffer.

#### Scenario: Truncated frame is rejected

- **WHEN** a frame shorter than the 31-byte fixed prefix is decoded
- **THEN** decoding SHALL fail with a malformed-frame error and SHALL NOT crash

#### Scenario: Unknown version is rejected

- **WHEN** a frame whose version byte is not 1 is decoded
- **THEN** decoding SHALL fail with an unsupported-version error, distinguishable from a malformed-frame error

##### Example: rejection cases

| Input | Expected result |
| ----- | --------------- |
| empty data | malformed-frame error |
| 30 bytes | malformed-frame error |
| 31-byte prefix with titleLen 10 but no title bytes | malformed-frame error |
| 31-byte prefix with titleLen 101 | malformed-frame error |
| valid frame with version byte 2 | unsupported-version error |
| valid frame with title bytes that are not valid UTF-8 | malformed-frame error |
| 132 bytes | malformed-frame error |


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/App/Info.plist
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Tests/RoleTests/RoleStoreTests.swift
  - Tests/WireFormatTests/CallMessageCodecTests.swift
  - Sources/Core/Role/RoleStore.swift
  - Sources/Core/Transport/BLE/SideBellGATT.swift
  - .spectra.yaml
  - docs/device-verification/w1-ble-poc.md
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Core/Transport/WireFormat/CallMessageCodec.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/Role/AppRole.swift
  - project.yml
  - Sources/App/AppDelegate.swift
  - Sources/Core/CallCenter.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Core/Transport/TransportEvent.swift
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - DECISIONS.md
-->

---
### Requirement: Acknowledgement payload

The system SHALL represent an acknowledgement as exactly the 16 raw bytes of the acknowledged call id, with no header and no additional fields.

#### Scenario: Acknowledgement round-trip

- **WHEN** an acknowledgement for a known call id is encoded and decoded
- **THEN** the decoded call id SHALL equal the original and the encoded payload SHALL be exactly 16 bytes

#### Scenario: Wrong-length acknowledgement is rejected

- **WHEN** an acknowledgement payload whose length is not 16 bytes is decoded
- **THEN** decoding SHALL fail with a malformed-frame error

<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/App/Info.plist
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Tests/RoleTests/RoleStoreTests.swift
  - Tests/WireFormatTests/CallMessageCodecTests.swift
  - Sources/Core/Role/RoleStore.swift
  - Sources/Core/Transport/BLE/SideBellGATT.swift
  - .spectra.yaml
  - docs/device-verification/w1-ble-poc.md
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Core/Transport/WireFormat/CallMessageCodec.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/Role/AppRole.swift
  - project.yml
  - Sources/App/AppDelegate.swift
  - Sources/Core/CallCenter.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Core/Transport/TransportEvent.swift
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - DECISIONS.md
-->