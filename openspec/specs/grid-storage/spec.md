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

The system SHALL create two items the first time the grid is used: one protected item for distress, and one for drinking water. Seeding SHALL happen once.

Four defaults assumed needs on the caregiver's behalf — turning over is useless to a patient who can walk, and the needs that matter most to a given household (changing a nappy, suctioning) were never among them. Two is the smallest set that leaves the device usable on arrival: one guaranteed way to call for help, and one ordinary need that shows what a cell looks like. The rest is for the caregiver to add.

The grid can no longer become empty, because the protected item cannot be deleted.

#### Scenario: First launch creates the defaults

- **WHEN** the grid is opened on a device with no stored items and no prior seeding
- **THEN** two items SHALL exist: a protected item for distress, and one for drinking water
- **AND** the protected item SHALL be first

#### Scenario: The grid cannot be emptied

- **WHEN** the caregiver deletes every item that can be deleted
- **THEN** the protected item SHALL remain
- **AND** the patient SHALL still have a way to call for help


<!-- @trace
source: add-grid-editing
updated: 2026-08-13
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - docs/device-verification/w3-patient-grid.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/App/AppRouter.swift
  - DECISIONS.md
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