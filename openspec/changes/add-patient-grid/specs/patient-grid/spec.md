## ADDED Requirements

### Requirement: The grid fills the screen with large targets

The patient screen SHALL present the items as a grid that occupies all available space below the navigation bar. Each cell SHALL be at least 150 points on its shorter side with at least 24 points of spacing, and the number of columns SHALL adapt to the available width rather than being fixed.

Eye control accuracy scales with the physical size of the target. A fixed column count would produce unusably narrow cells on a phone held in portrait and waste space on a tablet.

#### Scenario: Cells meet the minimum size

- **WHEN** the grid is shown with four items on any supported device
- **THEN** every cell SHALL be at least 150 points on its shorter side

#### Scenario: Column count adapts to width

- **WHEN** the grid is shown on a wide screen and then on a narrow one
- **THEN** the number of columns SHALL differ, and cells SHALL remain at or above the minimum size in both

### Requirement: A single tap sends the call

Triggering a cell SHALL require nothing beyond a plain tap — no long press, no double tap, no swipe, no drag.

The system's dwell control issues taps and nothing else. Any interaction beyond a tap would put the primary function of the product out of reach of the users it exists for.

#### Scenario: Tap sends immediately

- **WHEN** the patient taps a cell
- **THEN** a call carrying that item's title, command code and urgency SHALL be sent, with no confirmation step

#### Scenario: No gesture alternatives exist

- **WHEN** the patient screen is inspected for interactive elements
- **THEN** no element required for sending a call SHALL depend on a gesture other than a tap

### Requirement: Each cell shows the state of its own most recent call

Each cell SHALL show the state of the most recent call sent from it: waiting, acknowledged, or unanswered. A cell that has not been used in this session SHALL show no state.

#### Scenario: State appears on the originating cell

- **WHEN** the patient taps one cell and the call is waiting
- **THEN** that cell SHALL show waiting, and other cells SHALL show no state

#### Scenario: Acknowledgement updates the originating cell

- **WHEN** a caregiver acknowledges a call
- **THEN** the cell it came from SHALL show acknowledged

#### Scenario: Repeated use replaces the previous state

- **WHEN** the patient taps a cell whose previous call was unanswered
- **THEN** that cell SHALL show waiting for the new call, replacing the previous state

### Requirement: Call state is conveyed by more than colour

State SHALL be distinguishable without relying on colour alone: each state SHALL carry a distinct symbol or text in addition to any colour, and SHALL be announced to VoiceOver.

Relying on colour alone excludes users with colour vision deficiency, and states that only exist visually do not exist for blind users at all.

#### Scenario: States differ without colour

- **WHEN** the grid is viewed without colour information
- **THEN** waiting, acknowledged and unanswered SHALL still be distinguishable from each other

#### Scenario: State reaches VoiceOver

- **WHEN** VoiceOver focuses a cell that has a call state
- **THEN** the state SHALL be announced along with the cell's title

### Requirement: Connection status is permanently visible

The patient screen SHALL show, at all times and without scrolling, whether calls can currently reach a caregiver. The indicator SHALL NOT rely on colour alone.

This is the patient's only way to know whether the product is working at all. Its meaning is "a call would reach someone right now" — not "a Bluetooth link exists".

#### Scenario: Indicator is always on screen

- **WHEN** the patient screen is shown, with the grid scrolled to any position
- **THEN** the connection indicator SHALL be visible

#### Scenario: Indicator reflects real reachability

- **WHEN** a caregiver stops being reachable
- **THEN** the indicator SHALL change within seconds, without the patient interacting with the screen

### Requirement: Triggering a cell is announced aloud

The system SHALL speak the item's title through the device speaker when a cell is triggered.

Patients who cannot see the screen well, or at all, otherwise have no way to confirm which cell they hit — and with eye control, hitting the wrong cell is a realistic outcome.

#### Scenario: Title is spoken on trigger

- **WHEN** the patient triggers a cell titled 喝水
- **THEN** the device SHALL speak 喝水

#### Scenario: Rapid triggers do not queue up indefinitely

- **WHEN** several cells are triggered in quick succession
- **THEN** the most recent title SHALL be spoken, and earlier pending announcements SHALL be discarded rather than played in sequence

### Requirement: Acknowledgement is felt or heard, not only seen

When a caregiver acknowledges a call, the system SHALL notify the patient through a non-visual channel — haptic feedback, a short sound, or both — in addition to updating the cell.

The acknowledgement is the patient's only assurance that someone is coming. A checkmark that exists only on screen does not exist for a blind patient, and a patient who cannot see well may not be looking at the moment it appears.

#### Scenario: Non-visual feedback on acknowledgement

- **WHEN** an acknowledgement arrives for a call the patient sent
- **THEN** the device SHALL produce haptic or audible feedback, and the originating cell SHALL show acknowledged

#### Scenario: Feedback distinguishes acknowledgement from failure

- **WHEN** a call becomes unanswered
- **THEN** any feedback produced SHALL be distinguishable from the acknowledgement feedback, so the two outcomes are not confused

### Requirement: The patient screen keeps the display awake

While the patient screen is showing, the system SHALL prevent the device from dimming and locking. It SHALL restore normal behaviour when the patient role is left.

A locked device cannot be woken by eye tracking, which does not operate on the lock screen. Once the display sleeps, the calling system is effectively offline and the patient has no way to bring it back.

#### Scenario: Display stays awake on the patient screen

- **WHEN** the patient screen has been showing with no interaction for longer than the system's auto-lock delay
- **THEN** the display SHALL still be on

#### Scenario: Normal behaviour returns on leaving

- **WHEN** the patient role is left
- **THEN** the device SHALL resume its normal auto-lock behaviour
