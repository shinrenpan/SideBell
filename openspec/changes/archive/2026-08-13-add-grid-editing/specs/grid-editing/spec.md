## ADDED Requirements

### Requirement: The caregiver can shape the grid to this household's needs
The caregiver SHALL be able to add, rename, delete, and reorder the patient's call items. Adding an item SHALL require only a name.

#### Scenario: Adding an item
- **WHEN** the caregiver adds an item with a name
- **THEN** it appears in the patient's grid as the last item
- **AND** no other information is asked of the caregiver

#### Scenario: Renaming an item
- **WHEN** the caregiver changes an item's name
- **THEN** the patient's grid shows the new name

#### Scenario: Deleting an item
- **WHEN** the caregiver deletes an item and confirms
- **THEN** it no longer appears in the patient's grid

#### Scenario: Reordering items
- **WHEN** the caregiver moves an item to a different position
- **THEN** the patient's grid reflects that order

#### Scenario: A name that cannot be carried
- **WHEN** the caregiver enters a name that is empty, or too long for the wire format
- **THEN** the change is refused and the reason is stated
- **AND** the refusal happens while editing, not when the patient later presses the cell

### Requirement: One item is protected so the patient is never left without a way to call
Exactly one item SHALL be protected. A protected item SHALL NOT be deletable and SHALL always occupy the first position. It SHALL remain renameable.

#### Scenario: The protected item cannot be deleted
- **WHEN** the caregiver views the protected item
- **THEN** no way to delete it is offered

#### Scenario: The protected item stays first
- **WHEN** the caregiver reorders items
- **THEN** the protected item remains in the first position
- **AND** no item can be placed before it

#### Scenario: The protected item can be renamed
- **WHEN** the caregiver renames the protected item
- **THEN** the new name is used
- **AND** the item remains protected

##### Example: a household that says it differently
- **GIVEN** the protected item is named "不舒服"
- **WHEN** the caregiver renames it to "快來"
- **THEN** the patient's first cell reads "快來"
- **AND** it still cannot be deleted or moved

#### Scenario: Protection is a property, not a name or a position
- **WHEN** the system determines whether an item is protected
- **THEN** it SHALL rely on the item's own protected state
- **AND** it SHALL NOT infer protection from the item's name or its position in the order

### Requirement: Only the protected item raises an urgent call
Urgency SHALL NOT be configurable by the caregiver. Only the protected item SHALL be treated as urgent.

#### Scenario: Adding an item
- **WHEN** the caregiver adds an item
- **THEN** no choice about urgency is presented
- **AND** the resulting item is not urgent

#### Scenario: The protected item is triggered
- **WHEN** the patient triggers the protected item
- **THEN** the caregiver's device treats it as an urgent call

### Requirement: Adding stops at the limit, with the reason stated
When the number of items reaches the limit that fits on screen, adding SHALL be refused and the reason SHALL be given.

#### Scenario: The limit is reached
- **WHEN** the number of items reaches the limit
- **THEN** adding is no longer offered
- **AND** the caregiver is told that further items would not be visible to the patient

#### Scenario: Making room
- **GIVEN** the limit has been reached
- **WHEN** the caregiver deletes an item
- **THEN** adding becomes available again

### Requirement: Editing takes effect immediately
Each change SHALL be stored as it is made. There SHALL NOT be a separate step to apply or discard a set of edits.

#### Scenario: Leaving mid-edit
- **WHEN** the caregiver makes a change and leaves the screen without any further action
- **THEN** the change is already in effect

#### Scenario: Deleting is confirmed first
- **WHEN** the caregiver deletes an item
- **THEN** confirmation is required before it is removed
