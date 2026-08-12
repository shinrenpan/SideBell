## ADDED Requirements

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

### Requirement: Permission to notify is requested at a moment the caregiver understands
Permission for notifications SHALL be requested when the caregiver role is first entered, and SHALL NOT be requested at app launch.

#### Scenario: Entering the caregiver role for the first time
- **WHEN** the caregiver role is entered for the first time
- **THEN** the system asks for notification permission

#### Scenario: Entering the caregiver role again
- **WHEN** the caregiver role is entered on a later occasion
- **THEN** the system SHALL NOT ask again, whatever the earlier answer was

### Requirement: An interrupted alert resumes
When system audio is interrupted, an outstanding urgent alert SHALL resume once the interruption ends.

#### Scenario: A phone call interrupts the alert
- **GIVEN** an urgent call is alerting
- **WHEN** an incoming phone call interrupts the audio
- **AND** the phone call ends while the urgent call is still outstanding
- **THEN** the alert resumes
