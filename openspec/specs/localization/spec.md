# localization Specification

## Purpose

TBD - created by archiving change 'add-localization'. Update Purpose after archive.

## Requirements

### Requirement: Every user sees a language they can read
The app SHALL present its interface in the user's system language when that language is supported, and in English otherwise. No user SHALL be shown a language that is neither their own nor English.

#### Scenario: The system language is supported
- **WHEN** the system language is Traditional Chinese
- **THEN** every screen is presented in Traditional Chinese

#### Scenario: The system language is English
- **WHEN** the system language is English
- **THEN** every screen is presented in English

#### Scenario: The system language is not supported
- **WHEN** the system language is one the app does not translate
- **THEN** every screen falls back to English
- **AND** no Chinese characters appear anywhere in the interface

##### Example: a Japanese device
- **GIVEN** the device language is Japanese
- **WHEN** the caregiver opens the call list, the settings tab, and the role selection screen
- **THEN** every label, button, and status text on those screens is in English


<!-- @trace
source: add-localization
updated: 2026-08-13
code:
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - DECISIONS.md
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Config/Secrets.example.xcconfig
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/App/Info.plist
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w5-localization.md
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
-->

---
### Requirement: System-presented text follows the same rule
Text that the operating system presents on the app's behalf SHALL follow the same language rule as the interface.

#### Scenario: The Bluetooth permission prompt
- **GIVEN** the device language is one the app does not translate
- **WHEN** the permission prompt for Bluetooth is shown
- **THEN** its explanation is in English

#### Scenario: The permission prompt in a supported language
- **GIVEN** the device language is Traditional Chinese
- **WHEN** the permission prompt for Bluetooth is shown
- **THEN** its explanation is in Traditional Chinese


<!-- @trace
source: add-localization
updated: 2026-08-13
code:
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - DECISIONS.md
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Config/Secrets.example.xcconfig
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/App/Info.plist
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w5-localization.md
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
-->

---
### Requirement: Spoken output matches the interface language
Assistive technology SHALL read the interface in the language it is presented in.

#### Scenario: VoiceOver on an English interface
- **GIVEN** the interface is presented in English
- **WHEN** VoiceOver reads a cell and its state
- **THEN** it speaks English
- **AND** it SHALL NOT use a voice for another writing system


<!-- @trace
source: add-localization
updated: 2026-08-13
code:
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - DECISIONS.md
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Config/Secrets.example.xcconfig
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/App/Info.plist
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w5-localization.md
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
-->

---
### Requirement: Grid item titles are the caregiver's data, not interface text
The titles of grid items SHALL be stored as data at the moment they are seeded, in the language current at that time, and SHALL NOT change when the system language changes.

#### Scenario: First launch in English
- **GIVEN** the device language is English
- **WHEN** the app is launched for the first time and the default items are seeded
- **THEN** the four default titles are stored in English

#### Scenario: Changing the system language afterwards
- **GIVEN** default items were seeded in one language
- **WHEN** the system language is changed
- **THEN** the stored titles remain as they were

##### Example: switching to Traditional Chinese
- **GIVEN** the grid was seeded in English, showing "Water", "Turn over", "Bathroom", "Discomfort"
- **WHEN** the device language is changed to Traditional Chinese
- **THEN** the grid still shows "Water", "Turn over", "Bathroom", "Discomfort"
- **AND** the caregiver can rename them if they wish


<!-- @trace
source: add-localization
updated: 2026-08-13
code:
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - DECISIONS.md
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Config/Secrets.example.xcconfig
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/App/Info.plist
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w5-localization.md
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
-->

---
### Requirement: A missing translation degrades to English, never to another language
Where a translation is absent, the app SHALL present the English text rather than any other language.

#### Scenario: A string has no translation for the system language
- **WHEN** a string lacks a translation for the current language
- **THEN** the English text is shown for that string

<!-- @trace
source: add-localization
updated: 2026-08-13
code:
  - Sources/Features/Sponsorship/SponsorshipMocks.swift
  - Tests/SponsorshipTests/SponsorshipStateTests.swift
  - docs/device-verification/w6-sponsorship.md
  - Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift
  - Sources/App/AppRouter.swift
  - Sources/Core/Sponsorship/SponsorshipStore.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsView.swift
  - Sources/Features/CaregiverHome/CaregiverHomeContainer.swift
  - DECISIONS.md
  - Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift
  - Sources/Features/Shared/TwoStepConfirmButton.swift
  - Sources/Core/Sponsorship/SponsorshipProduct.swift
  - Sources/Resources/en.lproj/Localizable.strings
  - Config/Secrets.example.xcconfig
  - Sources/Features/Sponsorship/SponsorshipView.swift
  - Sources/App/Info.plist
  - Sources/Core/Sponsorship/SponsorshipConfiguration.swift
  - Sources/Features/Sponsorship/SponsorshipHostController.swift
  - Sources/Resources/en.lproj/InfoPlist.strings
  - Sources/Resources/zh-Hant.lproj/Localizable.strings
  - Sources/Features/RoleSettings/RoleSettingsViewModel.swift
  - docs/device-verification/w5-localization.md
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/RoleSettings/RoleSettingsHostController.swift
  - Sources/Resources/zh-Hant.lproj/InfoPlist.strings
  - Sources/App/AppDelegate.swift
  - project.yml
  - Sources/Core/Persistence/GridItemStore.swift
  - Sources/Features/Sponsorship/SponsorshipViewModel.swift
  - Tests/PersistenceTests/GridItemStoreTests.swift
  - Sources/Features/PatientGrid/PatientGridView.swift
  - Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift
  - Sources/Features/RoleSelection/RoleSelectionView.swift
  - Sources/Features/RoleSettings/RoleSettingsView.swift
-->