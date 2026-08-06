# app-shell Specification

## Purpose

TBD - created by archiving change 'add-project-skeleton-and-ble-poc'. Update Purpose after archive.

## Requirements

### Requirement: Project is generated from a declarative manifest

The system SHALL generate the Xcode project from a checked-in declarative manifest, so that target settings, background modes, capabilities and Info.plist keys are reviewable as text. The generated Xcode project SHALL NOT be the source of truth for those settings.

#### Scenario: Regenerating produces a buildable project

- **WHEN** a developer with a clean checkout runs the project generator and then builds the app target
- **THEN** the build SHALL succeed without any manual Xcode configuration step

#### Scenario: Capability changes are visible in review

- **WHEN** a background mode or capability is added or removed
- **THEN** the change SHALL appear as a text diff in the manifest


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
### Requirement: Deployment target and supported devices

The app SHALL target iOS 18.0 as its minimum version and SHALL support both iPhone and iPad.

#### Scenario: Installing on the minimum supported version

- **WHEN** the app is installed on a device running the minimum supported iOS version
- **THEN** installation SHALL succeed and the app SHALL launch


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
### Requirement: UIKit lifecycle entry point hosting SwiftUI

The app SHALL launch through a UIKit application and scene lifecycle and SHALL present its SwiftUI content through a hosting controller. The app SHALL NOT use a SwiftUI application lifecycle entry point, because Bluetooth managers must be rebuilt during the earliest launch callback for state restoration to work.

#### Scenario: Bluetooth managers are rebuilt at launch

- **WHEN** the system launches the app in the background in response to a Bluetooth event
- **THEN** the transport SHALL be reconstructed during the application launch callback, before any scene becomes active

#### Scenario: Root content is presented through a navigation stack

- **WHEN** the app becomes active in the foreground
- **THEN** the window root SHALL be a navigation controller hosting SwiftUI content, and the window SHALL have an opaque background colour


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
### Requirement: Role is persisted and readable before transport start

The app SHALL persist the selected role, patient or caregiver, in lightweight storage readable synchronously during the application launch callback. Role storage SHALL NOT require the persistent data store to be loaded first.

#### Scenario: Role is known at the earliest launch callback

- **WHEN** the app launches after a role has previously been selected
- **THEN** the role SHALL be readable during the application launch callback, before any user interface is constructed

#### Scenario: No role selected yet

- **WHEN** the app launches for the first time with no role stored
- **THEN** the role SHALL read as unselected and the transport SHALL NOT be started in either role


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
### Requirement: Bluetooth background modes and usage description are declared

The app SHALL declare the Bluetooth central and Bluetooth peripheral background modes, and SHALL declare a Bluetooth usage description that explains, in the user's language, that Bluetooth connects the patient and caregiver devices without requiring internet access.

#### Scenario: Permission prompt shows the reason

- **WHEN** the app requests Bluetooth access for the first time
- **THEN** the system prompt SHALL display the declared usage description rather than a blank or generic reason

#### Scenario: Background modes present in the built app

- **WHEN** the built app bundle is inspected
- **THEN** its Info.plist SHALL list both the Bluetooth central and the Bluetooth peripheral background modes

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