## ADDED Requirements

### Requirement: A call that cannot be sent is queued rather than failed

When the transport reports that a call could not be sent because no peer is connected, the system SHALL hold that call as pending rather than reporting failure to the patient.

The target population pays a real cost for every interaction — sustained gaze for eye control, physical effort for a single finger. Making the patient retry until a caregiver returns delegates polling to the person least able to perform it.

#### Scenario: Sending with no caregiver connected

- **WHEN** the patient triggers a call and no caregiver is connected
- **THEN** the call SHALL become pending, and the patient SHALL see it as waiting rather than as failed

### Requirement: Pending calls are sent when the connection returns

The system SHALL send pending calls when the transport reports that a peer has connected, without waiting for a timer and without polling.

Polling on a fixed interval both delays delivery (up to a full interval after the caregiver returns) and wastes power. The transport already reports connection changes as events.

#### Scenario: Delivery on reconnection

- **WHEN** a call is pending and the transport reports a connected peer
- **THEN** that call SHALL be sent without further user action

#### Scenario: Multiple pending calls

- **WHEN** more than one call is pending and the transport reports a connected peer
- **THEN** all pending calls SHALL be sent, in the order the patient triggered them

### Requirement: A call gives up after three minutes without a response

The system SHALL mark a call as unanswered when three minutes pass from the moment the patient triggered it without an acknowledgement arriving, whether or not the call was ever successfully transmitted.

Three minutes is chosen from the patient's side, not from retry cost: one minute is too short — a caregiver visiting the bathroom would be declared a failure — while beyond three minutes the patient is being kept waiting on a channel that is not working, when they should be seeking help another way.

#### Scenario: No acknowledgement within the window

- **WHEN** three minutes pass after a call was triggered and no acknowledgement has arrived
- **THEN** the call SHALL become unanswered, and SHALL no longer be retried

#### Scenario: Acknowledgement arrives inside the window

- **WHEN** an acknowledgement arrives before the three minutes elapse
- **THEN** the call SHALL become acknowledged and the timeout SHALL be cancelled

#### Scenario: Delivered but never acknowledged

- **WHEN** a call is transmitted successfully but no acknowledgement arrives within three minutes
- **THEN** the call SHALL become unanswered — the same outcome as a call that was never transmitted

##### Example: state by outcome

| Transmitted | Acknowledged within 3 min | Final state |
| ----------- | ------------------------- | ----------- |
| yes | yes | acknowledged |
| yes | no | unanswered |
| no, queued then sent on reconnect | yes | acknowledged |
| no, still queued at timeout | n/a | unanswered |

### Requirement: The patient sees three call states and no more

The system SHALL expose exactly three states for a call: waiting, acknowledged, and unanswered. It SHALL NOT distinguish, in anything the patient sees, between "not yet transmitted" and "transmitted but not acknowledged".

That distinction carries no action value for the patient: they cannot change their distance from the caregiver. Only the final state carries action value — it tells them this channel is not working and to seek help another way. Mechanism details such as retry counts and intervals SHALL NOT be surfaced.

#### Scenario: Queued and transmitted look the same

- **WHEN** one call is queued because no caregiver is connected and another has been transmitted but not acknowledged
- **THEN** both SHALL be presented as waiting, with no visible difference

#### Scenario: Terminal state is distinguishable

- **WHEN** a call becomes acknowledged or unanswered
- **THEN** each SHALL be visually distinct from waiting and from each other

### Requirement: Call state does not survive a restart

The system SHALL hold call state in memory only. A call that was waiting when the app stopped SHALL NOT be restored, retried, or shown on the next launch.

A call revived after a restart is a false alarm rather than a late message — the need it described has usually passed, and false alarms erode the caregiver's trust in the alert.

#### Scenario: Waiting call does not return

- **WHEN** a call is waiting, the app is terminated, and the app is launched again
- **THEN** no call SHALL be pending, no retry SHALL occur, and no call state SHALL be shown
