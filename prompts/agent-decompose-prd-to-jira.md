# PRD -> Jira Decomposition (v2 - with alignment phase)

Read `CLAUDE.md` first and follow it strictly.

Note:
- the previous version of this workflow generated Jira tickets immediately from the PRD
- this version requires a draft decomposition and clarification phase first
- final Jira tickets are generated only after the user responds to the alignment questions

This task is NOT a coding workflow.
This is a planning, decomposition, alignment, and Jira issue authoring workflow.

If you generate Jira tickets without first presenting a draft decomposition and asking clarification questions, you are not following this prompt.

---

# Task

Decompose a completed Product Requirements Document (PRD) into a set of well-structured Jira issues suitable for development.

The goal is to produce Jira issue content that:
- clearly maps to the PRD problem and outcomes
- is understandable without rereading the full PRD
- is independently testable
- gives a developer enough direction to start implementation confidently
- aligns with Moodle Jira field and branching conventions

This workflow is explicitly two-phase:

## Phase 1
- understand the PRD
- draft the decomposition
- surface assumptions and risks
- ask clarification questions
- stop

## Phase 2
- only after the user responds
- generate final Jira-ready tickets

After Phase 2, a local review-artifact step may be used when the user wants the ticket set written into local markdown files before any Jira write-back.

This workflow may be used before any Jira write-back.
Do NOT write directly to Jira in this workflow.
Do NOT implement code.

## Output modes

Choose the output mode that matches the user's request:
- discussion only
- final Jira-ready ticket content in chat
- local review artifacts written to markdown files
- later Jira write-back through a separate step

If local review artifacts are requested:
- keep the Jira fields clearly separated
- use one file per ticket plus an index when that shape is useful
- treat those files as review artifacts before any Jira write-back

---

# Inputs

You may be given:
- a completed PRD in Confluence-compatible markdown
- an existing Epic key, or confirmation that no Epic exists yet
- reference Jira tickets, epics, or related examples

Treat the PRD as the source of truth for the problem, intended outcomes, scope, and non-goals.
Treat references as quality or structure guides, not content to copy.

You MUST also use:
- `config/jira_field_map.yaml` as the source of truth for Jira field names, issue-type rules, testing-instruction rules, and branching policy snapshot
- `docs/moodle-branching.md` when you need canonical Moodle base-branch naming context

---

# Phase 1 - Draft decomposition and alignment

## Step 1 - Understand the PRD

Extract and summarise:
- the core problem
- target users and stakeholders
- key outcomes and success metrics
- proposed solution areas
- explicit non-goals
- dependencies and constraints

Do NOT proceed if the PRD is materially unclear.

If critical ambiguity remains, ask targeted clarification questions first.
Focus especially on:
- unclear scope boundaries
- unclear user value
- unclear success metrics
- missing dependencies
- ambiguous solution slices that would make ticket decomposition weak

## Step 2 - Draft the logical work slices

Break the PRD into a small set of coherent work items.

Each work item should:
- deliver a meaningful unit of user or system value
- be independently understandable
- be independently testable
- avoid mixing unrelated concerns

Useful slice types may include:
- UI or UX changes
- backend logic or APIs
- data model changes
- integration points
- permissions or capabilities
- reporting, observability, or performance work
- documentation work when product or developer documentation must change

Avoid:
- oversized tickets that collapse multiple concerns into one
- tiny tickets that do not represent a meaningful delivery slice
- duplicate tickets with overlapping ownership

If the decomposition feels too broad or too granular, adjust it before presenting it.

## Step 3 - Determine draft issue type for each proposed ticket

For every proposed ticket, determine one draft issue type:
- `Bug`
- `Improvement`
- `New Feature`

Use the issue-type rubric from `config/jira_field_map.yaml`:
- Bug = existing expected behavior is broken or incorrect
- Improvement = existing workflow or capability is enhanced
- New Feature = a new capability is introduced that does not exist today

If issue type is uncertain:
- explain the reasoning briefly
- flag it for user confirmation
- do NOT guess silently

## Step 4 - Draft decomposition output only

In Phase 1, provide a concise draft decomposition only.

For each proposed ticket include:
- proposed issue type
- short summary
- what it delivers in plain English
- why it exists in terms of PRD value
- obvious dependencies
- obvious risks or unknowns

Keep this concise.
Do NOT generate partial Jira tickets in Phase 1.
Do NOT generate descriptions, acceptance criteria, or testing instructions yet.

If docs are impacted:
- call out a documentation work item explicitly
- note that final Jira output should include the `docs_required` label
- note that the final Jira output should include a markdown doc update in scope

## Step 5 - Surface assumptions and risks

Explicitly call out:
- assumptions you had to make
- inconsistencies in the PRD or references
- technical feasibility questions
- any unclear shared-vs-plugin-specific split
- any unclear documentation or validation expectations

## Step 6 - Ask clarification questions (mandatory)

Before any ticket generation, ask a tight set of targeted clarification questions.

Keep the list to about 5-8 questions maximum.

Focus on:
- scope boundaries
- grouping preferences
- how shared work should be separated from plugin-specific work
- unclear technical assumptions
- documentation expectations
- testing expectations
- any issue-type classification that needs confirmation

Then stop and wait for the user response.

---

# Phase 2 - Final Jira ticket generation

Only enter Phase 2 after the user has responded to the clarification questions.

## Step 7 - Apply Moodle branching logic

Use the current policy snapshot in `config/jira_field_map.yaml`.

Per ticket, determine target branches from issue type:

- `New Feature` or `Improvement`
  - target `main`
- `Bug`
  - target `5.1`, `5.2`, and `main`
- `Security`
  - only if explicitly relevant
  - target `4.5`, `5.0`, `5.1`, `5.2`, and `main`

Document target branches clearly for each ticket.

When helpful, also state the rationale in plain language.

Do NOT invent extra targeting heuristics beyond the current mapping and the explicit task context.

## Step 8 - Generate Jira-ready ticket content

For each ticket, produce:

### 1. Issue Type

State the selected issue type clearly.

### 2. Summary

Write a concise, value-oriented summary.

The summary should:
- make sense on its own
- describe what changes for the user or system
- avoid vague verbs like "handle" or "improve" without context

### 3. Description

The description must include:
- the relevant problem context from the PRD
- what this specific ticket delivers
- how it contributes to the overall PRD outcome
- enough context to understand the ticket without opening the PRD

If an Epic key was provided, mention the Epic relationship in a short note.

### 4. Acceptance Criteria

Acceptance criteria must be:
- concrete
- testable
- aligned with the PRD outcomes and success metrics

Prefer bullet points.

### 5. Testing Instructions

Use the testing-instruction structure from `config/jira_field_map.yaml`.

For `Bug`:
- Preconditions
- Setup
- Steps to reproduce the bug
- Apply patch / updated code
- Expected result after fix

For `Improvement` and `New Feature`:
- Preconditions
- Setup
- User role and login steps
- Admin or configuration steps where relevant
- Concrete user workflow steps
- Expected result
- Regression checks
- Repeated setup paths where applicable

Testing instructions must be:
- step-by-step
- end-to-end
- concrete enough for a tester unfamiliar with the work to follow without extra interpretation
- focused on validating the actual desired feature behavior, not just confirming that a setting or plugin exists

Reject vague testing instructions such as:
- "confirm the plugin works"
- "verify the feature is available"

Those are incomplete unless expanded into concrete workflow steps and expected outcomes.

When relevant, include:
- preconditions or prerequisites
- exact setup state
- login and role details
- exact admin navigation and configuration steps
- exact user workflow steps
- expected results after each important action
- regression checks for adjacent behavior
- repeated setup paths where multiple supported modes exist

For example, a TinyMCE plugin support ticket would usually test:
- admin login
- TinyMCE Premium configuration
- Tiny Cloud mode
- self-hosted mode
- a real Moodle editor surface
- the specific plugin behavior itself
- the expected editor output or user workflow result
- absence of regressions in existing Tiny editor behavior

### 6. Developer Direction

This section is required.

Use it to guide implementation without over-prescribing exact code.

Include where relevant:
- similar Jira tickets, issues, or epics to review
- similar existing work or implementation patterns to follow
- existing Moodle components, subsystems, or code areas to inspect
- expected APIs, classes, configuration areas, or extension points likely to be involved
- known technical constraints or risks
- explicit out-of-scope or "do not change" notes where relevant

If similar work exists, reference it explicitly.
Use reference tickets, examples, and discovered patterns to populate this section.

Developer Direction should help a developer find the likely implementation path faster, while still leaving room for engineering judgement.

### 7. Technical Notes

Add only when they materially help delivery.

Useful technical notes may include:
- implementation hints
- important constraints
- architectural boundaries
- follow-on considerations

Do NOT turn technical notes into a full implementation design.

### 8. Dependencies

List ordering or relationship dependencies between tickets.

Examples:
- blocks another ticket
- should land first
- can proceed independently
- shares an integration dependency with another ticket

### 9. Documentation handling

If docs are impacted:
- include a docs ticket when the documentation work is meaningfully separable
- include the `docs_required` label on the relevant final ticket or tickets
- include a markdown doc update in scope

## Step 8.5 - Optional local review artifacts

If the user wants local review artifacts instead of chat-only output:
- write the final Jira-ready content into local markdown files
- separate Jira fields clearly so later MCP or API write-back is straightforward
- prefer one file per ticket plus an index file when reviewing a ticket set
- make it explicit that those files are planning artifacts and have not been written to Jira yet

---

# Final field-mapping and quality checks

## Step 9 - Align with Jira field mapping

Ensure each final ticket can map cleanly to these Jira concepts from `config/jira_field_map.yaml`:
- summary
- description
- issue type
- labels, if relevant
- components, if relevant
- fix versions derived from branching logic when applicable
- testing instructions

If a field or mapping is uncertain:
- flag it explicitly
- do not pretend the mapping is settled

Use labels and components only when the PRD or references provide a reasonable basis.
Do NOT invent labels or components without support.

## Step 10 - Maintain quality bar

Before finalising, check that every ticket:
- is understandable without rereading the PRD
- is testable in isolation
- clearly links back to user or business value
- gives a developer clear implementation direction
- does not duplicate another ticket
- has a realistic scope
- does not rely on hidden assumptions

Also check that:
- the Developer Direction section points toward plausible existing patterns, code areas, or references when those are available
- the testing instructions are concrete enough for an unfamiliar tester to execute end to end
- the testing verifies actual feature behavior, not only the presence of configuration

Then check that the ticket set as a whole:
- covers the meaningful PRD scope
- reflects explicit non-goals correctly
- does not leave major solution areas unassigned
- does not over-fragment the work

If the decomposition is weak, revise it before presenting the result.

---

# Output format

## Phase 1 output

Provide:

### 1. PRD Summary

A short summary covering:
- problem
- users and stakeholders
- outcomes
- solution areas
- non-goals
- dependencies and constraints

### 2. Draft Decomposition Overview

List each proposed ticket with:
- proposed issue type
- short summary
- what it delivers
- why it exists
- dependencies
- risks or unknowns

### 3. Assumptions And Risks

List:
- assumptions made
- inconsistencies or ambiguities
- technical feasibility questions

### 4. Clarification Questions

Ask about 5-8 targeted questions maximum.

Then stop.
Do NOT generate final Jira tickets in Phase 1.

## Phase 2 output

After the user responds, provide:

### 1. Final Ticket Overview

List each final ticket with:
- ticket number or short identifier
- summary
- one-line purpose

### 2. Detailed Jira Tickets

For each ticket include:
- Issue Type
- Summary
- Description
- Acceptance Criteria
- Testing Instructions
- Developer Direction
- Target Branches
- Dependencies, if any
- Notes, if any

### 3. Validation Output

At the end provide:
- number of tickets generated
- assumptions made
- any areas needing user confirmation
- any suggested follow-up, such as splitting or merging tickets later

If local review artifacts were requested, also provide:
- the output directory
- the filenames created
- confirmation that the files are Jira-ready planning artifacts only

---

# Constraints

- Do NOT write directly to Jira
- Do NOT assume MCP write-back
- Do NOT omit testing instructions in Phase 2
- Do NOT proceed past critical ambiguity without clarification
- Do NOT perform a peer-review step
- Do NOT implement code
- Do NOT generate final tickets before the alignment phase is completed

---

# Success criteria

The output should leave the user with a Jira-ready issue set that:
- collectively covers the PRD scope
- respects Moodle issue-type and branch-target rules
- is understandable and testable ticket by ticket
- is produced only after a mandatory draft decomposition and clarification phase
- is ready for later Epic linking, Jira write-back, and development planning
