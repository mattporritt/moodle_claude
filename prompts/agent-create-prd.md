Read `CLAUDE.md` if present, but note:
This task is NOT a coding workflow.
This is a product-definition and PRD authoring workflow.

---

# Task

Work with the user to turn a partially completed PRD draft into a **complete, high-quality Product Requirements Document (PRD)** in **Confluence-compatible markdown**.

Your goal is to:
- clarify the problem
- make user and business value explicit
- identify missing scope, non-goals, dependencies, and risks
- define measurable success outcomes
- produce a PRD concrete enough to support later Jira epic and ticket creation

This workflow is for PRD creation, not coding.
Do NOT turn the session into implementation planning unless the user explicitly asks for it.

In most cases, one PRD will map to one Jira epic later.
Sometimes that epic already exists and sometimes it does not.
Your job here is to produce the PRD that makes that next step easier.

---

# Principles

- Do NOT invent product facts that the user has not provided or confirmed
- Do NOT hide weak areas in vague wording
- Do NOT jump into technical implementation detail unless it materially clarifies product scope
- Keep the problem, user value, and expected outcomes explicit
- Ask targeted clarification questions instead of making silent assumptions
- Use one or two rounds of clarification only; prefer focused, high-signal questions
- Keep the final PRD readable by humans and usable as later Jira-authoring source material

---

# Inputs

You may be given:
- a partially completed PRD draft based on the repo template
- rough notes or incomplete bullet points
- links or summaries for similar Jira tickets
- links or summaries for similar epics
- other examples, docs, or references

Treat those references as supporting context, not as source text to copy.

---

# Step 1 — Read the PRD draft

Start by reading the draft against the expected PRD structure:

1. Activity Name / Status / Owner / Target Increment
2. The Problem (The Why)
3. Strategy & Success Metrics (The Goal)
4. The Hypothesis
5. Proposed Solution & User Stories (The What)
6. Product Non-Goals (The Not Now)
7. Impacts & Dependencies (The Who)

You MUST identify:
- missing sections
- weak or generic sections
- places where the problem is implied but not stated
- places where user or business value is unclear
- missing success metrics or measurable outcomes
- unclear scope boundaries
- absent dependencies, risks, or impacted stakeholders
- areas that are too vague to support later Jira epic/ticket creation

---

# Step 2 — Clarification loop

Use a structured clarification loop with at most two rounds.

Prefer one round when the gaps are small.
Use a second round only when the first answers still leave important ambiguity.

Ask targeted questions about:

## The problem
- What exactly is wrong, missing, or underperforming today?
- Who experiences the problem most directly?
- What is the current pain, cost, risk, or missed opportunity?

## Value and outcomes
- Why does solving this matter?
- What user, business, or operational outcome should improve?
- How will success be measured?

## Scope
- What is definitely in scope?
- What is explicitly out of scope?
- What should wait for a later phase?

## Solution framing
- What kind of product change is being proposed?
- Are user stories needed to make scope or workflow intent clearer?
- Are there important edge cases or workflow expectations that should be called out?

## Dependencies and impact
- Which teams, systems, approvals, or sequencing constraints matter?
- Who needs to be involved, informed, or unblocked?
- What risks or assumptions should be visible in the PRD?

When asking questions:
- group related questions together
- keep them concise
- prioritise the smallest set of questions that materially improves the PRD

---

# Step 3 — Use references carefully

If the user provides similar Jira tickets, epics, or other examples:
- extract useful patterns in problem framing, scope definition, or level of detail
- reuse the helpful structure or quality bar
- compare them against the current PRD draft to spot missing areas

Do NOT:
- copy wording blindly
- inherit irrelevant scope
- assume the reference solution or rollout is correct for this case

If a reference seems misleading or only partially applicable, say so briefly and continue with the parts that are genuinely useful.

---

# Step 4 — Produce the final PRD

After clarification, produce a finished PRD in **Confluence-compatible markdown**.

Use simple markdown only:
- headings
- bullet lists
- numbered lists
- short emphasis where helpful

Avoid output formats that may translate poorly:
- HTML blocks
- nested tables unless clearly necessary
- task-list syntax
- repo-specific markup

Keep the final PRD in this structure:

## Activity details
- Activity Name
- Status
- Owner
- Target Increment

## The Problem (The Why)
- clear problem statement
- affected users and stakeholders
- current pain or limitation
- why it matters now

## Strategy & Success Metrics (The Goal)
- desired outcome
- business or user value
- measurable success metrics

## The Hypothesis
- explicit hypothesis statement
- key assumptions

## Proposed Solution & User Stories (The What)
- product-level proposed solution
- in-scope items
- user stories where useful
- notable behavioural expectations, constraints, or edge cases

## Product Non-Goals (The Not Now)
- explicit non-goals
- deferred ideas that belong in later phases

## Impacts & Dependencies (The Who)
- impacted stakeholders
- dependencies
- risks and concerns
- notes that will help later epic/ticket creation

The final PRD should be concrete enough that a later agent could use it to:
- define one likely Jira epic
- break that epic into sensible Jira tickets
- preserve the original problem, value, scope, and success measures

---

# Step 5 — Quality check before finalising

Before you present the PRD, verify that:
- the problem is explicit, not implied
- the user or business value is explicit
- the outcome is concrete
- success metrics are measurable or at least observable
- scope and non-goals are clearly separated
- dependencies and impacted stakeholders are named
- the wording is strong enough to support later Jira authoring
- the document still reads like a PRD rather than an implementation spec

If a critical unknown remains, state it clearly in a short `Open questions` section at the end rather than burying it.

---

# Output

Provide:

1. The final PRD in Confluence-compatible markdown
2. A short summary of the key clarifications made
3. A short list of any open questions that still need confirmation, if any

---

# Constraints

- Do NOT write code
- Do NOT create Jira tickets automatically in this workflow
- Do NOT assume the PRD must include engineering implementation details
- Do NOT skip clarification when the problem, value, or outcomes are weak

---

# Success criteria

The finished PRD should allow a later human or agent to:
- understand the problem quickly
- understand why it matters
- understand what is in scope and out of scope
- understand how success will be judged
- use the PRD as the basis for Jira epic and ticket creation
