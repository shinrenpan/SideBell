# caregiver-alert Specification

## Purpose

TBD - created by archiving change 'add-caregiver-alerts'. Update Purpose after archive.

## Requirements

### Requirement: An arriving call raises an alert
When a call arrives, the caregiver's device SHALL raise an alert that is audible, spoken, and felt.

#### Scenario: A call arrives
- **WHEN** a call arrives
- **THEN** the device plays an alert sound
- **AND** speaks the item name aloud
- **AND** produces haptic feedback on devices that have the hardware

#### Scenario: The alert sound cannot be loaded
- **WHEN** the alert sound fails to load
- **THEN** the spoken announcement and the haptic feedback SHALL still occur


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
### Requirement: The alert is heard in every situation the platform permits
The alert SHALL be audible in every combination of silent switch, foreground or background, and other apps holding audio. Sustaining an alert SHALL NOT depend on the app holding foreground presence.

#### Scenario: Silent switch engaged, app in the foreground
- **GIVEN** the caregiver's device has the silent switch engaged
- **AND** the app is in the foreground
- **WHEN** a call arrives
- **THEN** the alert sound is audible

#### Scenario: App in the background, ringer not silenced
- **WHEN** a call arrives while the app is in the background
- **THEN** the alert sound is audible

#### Scenario: Other audio is playing
- **GIVEN** the caregiver is playing music or a podcast
- **WHEN** a call arrives
- **THEN** the alert is audible over that audio, which is lowered while the alert plays

##### Example: background playback
- **GIVEN** a music app is playing in the foreground and this app is in the background
- **WHEN** a call arrives
- **THEN** the music drops in volume and the alert is heard
- **AND** the alert SHALL NOT be dropped merely because another app holds audio focus

#### Scenario: Silent switch engaged while the app is in the background
- **GIVEN** the caregiver's device has the silent switch engaged
- **AND** the app is in the background
- **WHEN** an urgent call arrives
- **THEN** the alert sound is audible and repeats until a stopping condition is met

##### Example: the caregiver is asleep
- **GIVEN** the phone is on the bedside table, silenced, its screen dimmed
- **AND** a music app is playing in the background
- **WHEN** an urgent call arrives
- **THEN** the alert sounds and keeps repeating
- **AND** it SHALL NOT stop merely because the app has no foreground presence


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
### Requirement: Urgent calls repeat until answered
An urgent call SHALL repeat its alert until a stopping condition is met. A non-urgent call SHALL alert once.

#### Scenario: An urgent call is not acknowledged
- **WHEN** an urgent call arrives and nobody acknowledges it
- **THEN** the alert repeats at a fixed interval

#### Scenario: A non-urgent call is not acknowledged
- **WHEN** a non-urgent call arrives and nobody acknowledges it
- **THEN** the alert plays once and does not repeat

#### Scenario: Several urgent calls are outstanding
- **WHEN** more than one urgent call is outstanding
- **THEN** only one alert sounds at a time, and the alerts SHALL NOT overlap


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
### Requirement: The alert stops on three conditions and no others
The alert SHALL stop when the call is acknowledged, when three minutes have passed since the patient pressed, or when the caregiver role is left.

#### Scenario: The caregiver acknowledges
- **WHEN** the caregiver acknowledges the call
- **THEN** its alert stops immediately

#### Scenario: Three minutes pass without acknowledgement
- **WHEN** three minutes have passed since the patient pressed the cell
- **THEN** the alert stops
- **AND** the patient's device shows that nobody responded

##### Example: a queued call
- **GIVEN** the patient pressed at 09:00:00 while the caregiver was out of range
- **AND** the call was delivered at 09:02:00 when the caregiver returned
- **WHEN** nobody acknowledges it
- **THEN** the alert stops at 09:03:00, not at 09:05:00

#### Scenario: The caregiver leaves the role
- **WHEN** the device is switched away from the caregiver role
- **THEN** all alerts stop

#### Scenario: Acknowledging one of several outstanding calls
- **GIVEN** two urgent calls are outstanding
- **WHEN** the caregiver acknowledges one of them
- **THEN** the alert continues for the one that remains outstanding


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
### Requirement: A call arriving in the background is visible on the lock screen
When the app is not in the foreground, the call SHALL also be presented as a local notification.

#### Scenario: A call arrives while the phone is locked
- **WHEN** a call arrives and the app is in the background or the phone is locked
- **THEN** a notification appears showing the item name and the source patient
- **AND** the alert sound is played regardless of whether the notification itself is silenced

#### Scenario: Notification permission was refused
- **WHEN** a call arrives and notification permission has not been granted
- **THEN** no notification is shown
- **AND** the audible alert still occurs
- **AND** the caregiver is not prompted again


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
### Requirement: Permission to notify is requested at a moment the caregiver understands
Permission for notifications SHALL be requested when the caregiver role is first entered, and SHALL NOT be requested at app launch.

#### Scenario: Entering the caregiver role for the first time
- **WHEN** the caregiver role is entered for the first time
- **THEN** the system asks for notification permission

#### Scenario: Entering the caregiver role again
- **WHEN** the caregiver role is entered on a later occasion
- **THEN** the system SHALL NOT ask again, whatever the earlier answer was


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
### Requirement: An interrupted alert resumes
When system audio is interrupted, an outstanding urgent alert SHALL resume once the interruption ends.

#### Scenario: A phone call interrupts the alert
- **GIVEN** an urgent call is alerting
- **WHEN** an incoming phone call interrupts the audio
- **AND** the phone call ends while the urgent call is still outstanding
- **THEN** the alert resumes

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