# sponsorship Specification

## Purpose

TBD - created by archiving change 'add-sponsorship'. Update Purpose after archive.

## Requirements

### Requirement: Supporting the developer never changes what the app can do
Every feature SHALL remain available regardless of whether the user has ever supported the developer. The app SHALL NOT contain any decision that depends on purchase state to determine whether a feature is available.

#### Scenario: A user who has never supported
- **WHEN** a user who has never made a purchase uses the app
- **THEN** every feature behaves exactly as it does for a user who has

#### Scenario: The device has been offline for a long time
- **GIVEN** the device has had no network connection for weeks
- **WHEN** the patient triggers a call and the caregiver acknowledges it
- **THEN** both work as normal
- **AND** no purchase verification is attempted at any point


<!-- @trace
source: add-sponsorship
updated: 2026-08-14
code:
  - docs/device-verification/w3-patient-grid.md
  - docs/device-verification/w7-grid-editing.md
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/App/Info.plist
  - Sources/Core/Alert/AlertPlayer.swift
  - docs/release-checklist.md
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - DECISIONS.md
  - Sources/Resources/Assets.xcassets/Contents.json
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/Core/Persistence/GridItemModel.swift
  - SideBell_Spec_v0.5.md
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - project.yml
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/App/AppDelegate.swift
  - scripts/screenshots.sh
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - docs/roadmap.md
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Sources/Core/Notification/CallNotifier.swift
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
-->

---
### Requirement: The support screen is reachable only from the caregiver side
The support screen SHALL be reachable only from the caregiver's settings. The patient's interface SHALL NOT present any entry point, price, or purchase control.

#### Scenario: The caregiver opens settings
- **WHEN** the caregiver opens the settings tab
- **THEN** an entry point to the support screen is shown

#### Scenario: The patient opens settings
- **WHEN** the patient's settings screen is opened
- **THEN** no entry point to the support screen is present
- **AND** no price or purchase control appears anywhere in the patient's interface


<!-- @trace
source: add-sponsorship
updated: 2026-08-14
code:
  - docs/device-verification/w3-patient-grid.md
  - docs/device-verification/w7-grid-editing.md
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/App/Info.plist
  - Sources/Core/Alert/AlertPlayer.swift
  - docs/release-checklist.md
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - DECISIONS.md
  - Sources/Resources/Assets.xcassets/Contents.json
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/Core/Persistence/GridItemModel.swift
  - SideBell_Spec_v0.5.md
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - project.yml
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/App/AppDelegate.swift
  - scripts/screenshots.sh
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - docs/roadmap.md
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Sources/Core/Notification/CallNotifier.swift
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
-->

---
### Requirement: Each option states what the money is for
The support screen SHALL present three options, each showing the price as provided by the App Store for the user's region, together with a description of what that amount is used for.

#### Scenario: The support screen is opened with a network connection
- **WHEN** the caregiver opens the support screen and the store is reachable
- **THEN** three options are listed
- **AND** each shows its localized price and what the amount funds

#### Scenario: Supporting more than once
- **WHEN** the caregiver chooses an option they have already purchased before
- **THEN** the purchase proceeds as a new, independent contribution


<!-- @trace
source: add-sponsorship
updated: 2026-08-14
code:
  - docs/device-verification/w3-patient-grid.md
  - docs/device-verification/w7-grid-editing.md
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/App/Info.plist
  - Sources/Core/Alert/AlertPlayer.swift
  - docs/release-checklist.md
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - DECISIONS.md
  - Sources/Resources/Assets.xcassets/Contents.json
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/Core/Persistence/GridItemModel.swift
  - SideBell_Spec_v0.5.md
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - project.yml
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/App/AppDelegate.swift
  - scripts/screenshots.sh
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - docs/roadmap.md
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Sources/Core/Notification/CallNotifier.swift
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
-->

---
### Requirement: The support screen states plainly when it needs a network
The support screen SHALL state that a connection is required when it cannot reach the store, and SHALL offer a way to try again. Every other screen SHALL behave identically whether or not the device has a network connection.

#### Scenario: Opening the support screen with no connection
- **WHEN** the caregiver opens the support screen and the store cannot be reached
- **THEN** the screen states that a connection is needed and offers to retry
- **AND** it SHALL NOT show an empty list or an indefinite loading state

#### Scenario: Using the rest of the app with no connection
- **WHEN** the device has no network connection
- **THEN** calls, alerts, and acknowledgements behave exactly as they do with one


<!-- @trace
source: add-sponsorship
updated: 2026-08-14
code:
  - docs/device-verification/w3-patient-grid.md
  - docs/device-verification/w7-grid-editing.md
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/App/Info.plist
  - Sources/Core/Alert/AlertPlayer.swift
  - docs/release-checklist.md
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - DECISIONS.md
  - Sources/Resources/Assets.xcassets/Contents.json
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/Core/Persistence/GridItemModel.swift
  - SideBell_Spec_v0.5.md
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - project.yml
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/App/AppDelegate.swift
  - scripts/screenshots.sh
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - docs/roadmap.md
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Sources/Core/Notification/CallNotifier.swift
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
-->

---
### Requirement: Cancelling is not an error
When the user cancels a purchase, the app SHALL return silently. Other failures SHALL be explained in terms the user can act on.

#### Scenario: The user cancels
- **WHEN** the user dismisses the system purchase sheet without buying
- **THEN** no error message is shown

#### Scenario: The purchase fails for another reason
- **WHEN** a purchase fails for a reason other than cancellation
- **THEN** the screen explains what happened and offers to try again
- **AND** it SHALL NOT show a raw error code


<!-- @trace
source: add-sponsorship
updated: 2026-08-14
code:
  - docs/device-verification/w3-patient-grid.md
  - docs/device-verification/w7-grid-editing.md
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/App/Info.plist
  - Sources/Core/Alert/AlertPlayer.swift
  - docs/release-checklist.md
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - DECISIONS.md
  - Sources/Resources/Assets.xcassets/Contents.json
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/Core/Persistence/GridItemModel.swift
  - SideBell_Spec_v0.5.md
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - project.yml
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/App/AppDelegate.swift
  - scripts/screenshots.sh
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - docs/roadmap.md
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Sources/Core/Notification/CallNotifier.swift
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
-->

---
### Requirement: Thanks is decoration, not a benefit
After a successful purchase the app SHALL acknowledge it. That acknowledgement SHALL be decorative and SHALL remain visible without a network connection.

#### Scenario: After supporting
- **WHEN** a purchase completes successfully
- **THEN** the caregiver's settings shows a token of thanks

#### Scenario: The token of thanks while offline
- **GIVEN** the user has supported the developer before
- **WHEN** the device has no network connection
- **THEN** the token of thanks is still shown

#### Scenario: The token of thanks grants nothing
- **WHEN** the token of thanks is shown
- **THEN** no feature, setting, or behaviour differs from a user without it

<!-- @trace
source: add-sponsorship
updated: 2026-08-14
code:
  - docs/device-verification/w3-patient-grid.md
  - docs/device-verification/w7-grid-editing.md
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/App/Info.plist
  - Sources/Core/Alert/AlertPlayer.swift
  - docs/release-checklist.md
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - DECISIONS.md
  - Sources/Resources/Assets.xcassets/Contents.json
  - docs/archive/SideBell_Spec_v0.5.md
  - Sources/Core/Persistence/GridItemModel.swift
  - SideBell_Spec_v0.5.md
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - project.yml
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/App/AppDelegate.swift
  - scripts/screenshots.sh
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - docs/roadmap.md
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Sources/Core/Notification/CallNotifier.swift
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
-->