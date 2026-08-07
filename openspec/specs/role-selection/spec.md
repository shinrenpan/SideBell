# role-selection Specification

## Purpose

TBD - created by archiving change 'add-app-entry'. Update Purpose after archive.

## Requirements

### Requirement: Disclaimer is permanently present on the home screen

The home screen SHALL present, on every launch, a statement that SideBell is a care assistance calling tool and cannot replace emergency medical alert services or calling the local emergency number. The statement SHALL occupy the top of the screen, SHALL NOT be collapsed behind a link, a disclosure control or a tooltip, and SHALL NOT be truncated.

The statement SHALL be readable in full, by scrolling when the viewport cannot contain it. A fixed layout that clips the text is not acceptable: enlarged Dynamic Type sizes, small screens and longer translations compound, and clipped text is text the user can never reach.

#### Scenario: Statement is present on every launch

- **WHEN** the home screen appears, on any launch, including launches after the disclaimer was already acknowledged
- **THEN** the statement SHALL be at the top of the screen, with no interaction required to reveal it

#### Scenario: Statement stays readable when the viewport is too small

- **WHEN** the home screen is shown with an enlarged Dynamic Type size on a small screen, such that the statement cannot fit
- **THEN** the statement SHALL remain readable in full by scrolling, and SHALL NOT be truncated or clipped


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: First launch requires explicit acknowledgement of the disclaimer

The system SHALL require the user to actively acknowledge the disclaimer before either role can be selected for the first time. The acknowledgement SHALL be persisted, and SHALL NOT be requested again on subsequent launches.

#### Scenario: Roles are locked until acknowledged

- **WHEN** the app launches for the first time
- **THEN** both role buttons SHALL be disabled, and an unchecked acknowledgement control SHALL be shown next to the disclaimer

#### Scenario: Acknowledgement sits below the statement

- **WHEN** the home screen is shown on first launch
- **THEN** the acknowledgement control SHALL appear below the statement inside the same scrollable region, so that reaching it requires passing the statement

#### Scenario: Acknowledging unlocks role selection

- **WHEN** the user checks the acknowledgement control
- **THEN** both role buttons SHALL become enabled, provided Bluetooth is not unavailable

#### Scenario: Acknowledgement is remembered

- **WHEN** the app is launched again after the disclaimer was acknowledged
- **THEN** the acknowledgement control SHALL NOT be shown, and role selection SHALL NOT be blocked by it


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: Role selection is blocked only when Bluetooth is definitively unavailable

The system SHALL disable both role buttons and explain why when Bluetooth is powered off, unauthorized, or unsupported. The system SHALL NOT disable them while Bluetooth availability is undetermined.

This distinction is load-bearing: no Bluetooth manager exists before a role is chosen, so availability reads as undetermined on first launch. Treating that as unavailable would deadlock the app — the permission prompt only appears once a manager is created, and a manager is only created once a role is chosen.

#### Scenario: Undetermined availability does not block entry

- **WHEN** the app launches for the first time, before any Bluetooth manager has been created
- **THEN** the role buttons SHALL be enabled once the disclaimer is acknowledged, and no Bluetooth warning SHALL be shown

#### Scenario: Powered-off Bluetooth blocks entry with an explanation

- **WHEN** the home screen is shown while Bluetooth is powered off
- **THEN** both role buttons SHALL be disabled and the screen SHALL state that Bluetooth is off and must be turned on

#### Scenario: Turning Bluetooth on restores entry

- **WHEN** the user turns Bluetooth on while the home screen is visible
- **THEN** the role buttons SHALL become enabled without the user having to restart the app

##### Example: button state by availability

| Disclaimer acknowledged | Bluetooth state | Role buttons | Message shown |
| ----------------------- | --------------- | ------------ | ------------- |
| no | undetermined | disabled | acknowledgement required |
| yes | undetermined | enabled | none |
| yes | powered off | disabled | Bluetooth is off |
| yes | unauthorized | disabled | Bluetooth permission needed |
| yes | unsupported | disabled | device does not support Bluetooth |
| yes | powered on | enabled | none |


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: Role buttons stay reachable regardless of content length

The role buttons SHALL remain on screen and reachable regardless of how long the statement is or how large the text is rendered. They SHALL NOT be pushed out of view by the content above them.

#### Scenario: Buttons remain reachable with enlarged text

- **WHEN** the home screen is shown with an enlarged Dynamic Type size that forces the statement to scroll
- **THEN** both role buttons SHALL still be on screen without scrolling


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: Choosing a role opens its container full screen

The system SHALL present the chosen role's container as a full-screen modal over the home screen, and SHALL persist the choice so the transport starts in that role.

#### Scenario: Patient role opens the patient container

- **WHEN** the user chooses the patient role
- **THEN** the patient container SHALL be presented full screen and the transport SHALL start advertising

#### Scenario: Caregiver role opens the caregiver container

- **WHEN** the user chooses the caregiver role
- **THEN** the caregiver container SHALL be presented full screen and the transport SHALL start scanning


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: A previously chosen role bypasses the home screen

The system SHALL open directly into the stored role's container when the app launches with a role already chosen, without animation and without asking the user to choose again. The home screen SHALL remain the root beneath it.

Requiring the caregiver to re-select a role on every launch is a failure scenario, not an inconvenience: an alarm at three in the morning would put a role picker between the caregiver and the patient's call.

#### Scenario: Launch with a stored role

- **WHEN** the app launches and a role was previously chosen
- **THEN** that role's container SHALL be on screen when the app becomes interactive, with no visible transition from the home screen

#### Scenario: Home screen remains available underneath

- **WHEN** the user later leaves the role from settings
- **THEN** the home screen SHALL be revealed, with the role buttons available for a new choice


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: Either role can return to the home screen

The system SHALL offer a way to leave the current role and return to the home screen from within each role's settings. Leaving a role SHALL stop that role's transport activity.

#### Scenario: Leaving from the caregiver role

- **WHEN** the caregiver chooses to switch roles from the settings tab
- **THEN** the caregiver container SHALL be dismissed, the home screen SHALL be shown, and scanning SHALL stop

#### Scenario: Leaving from the patient role

- **WHEN** the patient device's settings are opened and switching roles is chosen
- **THEN** the patient container SHALL be dismissed, the home screen SHALL be shown, and advertising SHALL stop


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: The patient role has no persistent navigation controls

The patient container SHALL devote the full screen to patient content and SHALL NOT display a tab bar or segmented control. Its settings entry point SHALL require two deliberate activations rather than one, and the control SHALL visibly change between the first and the second.

The rationale is safety, not aesthetics: eye control precision scales with the physical size of the target, and a mis-tap that navigates away from the calling screen may leave a patient unable to return — the calling system would be silently out of service.

The safeguard SHALL NOT rely on a gesture that some assistive technology cannot produce. An earlier design required a long press, which eye control cannot issue — but neither can VoiceOver users perform it reliably, making it a barrier to blind caregivers. Requiring two accurate activations against a changing target is equally hard to trigger by accident, while remaining a plain tap for every assistive technology.

#### Scenario: No tab bar in the patient container

- **WHEN** the patient container is on screen
- **THEN** no tab bar or segmented control SHALL be present, and patient content SHALL occupy the full screen

#### Scenario: A single activation does not open settings

- **WHEN** the settings control in the patient container is activated once
- **THEN** the settings SHALL NOT open, and the control SHALL change to indicate that another activation is required

#### Scenario: A second activation opens settings

- **WHEN** the settings control is activated again while it is indicating that another activation is required
- **THEN** the patient settings SHALL open

#### Scenario: The pending state expires on its own

- **WHEN** the control has been activated once and is not activated again within a few seconds
- **THEN** it SHALL return to its resting state without opening settings


<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->

---
### Requirement: The home screen is fully operable with VoiceOver

Every interactive element on the home screen SHALL carry a label that states its purpose, and disabled elements SHALL convey why they are disabled. The disclaimer SHALL be reachable by VoiceOver navigation. Reading order SHALL match visual order: disclaimer, acknowledgement, then the role buttons.

Blind users are part of the target population — a caregiver setting up the device may themselves be blind, and a blind-and-mobile patient operates the app through VoiceOver rather than eye control. Feedback that exists only in visual form does not exist for them.

#### Scenario: Role buttons announce their purpose

- **WHEN** VoiceOver focuses a role button
- **THEN** it SHALL announce the role and that it opens that role's screen, not merely the word on the button

#### Scenario: Disabled buttons announce the reason

- **WHEN** VoiceOver focuses a role button that is disabled because the disclaimer is unacknowledged
- **THEN** it SHALL announce that acknowledgement is required
- **AND WHEN** the button is disabled because Bluetooth is off
- **THEN** it SHALL announce that Bluetooth must be turned on

#### Scenario: Reading order matches visual order

- **WHEN** VoiceOver navigates the home screen from the top
- **THEN** the elements SHALL be reached in the order: disclaimer, acknowledgement control, patient button, caregiver button

#### Scenario: Settings are reachable without sight

- **WHEN** a VoiceOver user activates the patient container's settings control twice
- **THEN** the patient settings SHALL open, using the same plain activation gesture as any other button
- **AND** the change to the pending state SHALL be announced, so that a user who cannot see the label change knows the first activation registered

The safeguard against eye-control mis-taps SHALL NOT become a barrier to blind caregivers. A gesture that technically works but takes several attempts is a barrier — reachability is not the same as usability.

<!-- @trace
source: add-app-entry
updated: 2026-08-08
code:
  - Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift
  - Tests/RoleTests/DisclaimerStoreTests.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift
  - DECISIONS.md
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Tests/TransportTests/BluetoothAvailabilityTests.swift
  - Sources/Core/Transport/BluetoothAvailability.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/App/AppRouter.swift
  - Sources/Features/RoleSelection/RoleSelectionViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionHostController.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Tests/RoleSelectionTests/RoleSelectionStateTests.swift
  - Sources/Features/PatientHome/PatientHomeContainer.swift
  - Sources/App/Info.plist
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w2-app-entry.md
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Role/DisclaimerStore.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/App/SceneDelegate.swift
-->