# call-transport Specification

## Purpose

TBD - created by archiving change 'add-project-skeleton-and-ble-poc'. Update Purpose after archive.

## Requirements

### Requirement: Transport contract isolates core logic from Core Bluetooth

The system SHALL expose call delivery to core logic through a transport contract offering exactly four concerns: starting the transport in a given role, sending a call, acknowledging a call, and observing connection state and inbound events. No type outside the transport module SHALL reference Core Bluetooth types.

#### Scenario: Core logic compiles without Core Bluetooth

- **WHEN** the project is built
- **THEN** no source file outside the transport module SHALL import Core Bluetooth

#### Scenario: Transport is selected by role at start

- **WHEN** the transport is started in the patient role
- **THEN** the device SHALL advertise the SideBell call service and SHALL NOT scan for other devices
- **AND WHEN** the transport is started in the caregiver role
- **THEN** the device SHALL scan for the SideBell call service and SHALL NOT advertise it


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Automatic pairing without a manual device-selection flow

The system SHALL discover and connect the paired role counterpart without presenting a device picker or requiring the user to enter a code. Caregiver-side scanning SHALL always filter by the SideBell service identifier and SHALL NOT scan for all peripherals.

#### Scenario: Caregiver connects to an advertising patient

- **WHEN** a caregiver device starts the transport while a patient device is advertising within range
- **THEN** the caregiver SHALL connect without any user interaction beyond the system pairing prompt, and both sides SHALL report a connected state


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Long-lived connection rather than repeated scanning

The system SHALL hold the connection open once established, and SHALL NOT poll, disconnect on idle, or re-scan while a connection is live.

#### Scenario: Connection persists across an idle period

- **WHEN** a connected pair sits idle for thirty minutes with no calls sent
- **THEN** both sides SHALL still report a connected state and the next call SHALL be delivered without a reconnection delay


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Call delivery while the caregiver app is backgrounded

The system SHALL deliver a call to a caregiver device whose app is backgrounded and whose screen is locked, and SHALL surface the call to the caregiver app within the wake window the system grants.

#### Scenario: Locked-screen delivery

- **WHEN** a patient sends a call while the caregiver device is locked and the caregiver app has been in the background for at least thirty minutes
- **THEN** the caregiver app SHALL receive the call and SHALL record it as received, with the received timestamp reflecting the moment of delivery rather than the moment the app was next opened


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Acknowledgement closes the loop to the patient

The system SHALL let a caregiver acknowledge a received call by its call id, and SHALL surface that acknowledgement to the originating patient device.

#### Scenario: Acknowledgement reaches the patient

- **WHEN** a caregiver acknowledges a received call
- **THEN** the patient device SHALL observe an acknowledgement event carrying the same call id it sent

#### Scenario: Acknowledgement for an unknown call id is ignored

- **WHEN** a patient device receives an acknowledgement whose call id matches no call it sent
- **THEN** the patient SHALL discard it without changing any call state and SHALL NOT surface an error to the user


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Automatic reconnection after range loss

The system SHALL re-establish the connection without user action after the peer leaves and re-enters range, by issuing a connection request immediately on disconnect and letting the system hold that intent.

#### Scenario: Peer leaves and returns

- **WHEN** a connected patient device is carried out of range until the caregiver reports a disconnected state, and is later brought back into range
- **THEN** the caregiver SHALL return to a connected state without the user reopening or interacting with either app


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Recovery after system termination

The system SHALL register both roles for Bluetooth state restoration, so that a Bluetooth event can relaunch the app in the background after the system terminated it under memory pressure, and SHALL rebuild its transport state during that relaunch rather than starting from an empty state.

#### Scenario: System-terminated caregiver app is revived by an incoming call

- **WHEN** the caregiver app has been terminated by the system, not by the user, and a patient sends a call
- **THEN** the caregiver app SHALL be relaunched in the background and SHALL receive the call

#### Scenario: User-terminated app is not expected to revive

- **WHEN** the user terminates the app from the app switcher
- **THEN** the system SHALL NOT be expected to relaunch it, and this SHALL be treated as a platform constraint rather than a defect


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Encrypted characteristics reject unpaired peers

The system SHALL declare every SideBell characteristic as requiring encryption, so that reads, writes and subscriptions from an unbonded device are refused at the GATT layer.

#### Scenario: First connection triggers system pairing

- **WHEN** a caregiver device connects to a patient device for the first time
- **THEN** the system pairing prompt SHALL appear, and call traffic SHALL only flow after bonding completes

#### Scenario: Unbonded device is refused

- **WHEN** a device that has not bonded attempts to subscribe to the call characteristic
- **THEN** the subscription SHALL be refused and no call content SHALL be transmitted to it


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Connections are tracked as a collection

The system SHALL model caregiver-side connections as a collection of peers rather than a single peer, and SHALL tag every received call with the originating device name so calls from different patients remain distinguishable.

#### Scenario: Received call carries its origin

- **WHEN** a caregiver receives a call
- **THEN** the recorded call SHALL carry the originating patient device name


<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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
### Requirement: Pending calls are not persisted across launches

The system SHALL hold un-acknowledged call state in memory only. A call that was pending when the app stopped SHALL NOT be resent after a subsequent launch.

#### Scenario: Pending call does not survive a restart

- **WHEN** a patient sends a call, the app stops before any acknowledgement arrives, and the app is launched again later
- **THEN** the transport SHALL NOT resend that call and SHALL start with no pending calls

<!-- @trace
source: add-project-skeleton-and-ble-poc
updated: 2026-08-06
code:
  - CLAUDE.md
  - Sources/Core/Transport/CallMessage.swift
  - SideBell_Spec_v0.5.md
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