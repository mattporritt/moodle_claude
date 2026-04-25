Read CLAUDE.md if present, but note:
This task is NOT a development task.
This is a problem-definition and Jira ticket authoring task.

---

# Task

Work with the user to turn an initial rough ticket draft into a **complete, high-quality Jira ticket**.

Your goal is to:
- clarify the problem
- define value
- remove ambiguity
- produce a ticket ready for development and peer review

At the end, you will:
- produce a final structured ticket
- update the Jira issue via MCP

---

# Principles

- Do NOT assume missing details
- Do NOT jump to implementation
- Focus on **problem clarity and value**
- Prefer asking questions over guessing
- Make the ticket easy for a developer to pick up without confusion
- When the ticket is likely to be written back through Jira REST string fields, prefer conservative Jira-safe formatting over rich markdown structure

---

# Step 1 — Read the draft

You will be given:
- a partially filled template

You MUST:
- identify gaps
- identify ambiguity
- identify missing value definition
- identify unclear success criteria

---

# Step 2 — Clarification loop (MANDATORY)

Engage the user in a structured clarification process.

Ask targeted questions covering:

## Problem clarity
- What is the actual problem?
- Is this a bug, improvement, or new feature?

If the issue type is not already fixed:
- infer the most likely type:
  - Bug
  - Improvement
  - New Feature
- explain briefly why
- ask the user to confirm before writing it back to Jira

Use this lightweight rubric:
- Bug = existing expected behavior is broken
- Improvement = existing workflow is enhanced
- New Feature = net new capability

If the Jira issue already has a settled type, do not try to override it here.

## Scope
- What is explicitly in scope?
- What is out of scope?

## Users
- Who is affected?
- Are there different roles involved?

## Behaviour
- What happens today?
- What should happen instead?

## Value
- Why does this matter?
- What outcome improves?

## Edge cases
- Are there known edge cases?
- What should happen in failure scenarios?

## Related work
- Are the provided example tickets relevant?
- What patterns should be reused?

---

# Step 3 — Use reference tickets (if provided)

If the user provided similar tickets:
- extract patterns from them
- reuse:
  - structure
  - level of detail
  - testing approach

Do NOT blindly copy content.

---

# Step 4 — Construct the Jira ticket

Produce a clean, structured ticket:

## Required sections

### Summary
Clear, concise, outcome-focused

### Problem statement
- What is broken or missing
- Who it affects

### Current behaviour
- What happens today

### Expected behaviour
- What should happen instead

### Value
- Why this matters
- What improves

### Scope
- In scope
- Out of scope

### Acceptance criteria
Clear, testable outcomes

### Testing instructions
- Preconditions
- Setup
- User role and login steps where relevant
- Admin or configuration steps where relevant
- Concrete user workflow steps
- Expected results
- Regression checks
- Repeated setup paths where applicable

### Notes
- constraints
- assumptions
- technical hints (if relevant)

## Jira formatting rule

When preparing content that may be written back through the current Jira REST string path:
- prefer plain paragraphs and flat bullet lists
- prefer explicit section labels over markdown heading syntax
- separate sections with blank lines
- avoid nested indentation-heavy list structures unless clearly necessary
- avoid HTML and tables

Do not rely on `#`, `##`, or `###` headings rendering correctly through REST string writes unless that renderer has been verified for the target field.

---

# Step 5 — Validate completeness

Before writing to Jira, ensure:

- problem is clear
- value is explicit
- no major ambiguity remains
- acceptance criteria are testable
- testing instructions are end-to-end and concrete enough for a tester unfamiliar with the work to follow

Testing instructions are not complete unless they:
- validate the actual desired behavior, not just that a setting or feature exists
- include real workflow steps where relevant
- include roles, login, setup, and admin configuration when those matter
- include expected results and regression checks where relevant

Reject vague testing instructions such as:
- "confirm the plugin works"
- "verify the feature is available"

Those are incomplete unless expanded into concrete steps and expected outcomes.

Also reject formatting that is likely to render poorly in Jira REST-written fields, such as:
- heading-heavy markdown
- mixed or deeply nested list indentation
- layout that depends on markdown rendering quirks rather than plain readable text

---

# Step 6 — Write back to Jira

Using MCP:

- update the Jira issue description with the structured ticket
- add a comment summarising:
  - what was clarified
  - any assumptions made
- only update issue type if the user explicitly confirmed the suggested type during ticket authoring/refinement

If needed:
- suggest labels (do not enforce yet)

---

# Output

Provide:

1. Final structured ticket
2. Summary of key clarifications
3. Any remaining uncertainties (if any)
4. Confirmation of Jira update

---

# Constraints

- Do NOT implement code
- Do NOT define branching
- Do NOT perform peer review
- Do NOT over-engineer

---

# Success criteria

A developer (human or agent) should be able to:
- pick up the ticket
- understand the problem immediately
- know what to build
- know how to test it
