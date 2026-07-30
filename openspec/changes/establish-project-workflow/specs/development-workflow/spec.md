## ADDED Requirements

### Requirement: Confirmed requirements enter through an Issue

Every confirmed requirement MUST have one GitHub Issue added to the `CloudPilot-PVE Development` Project before an OpenSpec proposal or development branch is created. The Issue MUST describe the goal, scope, and testable acceptance criteria.

#### Scenario: A new requirement is confirmed

- **WHEN** a requirement is approved for planning
- **THEN** an Issue is created and added to the Project with status `Backlog`

### Requirement: Planned work has priority and iteration

Every Issue MUST have a Priority and Iteration before its status changes from `Backlog` to `Planned` or `Spec`.

#### Scenario: Work is scheduled

- **WHEN** a Project item receives a Priority and Iteration
- **THEN** its status may change to `Planned`

#### Scenario: Work is not scheduled

- **WHEN** either Priority or Iteration is missing
- **THEN** OpenSpec work and implementation MUST NOT begin

### Requirement: OpenSpec is traceable to the Issue

Every non-trivial or behavior-changing requirement MUST have an OpenSpec change that references its Issue. Implementation MUST NOT begin until the proposal is approved.

#### Scenario: Specification begins

- **WHEN** the scheduled requirement enters OpenSpec drafting or approval
- **THEN** the Project status is changed to `Spec` and the proposal references the Issue

#### Scenario: Proposal is approved

- **WHEN** the OpenSpec proposal is approved and implementation starts
- **THEN** the Project status is changed to `In Progress`

### Requirement: Project status follows the delivery phase

The responsible AI or developer MUST synchronize the Project status before entering each delivery phase. A failed status update MUST stop progression and be reported.

#### Scenario: Verification begins

- **WHEN** implementation is ready for tests and read-only review
- **THEN** the Project status is changed to `Testing` before verification runs

#### Scenario: Pull request is created

- **WHEN** verification passes and a PR is created
- **THEN** the Project status is changed to `In Review`

#### Scenario: Project synchronization fails

- **WHEN** a required Project update cannot be completed
- **THEN** the next development action is not performed and the failure is reported

### Requirement: Pull request closes the tracked Issue

Every PR MUST reference the OpenSpec change and use `Closes #<issue>` for the tracked requirement. The Issue, rather than the PR, MUST remain the single Project item.

#### Scenario: Pull request is merged

- **WHEN** the approved PR is merged into `main`
- **THEN** GitHub closes the Issue and the Project item reaches `Done`

#### Scenario: Pull request remains under review

- **WHEN** CI, required approval, or review conversations are incomplete
- **THEN** the Project item remains `In Review` and the PR MUST NOT be merged
