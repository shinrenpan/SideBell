## ADDED Requirements

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

### Requirement: The support screen is reachable only from the caregiver side
The support screen SHALL be reachable only from the caregiver's settings. The patient's interface SHALL NOT present any entry point, price, or purchase control.

#### Scenario: The caregiver opens settings
- **WHEN** the caregiver opens the settings tab
- **THEN** an entry point to the support screen is shown

#### Scenario: The patient opens settings
- **WHEN** the patient's settings screen is opened
- **THEN** no entry point to the support screen is present
- **AND** no price or purchase control appears anywhere in the patient's interface

### Requirement: Each option states what the money is for
The support screen SHALL present three options, each showing the price as provided by the App Store for the user's region, together with a description of what that amount is used for.

#### Scenario: The support screen is opened with a network connection
- **WHEN** the caregiver opens the support screen and the store is reachable
- **THEN** three options are listed
- **AND** each shows its localized price and what the amount funds

#### Scenario: Supporting more than once
- **WHEN** the caregiver chooses an option they have already purchased before
- **THEN** the purchase proceeds as a new, independent contribution

### Requirement: The support screen states plainly when it needs a network
The support screen SHALL state that a connection is required when it cannot reach the store, and SHALL offer a way to try again. Every other screen SHALL behave identically whether or not the device has a network connection.

#### Scenario: Opening the support screen with no connection
- **WHEN** the caregiver opens the support screen and the store cannot be reached
- **THEN** the screen states that a connection is needed and offers to retry
- **AND** it SHALL NOT show an empty list or an indefinite loading state

#### Scenario: Using the rest of the app with no connection
- **WHEN** the device has no network connection
- **THEN** calls, alerts, and acknowledgements behave exactly as they do with one

### Requirement: Cancelling is not an error
When the user cancels a purchase, the app SHALL return silently. Other failures SHALL be explained in terms the user can act on.

#### Scenario: The user cancels
- **WHEN** the user dismisses the system purchase sheet without buying
- **THEN** no error message is shown

#### Scenario: The purchase fails for another reason
- **WHEN** a purchase fails for a reason other than cancellation
- **THEN** the screen explains what happened and offers to try again
- **AND** it SHALL NOT show a raw error code

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
