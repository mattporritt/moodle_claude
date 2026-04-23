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
- Setup
- Steps
- Expected results

### Notes
- constraints
- assumptions
- technical hints (if relevant)

---

# Step 5 — Validate completeness

Before writing to Jira, ensure:

- problem is clear
- value is explicit
- no major ambiguity remains
- acceptance criteria are testable
- testing instructions are usable

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
