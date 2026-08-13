## MODIFIED Requirements

### Requirement: A first launch is seeded with four default items

The system SHALL create two items the first time the grid is used: one protected item for distress, and one for drinking water. Seeding SHALL happen once.

Four defaults assumed needs on the caregiver's behalf — turning over is useless to a patient who can walk, and the needs that matter most to a given household (changing a nappy, suctioning) were never among them. Two is the smallest set that leaves the device usable on arrival: one guaranteed way to call for help, and one ordinary need that shows what a cell looks like. The rest is for the caregiver to add.

The grid can no longer become empty, because the protected item cannot be deleted.

#### Scenario: First launch creates the defaults

- **WHEN** the grid is opened on a device with no stored items and no prior seeding
- **THEN** two items SHALL exist: a protected item for distress, and one for drinking water
- **AND** the protected item SHALL be first

#### Scenario: The grid cannot be emptied

- **WHEN** the caregiver deletes every item that can be deleted
- **THEN** the protected item SHALL remain
- **AND** the patient SHALL still have a way to call for help
