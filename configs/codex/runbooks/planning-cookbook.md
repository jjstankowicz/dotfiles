# Planning Cookbook

Use this runbook when writing or updating:

- canonical queue files such as `plans/next-steps.md`
- standalone zoom-in planning docs linked from a canonical queue file

## Core rule

`Priority` and `Backlog` are two views of the same items.

- `Priority` is the ordered view.
- `Backlog` contains brief branch-sized scope, deliverables, and gates.

Do not put detailed checklist content directly in `Priority`.

## Required structure

### Priority

`Priority` contains only simple item titles in execution order.

Allowed content:

- one checklist line per item
- the exact title that appears in `Backlog`

Not allowed:

- deliverables
- gates
- notes
- prose description
- nested detail of any kind

Example:

```md
## Priority

- [ ] `session-object-state`
- [ ] `chat-request-selection-context`
- [ ] `artifact-object-metadata`
```

### Backlog

`Backlog` contains the same items as `Priority`, but as detailed entries.

Each backlog entry should:

- use the exact same title as the corresponding `Priority` item
- contain the details for that item
- remain unordered relative to the other backlog entries

Keep each canonical backlog card concise:

- brief context and current status;
- branch-sized deliverables and completion gates;
- unresolved decisions needed to proceed;
- a link to the zoom-in when implementation needs more detail.

Detailed implementation steps and test expectations belong in the zoom-in.
Do not accumulate successive approvals, test-result narratives, commit IDs,
agent assignments, or live-run reports in either planning file. Conversation,
Git, and existing result artifacts retain execution history.

Example:

```md
## Backlog

### `session-object-state`

Deliverables:

- [ ] Add `ChatSessionState`.
- [ ] Add `SessionObject`.

Gates:

- [ ] Session state stores reusable objects.
```

## Mapping rule

Every item in `Priority` must have exactly one matching entry in `Backlog`.

Every detailed entry in `Backlog` must have exactly one matching item in `Priority`.

If an item is too small to deserve its own `Backlog` entry, it should not be in `Priority`.

## Zoom-in docs

Create a zoom-in for an existing canonical backlog card when it needs slice-level
implementation detail or detailed test expectations. Track it in Git and link it
from that card. Keep those details in the zoom-in rather than copying them into
the queue. A simple card needs no zoom-in.

Standalone zoom-in docs follow the same pattern, but the item mapping is usually:

- `Priority`: execution order for independently reviewable behavior slices
- `Backlog`: implementation slices, relevant decisions, and test expectations

The same rule still applies:

- `Priority` contains titles only
- `Backlog` contains details only

## Current status and decisions

Keep only the current status and decisions or unresolved constraints needed to
continue. Replace stale next actions instead of appending another progress entry.
Keep detailed decisions in the zoom-in when one exists; the queue needs only a
brief status and link.

Reserve completed checkboxes for completed work; approval alone does not mean
implementation or validation is complete. Establish permission from the current
request and conversation, without maintaining a separate authorization ledger.
The shared human approval and review checkpoints still apply.

## Anti-patterns

Do not do these:

- put detailed checklist bullets directly under `Priority`
- use `Priority` as a prose summary section
- create backlog entries that do not appear in `Priority`
- create priority items that expand inline instead of pointing to one backlog entry
