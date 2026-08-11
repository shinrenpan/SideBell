# grid-storage Specification

## Purpose

TBD - created by archiving change 'add-patient-grid'. Update Purpose after archive.

## Requirements

### Requirement: Grid items are stored on the device

The system SHALL persist the patient's grid items locally, with no cloud synchronisation. Each item SHALL carry an identifier, a title, a symbol name, a command code, an urgency flag, and a sort position.

Local-only storage follows from the offline positioning: the product must work with no internet at all, and health-related content is kept to the minimum footprint.

#### Scenario: Items survive a restart

- **WHEN** the app is terminated and launched again
- **THEN** the grid SHALL show the same items, in the same order, as before


<!-- @trace
source: add-patient-grid
updated: 2026-08-11
code:
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/CallCenter.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Core/Delivery/CallDelivery.swift
  - Sources/App/AppDelegate.swift
  - docs/device-verification/w3-patient-grid.md
  - Sources/Features/PatientGrid/PatientGridMocks.swift
  - Sources/Core/Delivery/PendingCall.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - Sources/Core/Feedback/CallFeedback.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Tests/DeliveryTests/CallDeliveryTests.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - DECISIONS.md
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/Core/Persistence/SideBellModelContainer.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/App/Info.plist
  - Tests/TransportTests/TransportEventFanOutTests.swift
  - Sources/Core/Speech/CallAnnouncer.swift
-->

---
### Requirement: A first launch is seeded with four default items

The system SHALL create four items the first time the grid is used: drinking water, turning over, toilet, and feeling unwell. Seeding SHALL happen once — an empty grid on a later launch SHALL NOT be re-seeded.

An empty grid on first use would mean the device is unusable until a caregiver configures it, and configuration happens in a screen that does not exist yet at that moment.

#### Scenario: First launch creates the defaults

- **WHEN** the grid is opened on a device with no stored items and no prior seeding
- **THEN** four items SHALL exist: 喝水, 翻身, 洗手間, 不舒服

#### Scenario: Deliberately emptied grid stays empty

- **WHEN** every item has been removed and the app is launched again
- **THEN** the grid SHALL remain empty and SHALL NOT be re-seeded


<!-- @trace
source: add-patient-grid
updated: 2026-08-11
code:
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/CallCenter.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Core/Delivery/CallDelivery.swift
  - Sources/App/AppDelegate.swift
  - docs/device-verification/w3-patient-grid.md
  - Sources/Features/PatientGrid/PatientGridMocks.swift
  - Sources/Core/Delivery/PendingCall.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - Sources/Core/Feedback/CallFeedback.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Tests/DeliveryTests/CallDeliveryTests.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - DECISIONS.md
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/Core/Persistence/SideBellModelContainer.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/App/Info.plist
  - Tests/TransportTests/TransportEventFanOutTests.swift
  - Sources/Core/Speech/CallAnnouncer.swift
-->

---
### Requirement: Item content stays within the wire format limits

The system SHALL reject item titles longer than the wire format's limit and command codes that are not short ASCII, at the point the item is stored rather than at the point a call is sent.

Discovering the limit when the patient presses the button is too late: the failure would surface as a call that cannot be sent, in the moment it matters most.

#### Scenario: Title within limits is accepted

- **WHEN** an item with a title of 100 UTF-8 bytes or fewer is stored
- **THEN** it SHALL be stored successfully

#### Scenario: Over-long title is rejected at storage time

- **WHEN** an item with a title longer than 100 UTF-8 bytes is stored
- **THEN** storage SHALL fail with an error naming the limit, and no item SHALL be created

##### Example: validation cases

| Title | Command code | Result |
| ----- | ------------ | ------ |
| "喝水" | "WATER" | stored |
| 100-byte title | "HELP" | stored |
| 101-byte title | "HELP" | rejected: title too long |
| "喝水" | "TOOLONGCODE" | rejected: command code too long |
| "喝水" | "喝水" | rejected: command code not ASCII |


<!-- @trace
source: add-patient-grid
updated: 2026-08-11
code:
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/CallCenter.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Core/Delivery/CallDelivery.swift
  - Sources/App/AppDelegate.swift
  - docs/device-verification/w3-patient-grid.md
  - Sources/Features/PatientGrid/PatientGridMocks.swift
  - Sources/Core/Delivery/PendingCall.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - Sources/Core/Feedback/CallFeedback.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Tests/DeliveryTests/CallDeliveryTests.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - DECISIONS.md
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/Core/Persistence/SideBellModelContainer.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/App/Info.plist
  - Tests/TransportTests/TransportEventFanOutTests.swift
  - Sources/Core/Speech/CallAnnouncer.swift
-->

---
### Requirement: Grid order is explicit and stable

The system SHALL present items in a stored sort position rather than in creation order or an arbitrary order. Two items SHALL NOT share a position.

A patient learns the physical location of each button. If the order shifts between launches, the muscle memory and gaze targets they have built up stop working.

#### Scenario: Order is preserved across launches

- **WHEN** items exist with distinct sort positions and the app is relaunched
- **THEN** they SHALL appear in ascending order of that position, identical to the previous launch

<!-- @trace
source: add-patient-grid
updated: 2026-08-11
code:
  - Sources/Core/Transport/CallTransport.swift
  - Sources/Core/CallCenter.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Core/Delivery/CallDelivery.swift
  - Sources/App/AppDelegate.swift
  - docs/device-verification/w3-patient-grid.md
  - Sources/Features/PatientGrid/PatientGridMocks.swift
  - Sources/Core/Delivery/PendingCall.swift
  - Sources/Core/Transport/BLE/BLETransport.swift
  - Tests/CallCenterTests/CallCenterLifecycleTests.swift
  - Sources/Core/Feedback/CallFeedback.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Tests/DeliveryTests/CallDeliveryTests.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - DECISIONS.md
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/Core/Persistence/SideBellModelContainer.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/App/Info.plist
  - Tests/TransportTests/TransportEventFanOutTests.swift
  - Sources/Core/Speech/CallAnnouncer.swift
-->