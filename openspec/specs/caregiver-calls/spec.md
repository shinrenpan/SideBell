# caregiver-calls Specification

## Purpose

TBD - created by archiving change 'add-caregiver-alerts'. Update Purpose after archive.

## Requirements

### Requirement: The caregiver sees the calls that arrived
The caregiver screen SHALL list the calls received from the patient, most recent first. Each entry SHALL show the item name, the source patient's name, the time the patient pressed, and whether this device has sent an acknowledgement.

#### Scenario: A call arrives while the screen is open
- **WHEN** a call arrives and the caregiver call list is on screen
- **THEN** the call appears at the top of the list within one second, showing its item name, source, and press time
- **AND** it is marked as not yet acknowledged

#### Scenario: Calls that arrived while the screen was absent
- **WHEN** the caregiver opens the call list after the app has been in the background
- **THEN** every call received during that period is listed, in the order received
- **AND** none of them are lost because no screen existed at the time

##### Example: overnight background
- **GIVEN** the caregiver's phone was locked from 23:00 to 07:00
- **AND** the patient triggered "bathroom" at 03:12 and "water" at 05:40
- **WHEN** the caregiver opens the app at 07:00
- **THEN** both calls are listed, with "water" above "bathroom"

#### Scenario: The same call arrives twice
- **WHEN** a call with an identifier already present in the list arrives again
- **THEN** the list SHALL NOT show a second entry for it


<!-- @trace
source: add-caregiver-alerts
updated: 2026-08-14
code:
  - Sources/Resources/AlertNotification.caf
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - docs/roadmap.md
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Config/Secrets.example.xcconfig
  - Sources/Resources/Assets.xcassets/Contents.json
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/App/Info.plist
  - Sources/Resources/Alert.caf
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/AlertTests/AlertPolicyTests.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w5-localization.md
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - docs/device-verification/w3-patient-grid.md
  - project.yml
  - Sources/Core/Speech/CallAnnouncer.swift
  - Sources/Core/Alert/AlertAudioSession.swift
  - scripts/screenshots.sh
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift
  - Sources/Core/Alert/AlertPolicy.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Core/Notification/CallNotifier.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - SideBell_Spec_v0.5.md
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - docs/release-checklist.md
  - docs/archive/SideBell_Spec_v0.5.md
  - DECISIONS.md
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Core/Alert/AlertPlayer.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
-->

---
### Requirement: Acknowledging a call closes the loop
The caregiver SHALL be able to acknowledge a call with a single action. Acknowledging SHALL write the acknowledgement back to the patient's device.

#### Scenario: Acknowledging a call
- **WHEN** the caregiver acknowledges a call in the list
- **THEN** the acknowledgement is written back to the patient's device
- **AND** the patient's corresponding cell shows the acknowledged state
- **AND** the entry in the caregiver's list is marked as acknowledged

#### Scenario: The acknowledgement cannot be delivered
- **WHEN** the caregiver acknowledges a call and the write fails
- **THEN** the entry SHALL remain marked as not acknowledged
- **AND** the screen SHALL state that the acknowledgement was not delivered
- **AND** the caregiver SHALL be able to try again

#### Scenario: Acknowledging a call whose origin is no longer known
- **WHEN** the caregiver acknowledges a call received before the app was restarted
- **THEN** the acknowledgement is still delivered to the connected patient device


<!-- @trace
source: add-caregiver-alerts
updated: 2026-08-14
code:
  - Sources/Resources/AlertNotification.caf
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - docs/roadmap.md
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Config/Secrets.example.xcconfig
  - Sources/Resources/Assets.xcassets/Contents.json
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/App/Info.plist
  - Sources/Resources/Alert.caf
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/AlertTests/AlertPolicyTests.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w5-localization.md
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - docs/device-verification/w3-patient-grid.md
  - project.yml
  - Sources/Core/Speech/CallAnnouncer.swift
  - Sources/Core/Alert/AlertAudioSession.swift
  - scripts/screenshots.sh
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift
  - Sources/Core/Alert/AlertPolicy.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Core/Notification/CallNotifier.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - SideBell_Spec_v0.5.md
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - docs/release-checklist.md
  - docs/archive/SideBell_Spec_v0.5.md
  - DECISIONS.md
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Core/Alert/AlertPlayer.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
-->

---
### Requirement: A call the patient has given up on cannot be acknowledged
Once three minutes have passed since the patient pressed, the entry SHALL be shown as unanswered and SHALL NOT offer acknowledgement.

#### Scenario: Three minutes pass without acknowledgement
- **WHEN** three minutes have passed since the patient pressed and nobody has acknowledged
- **THEN** the entry is marked as unanswered
- **AND** the acknowledgement control is no longer offered
- **AND** the patient's cell shows the same outcome

#### Scenario: The screen is open while a call expires
- **GIVEN** the call list is on screen and a call is waiting
- **WHEN** it reaches three minutes without acknowledgement
- **THEN** the entry changes to unanswered without any caregiver action


<!-- @trace
source: add-caregiver-alerts
updated: 2026-08-14
code:
  - Sources/Resources/AlertNotification.caf
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - docs/roadmap.md
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Config/Secrets.example.xcconfig
  - Sources/Resources/Assets.xcassets/Contents.json
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/App/Info.plist
  - Sources/Resources/Alert.caf
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/AlertTests/AlertPolicyTests.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w5-localization.md
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - docs/device-verification/w3-patient-grid.md
  - project.yml
  - Sources/Core/Speech/CallAnnouncer.swift
  - Sources/Core/Alert/AlertAudioSession.swift
  - scripts/screenshots.sh
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift
  - Sources/Core/Alert/AlertPolicy.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Core/Notification/CallNotifier.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - SideBell_Spec_v0.5.md
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - docs/release-checklist.md
  - docs/archive/SideBell_Spec_v0.5.md
  - DECISIONS.md
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Core/Alert/AlertPlayer.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
-->

---
### Requirement: The waiting time is shown as elapsed time
While a call can still be answered, the entry SHALL show how long the patient has been waiting rather than the clock time at which they pressed.

#### Scenario: A call is waiting
- **WHEN** a call is waiting for acknowledgement
- **THEN** the entry shows the time elapsed since the patient pressed
- **AND** that figure updates as time passes

#### Scenario: A call has been answered or has expired
- **WHEN** a call has been acknowledged or has passed three minutes
- **THEN** the entry shows the clock time at which the patient pressed


<!-- @trace
source: add-caregiver-alerts
updated: 2026-08-14
code:
  - Sources/Resources/AlertNotification.caf
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - docs/roadmap.md
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Config/Secrets.example.xcconfig
  - Sources/Resources/Assets.xcassets/Contents.json
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/App/Info.plist
  - Sources/Resources/Alert.caf
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/AlertTests/AlertPolicyTests.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w5-localization.md
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - docs/device-verification/w3-patient-grid.md
  - project.yml
  - Sources/Core/Speech/CallAnnouncer.swift
  - Sources/Core/Alert/AlertAudioSession.swift
  - scripts/screenshots.sh
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift
  - Sources/Core/Alert/AlertPolicy.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Core/Notification/CallNotifier.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - SideBell_Spec_v0.5.md
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - docs/release-checklist.md
  - docs/archive/SideBell_Spec_v0.5.md
  - DECISIONS.md
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Core/Alert/AlertPlayer.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
-->

---
### Requirement: Call state does not survive a restart
The caregiver's call list SHALL exist only in memory and SHALL NOT be restored after the app restarts.

#### Scenario: Restarting the app
- **WHEN** the app is restarted
- **THEN** the call list is empty until new calls arrive


<!-- @trace
source: add-caregiver-alerts
updated: 2026-08-14
code:
  - Sources/Resources/AlertNotification.caf
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - docs/roadmap.md
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Config/Secrets.example.xcconfig
  - Sources/Resources/Assets.xcassets/Contents.json
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/App/Info.plist
  - Sources/Resources/Alert.caf
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/AlertTests/AlertPolicyTests.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w5-localization.md
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - docs/device-verification/w3-patient-grid.md
  - project.yml
  - Sources/Core/Speech/CallAnnouncer.swift
  - Sources/Core/Alert/AlertAudioSession.swift
  - scripts/screenshots.sh
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift
  - Sources/Core/Alert/AlertPolicy.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Core/Notification/CallNotifier.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - SideBell_Spec_v0.5.md
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - docs/release-checklist.md
  - docs/archive/SideBell_Spec_v0.5.md
  - DECISIONS.md
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Core/Alert/AlertPlayer.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
-->

---
### Requirement: The caregiver screen shows whether calls can arrive
The caregiver screen SHALL show, at all times, whether the connection to the patient is currently able to carry calls. The indicator SHALL NOT rely on colour alone.

#### Scenario: The patient device leaves range
- **WHEN** the patient's device is no longer reachable
- **THEN** the indicator changes within seconds without any caregiver action
- **AND** the change is conveyed by symbol and text, not only by colour

<!-- @trace
source: add-caregiver-alerts
updated: 2026-08-14
code:
  - Sources/Resources/AlertNotification.caf
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
  - Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - Sources/Resources/PrivacyInfo.xcprivacy
  - Tests/PatientGridTests/PatientGridLayoutTests.swift
  - Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/PatientGrid/PatientGridViewModel+Models.swift
  - Sources/Features/TransportPoC/TransportPoCView.swift
  - docs/roadmap.md
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
  - Config/Secrets.example.xcconfig
  - Sources/Resources/Assets.xcassets/Contents.json
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - Sources/Features/GridEditing/GridEditingViewModel+Models.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift
  - Sources/Features/GridEditing/GridEditingMocks.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/GridEditing/GridEditingViewModel.swift
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift
  - docs/device-verification/w7-grid-editing.md
  - Sources/App/Info.plist
  - Sources/Resources/Alert.caf
  - Sources/Core/Support/SideBellLog.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/PatientGrid/PatientGridHostController.swift
  - Tests/AlertTests/AlertPolicyTests.swift
  - Tests/GridEditingTests/GridEditingStateTests.swift
  - docs/device-verification/w5-localization.md
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/GridEditing/GridEditingHostController.swift
  - Sources/Core/Transport/BLE/BLECentralEndpoint.swift
  - Sources/Features/PatientGrid/PatientGridViewModel.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/TransportPoC/TransportPoCViewModel.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - docs/device-verification/w3-patient-grid.md
  - project.yml
  - Sources/Core/Speech/CallAnnouncer.swift
  - Sources/Core/Alert/AlertAudioSession.swift
  - scripts/screenshots.sh
  - Sources/Core/Transport/ScreenshotTransport.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift
  - Sources/Core/Alert/AlertPolicy.swift
  - Sources/Core/Persistence/GridItemModel.swift
  - Sources/Features/TransportPoC/TransportPoCHostController.swift
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Core/Notification/CallNotifier.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - SideBell_Spec_v0.5.md
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - docs/device-verification/w4-caregiver-alerts.md
  - Sources/Features/PatientGrid/PatientGridView.swift
  - docs/release-checklist.md
  - docs/archive/SideBell_Spec_v0.5.md
  - DECISIONS.md
  - Sources/Features/GridEditing/GridEditingView.swift
  - Sources/Core/Alert/AlertPlayer.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
-->