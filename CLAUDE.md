# Claude Code Instructions For Moodle LMS Work

## Scope

- This repository is a command surface for Moodle development.
- The Moodle codebase lives at `MOODLE_DIR` from `.claude.env`.
- This repo lives inside the Moodle checkout at `~/projects/moodle/claude`, so the parent directory is the default Moodle target.
- The agentic orchestrator lives in a separate sibling checkout at `AGENTIC_ORCHESTRATOR_DIR` when available.
- Run commands from the repository root.
- PHPCS and PHPCBF run on the host against the parent Moodle checkout.
- PHPUnit, Behat, install, and runtime commands use the Docker-backed `./bin/*` wrappers.
- Browser MCP and Atlassian MCP are optional Claude Code client integrations that complement this harness.

## Non-negotiables

- Follow Moodle coding style and conventions:
  - https://moodledev.io/general/development/policies/codingstyle
- Default PHPCS standard is `moodle`; use `moodle-extra` only when the task explicitly calls for the stricter ruleset.
- Reuse existing Moodle APIs/patterns before introducing new abstractions.
- Keep changes minimal, localized, and issue-focused.

## Standard workflow

1. Classify the task:
   - trivial local edit in already-identified files, or
   - non-trivial Moodle task requiring orchestrator-first discovery
2. For non-trivial Moodle tasks, use orchestrator first for discovery and pattern-finding before coding, normally through its `query` workflow.
3. If orchestrator availability or health has not been manually verified, explicitly report that and block orchestrator-dependent work until manual verification happens.
4. For trivial local edits, proceed directly with the smallest viable local change.
5. After discovery, implement the smallest viable change directly in the local Moodle checkout.
6. Run quality gates:
   - `./bin/phpcs <touched paths>`
   - `./bin/phpunit <targeted tests>`
   - `./bin/behat <targeted tags>` for behaviour/UI changes
   - `./bin/smoke` when validating a fresh harness setup
   - `./bin/feature-smoke` when validating the full install/init/test workflow
7. Fix failures before proposing commit.
8. Prepare commit suggestions:
   - one logical change per commit
   - tests included in the same commit that changes behaviour
   - branch and commit message aligned to Moodle issue style: `MDL-12345 component_name: concise imperative summary`

## Orchestrator-first policy

- Use orchestrator before coding for non-trivial Moodle tasks, especially:
  - implementation-pattern discovery
  - "how does Moodle do X?"
  - cross-source retrieval across docs, code, and site context
  - broader debugging and investigation
- Treat orchestrator as a thin context assembler over `agentic_devdocs`, `agentic_indexer`, `agentic_sitemap`, and optionally `agentic_debug`.
- The most relevant current orchestrator entrypoints are:
  - `health` for preflight and trust checks
  - `query` for grouped context retrieval
  - `pilot-run` when a supervised live trial artifact is useful
  - `review_bundle` when a verification artifact is needed
- Do not use orchestrator for clearly local edits where the target files and change shape are already known.
- When a workflow depends on orchestrator-style discovery, do not guess if orchestrator has not been manually verified. Report the gap and stop that path.
- Manual verification currently means:
  - a real orchestrator config such as `config.local.toml` exists
  - `PYTHONPATH=src python3 -m agentic_orchestrator.cli health --config ./config.local.toml` completes without `FAIL`
  - at least one real `query` or `pilot-run` succeeds against that config
- Once discovery is complete, make direct local Moodle edits and use the existing `./bin/*` harness for linting, tests, runtime checks, and Docker operations.
- Remember the boundaries:
  - orchestrator is not a code editor
  - orchestrator is not the Docker/test harness
  - orchestrator health is conservative and does not guarantee perfect retrieval quality

## MCP workflow

- Use browser MCP for UI checks, console/network inspection, screenshots, and cross-browser reproduction.
- Use Atlassian MCP for Jira and Confluence search, issue/page retrieval, and small coordination tasks.
- When a task depends on an MCP server, start with a lightweight connectivity check:
  - Browser: open a blank or `data:` page and confirm a snapshot loads.
  - Atlassian: fetch current user info and list accessible resources.
- Keep MCP use task-focused. Do not browse aimlessly when a targeted read or reproduction is enough.
- Do not hardcode tenant-specific Atlassian IDs, tokens, or machine-specific MCP details in committed files.

## Working with a large codebase

- Prefer targeted search (`rg`) and narrow edits.
- If unsure about conventions, find and mirror nearby Moodle patterns.
- Avoid broad refactors unless explicitly requested.

## Git expectations

- One logical change per commit.
- Branch naming should align with Moodle workflow and issue key when known.
- Commit messages should use Moodle issue style: `MDL-12345 component_name: concise imperative summary`

## Practical rules for this repo

- Place any smoke-test artifacts in `/_smoke_test` at repo root.
- Do not hardcode machine-specific absolute paths in committed scripts.
- Prefer `./bin/changed-files` and `./bin/preflight` to keep checks scoped.
- Remember that `./bin/smoke` and `./bin/feature-smoke` validate the shell and Docker harness, not Claude Code MCP connections.

## Output expectations

- Summarise what changed and why.
- List exact test/lint commands run and outcomes.
- Suggest commit message(s) aligned to the change.
