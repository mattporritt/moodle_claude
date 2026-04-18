# Claude Code Instructions For Moodle LMS Work

## Scope

- This repository is a command surface for Moodle development.
- The Moodle codebase lives at `MOODLE_DIR` from `.claude.env`.
- This repo lives inside the Moodle checkout at `~/projects/moodle/claude`, so the parent directory is the default Moodle target.
- The agentic orchestrator lives in a separate sibling checkout at `AGENTIC_ORCHESTRATOR_DIR` when available, typically `~/projects/agentic_orchestrator`.
- Run commands from the `claude/` repository root, not the parent Moodle checkout.
- PHPCS and PHPCBF run on the host against the parent Moodle checkout.
- PHPUnit, Behat, install, and runtime commands use the Docker-backed `./bin/*` wrappers.
- JavaScript build commands should use the host-side `./bin/grunt` helper from the `claude/` repo root.
- `./bin/upgrade` is the thin wrapper for Moodle CLI upgrade in the web container.
- Chrome MCP, Firefox MCP, and Atlassian MCP are optional Claude Code client integrations that complement this harness.

## Non-negotiables

- Follow Moodle coding style and conventions:
  - https://moodledev.io/general/development/policies/codingstyle
- Default PHPCS standard is `moodle`; use `moodle-extra` only when the task explicitly calls for the stricter ruleset.
- Reuse existing Moodle APIs/patterns before introducing new abstractions.
- Keep changes minimal, localized, and issue-focused.
- For Moodle AMD JavaScript work, `amd/src/` is the source of truth and `amd/build/` is generated output.
- For newly created files, full-file PHPCS is appropriate.
- For edits in large existing legacy files, focus on keeping changed lines clean rather than fixing every historical PHPCS issue in the file.
- When generating new Moodle files, use local author metadata from `.claude.identity` and format it as:
  - `@copyright  {year} {Author} <{email}>`
- If `.claude.identity` is missing and the task requires creating new Moodle source files, stop that path and say the local identity file must be created or a fallback explicitly approved first.

## Standard workflow

1. Classify the task:
   - trivial local edit in already-identified files, or
   - non-trivial Moodle task requiring orchestrator-first discovery
2. For non-trivial Moodle tasks, use orchestrator first for discovery and pattern-finding before coding, normally through its `query` workflow.
3. If orchestrator availability or health has not been manually verified, explicitly report that and block orchestrator-dependent work until manual verification happens.
4. For trivial local edits, proceed directly with the smallest viable local change.
5. After discovery, implement the smallest viable change directly in the local Moodle checkout.
6. Run quality gates:
   - `./bin/phpcs <touched paths>` for explicit whole-file linting
   - `./bin/preflight` for the normal targeted PHPCS pass
   - `./bin/preflight --changed-lines` when editing large legacy files and you want changed-line-focused PHPCS
   - `./bin/grunt amd --files=<amd/src path>` or `./bin/grunt amd --root=<component>` for targeted Moodle AMD rebuilds when JS changed
   - `./bin/phpunit <targeted tests>`
   - `./bin/behat <targeted tags>` for behaviour/UI changes
   - `./bin/upgrade` when plugin discovery or upgrade-sensitive metadata changed
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
  - `verify` for fast preflight — preferred quick readiness check; returns `READY`, `DEGRADED`, or `NOT_READY`
  - `health` for authoritative preflight and trust checks; use `--json` for machine-readable output, `--deep` for routing/eval baseline checks
  - `query` for grouped context retrieval; supports `--route-mode task|auto|manual` and `--tools docs,code,site,debug`
  - `pilot-run` when a supervised live trial artifact is useful
  - `pilot-review <trial-id>` to record a human outcome on a completed trial
  - `pilot-report` to summarise recorded pilot trials
  - `review_bundle` when a verification artifact is needed: `PYTHONPATH=src python3 -m agentic_orchestrator.review_bundle --config ./config.local.toml`
  - `install-siblings` to bootstrap all sibling tools in one step (clones repos, creates venvs, runs `composer install` for `agentic_debug`)
- Do not use orchestrator for clearly local edits where the target files and change shape are already known.
- When a workflow depends on orchestrator-style discovery, do not guess if orchestrator has not been manually verified. Report the gap and stop that path.
- Manual verification currently means:
  - warnings must be surfaced explicitly, not silently ignored
  - a real orchestrator config such as `config.local.toml` exists in the sibling orchestrator repo, not in `~/projects/moodle/claude`
  - `PYTHONPATH=src python3 -m agentic_orchestrator.cli verify --config ./config.local.toml` returns `READY` or `DEGRADED` (not `NOT_READY`) when run from `~/projects/agentic_orchestrator`
  - at least one real `query` or `pilot-run` succeeds against that config when run from `~/projects/agentic_orchestrator`
- Treat warnings pragmatically:
  - stale sitemap or similarly stale resource warnings can still allow docs/code pattern discovery, but reduce trust in site-context freshness
  - warnings affecting `agentic_devdocs`, `agentic_indexer`, or `agentic_debug` contracts or tool availability should be called out as reducing trust in those specific sources
  - if the task depends heavily on a warned source, pause and say that manual judgement or verification is required before relying on it
- Before relying on orchestrator results, inspect `usable_for` in the `verify --json` or `health --json` output:
  - `usable_for.docs_lookup` — devdocs wiring, docs DB, and contract sanity are not blocking
  - `usable_for.code_context` — indexer wiring, index DB, and contract sanity are not blocking
  - `usable_for.site_navigation` — sitemap wiring, run directory, and contract sanity are not blocking
  - `usable_for.debug_investigation` — `agentic_debug` is configured and healthy enough to use
  - Only rely on capabilities currently reported as usable.
- `agentic_debug` is integrated conservatively. Route to it only for explicit bounded debug families:
  - interpret or retrieve a stored debug session
  - plan or execute debug for a PHPUnit selector
  - plan or execute debug for an allowlisted CLI script
  - Do not route to `agentic_debug` for general bug reports or open-ended exploration.
- Once discovery is complete, make direct local Moodle edits and use the existing `./bin/*` harness for linting, tests, runtime checks, and Docker operations.
- Remember the boundaries:
  - orchestrator is not a code editor
  - orchestrator is not the Docker/test harness
  - orchestrator health is conservative and does not guarantee perfect retrieval quality

## MCP workflow

- Use Chrome MCP for Chromium-based UI checks, console/network inspection, screenshots, and performance traces.
- Use Firefox MCP for second-browser reproduction and Gecko-specific behaviour.
- Use Atlassian MCP for Jira and Confluence search, issue/page retrieval, and small coordination tasks.
- When a task depends on an MCP server, start with a lightweight connectivity check:
  - Chrome or Firefox: open a blank or `data:` page and confirm a snapshot loads.
  - Atlassian: fetch current user info and list accessible resources.
- Keep MCP use task-focused. Do not browse aimlessly when a targeted read or reproduction is enough.
- Do not hardcode tenant-specific Atlassian IDs, tokens, or machine-specific MCP details in committed files.

## Browser validation

- Use Chrome MCP first for admin-facing feature validation unless Firefox-specific follow-up is needed.
- Log in with the explicit harness credentials from `.claude.env`:
  - `MOODLE_ADMIN_USERNAME`
  - `MOODLE_ADMIN_PASSWORD`
- After implementing admin-facing Moodle features:
  - run `./bin/upgrade` if the feature depends on plugin discovery or upgrade-sensitive metadata
  - open `/login/index.php`
  - sign in as the configured admin user
  - navigate to the relevant page, for example `/admin/settings.php?section=<settingspageid>`
  - confirm the expected setting or UI control renders correctly
- Keep this lightweight. Use browser MCP to validate the real page, not to build a new browser framework inside this repo.

## Working with a large codebase

- Prefer targeted search (`rg`) and narrow edits.
- If unsure about conventions, find and mirror nearby Moodle patterns.
- Avoid broad refactors unless explicitly requested.
- For Moodle JavaScript work:
  - edit source files in `amd/src/`, not generated `amd/build/*.min.js` files
  - treat `amd/build/` as generated output that must be rebuilt when committed assets need refreshing
  - prefer the narrowest practical Grunt run, usually `./bin/grunt amd --files=<sourcefile>` or `./bin/grunt amd --root=<component>`
  - do not claim success on JS changes without saying what Grunt command ran, or why no Grunt run was needed
- Use `.claude.identity` for new file author metadata when present.
- If `.claude.identity` is missing and the task requires new Moodle source files, do not fall back to git identity or invent personal author details. Say the local identity config is missing and stop until the user creates it or explicitly approves a fallback.

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
- State the PHPCS scope used:
  - whole file
  - changed files
  - changed lines
- List exact test/lint commands run and outcomes.
- Suggest commit message(s) aligned to the change.
