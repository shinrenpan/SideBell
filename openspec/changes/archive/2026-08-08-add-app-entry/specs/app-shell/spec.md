## MODIFIED Requirements

### Requirement: UIKit lifecycle entry point hosting SwiftUI

The app SHALL launch through a UIKit application and scene lifecycle and SHALL present its SwiftUI content through a hosting controller. The app SHALL NOT use a SwiftUI application lifecycle entry point, because Bluetooth managers must be rebuilt during the earliest launch callback for state restoration to work.

The window root SHALL be a navigation controller hosting the home screen. Role containers SHALL be presented over it rather than pushed onto it, because a role is a mode rather than a step in a hierarchy, and because the home screen must remain available underneath as the destination when a role is left.

#### Scenario: Bluetooth managers are rebuilt at launch

- **WHEN** the system launches the app in the background in response to a Bluetooth event
- **THEN** the transport SHALL be reconstructed during the application launch callback, before any scene becomes active

#### Scenario: Root content is the home screen inside a navigation stack

- **WHEN** the app becomes active in the foreground with no role chosen
- **THEN** the window root SHALL be a navigation controller hosting the home screen, and the window SHALL have an opaque background colour

#### Scenario: Role containers are presented over the root

- **WHEN** a role container is on screen
- **THEN** it SHALL be a full-screen presentation over the root navigation controller, and the root SHALL still hold the home screen underneath

### Requirement: Role is persisted and readable before transport start

The app SHALL persist the selected role, patient or caregiver, in lightweight storage readable synchronously during the application launch callback. Role storage SHALL NOT require the persistent data store to be loaded first.

The same storage layer SHALL hold whether the disclaimer has been acknowledged, for the same reason: both values are needed before any user interface is constructed, and neither justifies loading a database.

#### Scenario: Role is known at the earliest launch callback

- **WHEN** the app launches after a role has previously been selected
- **THEN** the role SHALL be readable during the application launch callback, before any user interface is constructed

#### Scenario: No role selected yet

- **WHEN** the app launches for the first time with no role stored
- **THEN** the role SHALL read as unselected and the transport SHALL NOT be started in either role

#### Scenario: Disclaimer acknowledgement is readable at the same point

- **WHEN** the scene is configured at launch
- **THEN** whether the disclaimer was acknowledged SHALL be readable synchronously, without loading the persistent data store
