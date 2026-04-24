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
- Jira field IDs and Jira workflow metadata for this repo live in `config/jira_field_map.yaml`.
- Moodle branch mapping and Jira-driven branch naming guidance live in `docs/moodle-branching.md`.
- Jira write-back auth and fallback guidance live in `docs/jira-writeback.md`.

## Non-negotiables

- Follow Moodle coding style and conventions:
  - https://moodledev.io/general/development/policies/codingstyle
- Default PHPCS standard is `moodle`; use `moodle-extra` only when the task explicitly calls for the stricter ruleset.
- Reuse existing Moodle APIs/patterns before introducing new abstractions.
- Keep changes minimal, localized, and issue-focused.
- For Moodle external web service `execute()` methods, always follow this access control order:
  1. `self::validate_parameters(self::execute_parameters(), [...])` — parameter validation
  2. `$context = \context_system::instance();` (or appropriate context) + `self::validate_context($context)` — mandatory for every execute(); validates session and context
  3. `require_capability('plugin:capability', $context)` — only for protected functions; omit for public endpoints with `loginrequired => false`
  Skipping `validate_context()` is never correct, even for public read functions.
- Every Moodle plugin must include a privacy provider at `classes/privacy/provider.php`. If the plugin stores no personal data, implement `\core_privacy\local\metadata\null_provider` with a `get_reason()` method returning a lang string key (e.g. `'privacy:metadata'`), and add the corresponding string to the lang file. Omitting this causes the core privacy compliance test (`core_privacy\privacy\provider_test`) to fail.
- PHPUnit tests are required for all web service functions and scheduled tasks — a CLI smoke-run proves the code path executes but does not assert correctness. Test files live in `tests/external/` and `tests/task/` respectively, extend `\advanced_testcase`, and must cover both the default (no config) and configured cases.
- For Moodle AMD JavaScript work, `amd/src/` is the source of truth and `amd/build/` is generated output.
- For newly created files, full-file PHPCS is appropriate.
- For edits in large existing legacy files, focus on keeping changed lines clean rather than fixing every historical PHPCS issue in the file.
- When generating new Moodle files, use local author metadata from `.claude.identity` and format it as:
  - `@copyright  {year} {Author} <{email}>`
- `.claude.identity` is sourced as a shell script — it must use shell variable syntax:
  ```
  AUTHOR_NAME="Your Name"
  AUTHOR_EMAIL="you@example.com"
  ```
  Copy `.claude.identity.example` as the starting point. Do not use `name=` or `email=` key-value syntax.
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
   - `./bin/grunt css --root=<theme/component>` for SCSS changes that require committed precompiled CSS output, and include the generated CSS files in the change
   - `./bin/phpunit <targeted tests>`
   - `./bin/behat <targeted tags or feature paths>` for behaviour/UI changes
   - `./bin/upgrade` when plugin discovery or upgrade-sensitive metadata changed
   - `docker exec moodlemaster-webserver-1 php /var/www/html/admin/cli/scheduled_task.php --execute='\plugin\task\classname'` to smoke-test a scheduled task — confirms the code path runs without fatal errors and `mtrace()` output is correct; this is a runtime check only, not a substitute for PHPUnit tests that assert task logic
   - `./bin/smoke` when validating a fresh harness setup
   - `./bin/feature-smoke` when validating the full install/init/test workflow
   - `docker exec moodlemaster-webserver-1 php /var/www/html/admin/cli/purge_caches.php` after CSS, SCSS, template, or lang-string changes before browser validation, to avoid stale LMS caches affecting manual or MCP-based checks
   - `docker exec moodlemaster-webserver-1 php /var/www/html/admin/cli/purge_caches.php` after adding lang strings or template changes to an already-installed plugin without a version bump — `./bin/upgrade` alone does not clear the string cache in this case
7. For non-trivial tasks, perform a self peer-review pass (see Self peer review section):
   - exactly one review pass only
   - use the compact `Y / N / -` checklist format
   - classify findings as `MUST FIX` or `SHOULD FIX`
   - treat this as a correction step, not a redesign step
   - do not recurse or run a second peer review after fixes
8. Apply all `MUST FIX` issues and any practical `SHOULD FIX` issues without expanding scope.
9. Re-run only the validation steps affected by those fixes.
10. Prepare final output and commit suggestions:
   - one logical change per commit
   - tests included in the same commit that changes behaviour
   - choose the correct Moodle base branch from `docs/moodle-branching.md`
   - never commit directly to `main` or `MOODLE_*_STABLE`; use issue-specific development branches instead
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
- Use `docs/jira-writeback.md` as the source of truth for Jira read-vs-write behavior and Jira write-back fallback order.
- Both Chrome and Firefox MCP run headless — the browser process is hidden and cannot be accidentally closed by the user. Output files (snapshots, logs) go to `~/.claude/playwright-output/`.
- When a task depends on an MCP server, start with a lightweight connectivity check:
  - Chrome or Firefox: open a blank or `data:` page and confirm a snapshot loads.
  - Atlassian: fetch current user info and list accessible resources.
- If a Chrome or Firefox MCP call fails with "Target page, context or browser has been closed" or similar, the MCP server process is still alive but has lost its browser context. This requires a Claude Code session restart to recover — it cannot be fixed mid-session by retrying. Note the gap in the task summary and continue with other validation methods (CLI, `curl`).
- For non-trivial tasks where rendered UI is part of acceptance, do not defer browser MCP checks until after implementation.
- If one browser MCP is unavailable, try the other relevant browser MCP promptly rather than waiting for a later validation step to fail.
- If both browser MCP servers are unavailable and the task depends on real browser inspection, call that out early as a validation blocker or explicit gap.
- Keep MCP use task-focused. Do not browse aimlessly when a targeted read or reproduction is enough.
- Do not hardcode tenant-specific Atlassian IDs, tokens, or machine-specific MCP details in committed files.
- For Jira interaction in this repo, treat `config/jira_field_map.yaml` as the source of truth for field IDs and issue-type-driven workflow metadata.
- Treat Jira reads and Jira writes as separate checks. Public readability or successful MCP reads do not prove authenticated write access.
- Prefer Atlassian Rovo MCP first for Jira reads and writes.
- If Jira write-back via MCP fails because authentication or permissions are insufficient, use Jira REST API fallback only when `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, and `JIRA_API_TOKEN` are configured locally in `.claude.env`.
- If both MCP and API fallback are unavailable or fail, browser-based Jira interaction may be used as the final fallback when the browser session is authenticated for editing.
- When using Jira REST for writes:
  - use `./bin/jira-update` for common issue-field and comment updates before hand-rolling `curl`
  - default to Jira REST v2 issue writes for the common string and textarea fields documented in `config/jira_field_map.yaml`
  - check `docs/jira-writeback.md` and the field map for the expected payload format before writing unfamiliar fields
  - if the field format is still uncertain, inspect `editmeta` once before the first write rather than guessing repeatedly
  - verify successful writes with a follow-up read of the updated fields
- When Jira updates are part of the task, report the read path used, whether MCP write was attempted, whether MCP write failed due to authentication or permissions, whether API fallback was attempted, whether browser fallback was used, and the exact update types applied.
- In ticket authoring/refinement flows, issue type may be suggested for confirmation when it is not yet settled.
- In coding workflows against an existing Jira issue, trust the Jira issue type as the source of truth.
- In Jira-driven coding work, use `docs/moodle-branching.md` to map target versions to Moodle base branches and form developer-owned issue branches such as `MOODLE_502_STABLE_MDL-12345`.

## Browser validation

- Use Chrome MCP first for admin-facing feature validation unless Firefox-specific follow-up is needed.
- Log in with the explicit harness credentials from `.claude.env`:
  - `MOODLE_ADMIN_USERNAME`
  - `MOODLE_ADMIN_PASSWORD`
- For Jira-driven work, finish by manually walking through the current Jira testing instructions after automated checks pass, and treat that pass as part of completion rather than optional follow-up.
- For browser-facing UI changes, do not stop at "page loads correctly" — explicitly exercise the changed control states that matter for the ticket, such as default, focused, hover, error, and JS-enhanced states where relevant.
- For decorative UI additions, perform an explicit accessibility sanity check to confirm they do not alter the accessible name or announcement path for the underlying control.
- For CSS changes involving Bootstrap-managed controls such as `input-group`, toggles, buttons, or wrappers around focused fields, explicitly check focus-state stacking and wrapper interactions rather than assuming the default state is sufficient.
- If browser behaviour looks wrong after a frontend change, consider stale assets or focus/stacking CSS interactions early, especially in Boost, before assuming the template or PHP logic is incorrect.
- For Jira-driven UI changes, take a validation screenshot after the final manual/browser verification when the screenshot materially demonstrates the implemented result, and attach it to the Jira ticket.
- After implementing admin-facing Moodle features:
  - run `./bin/upgrade` if the feature depends on plugin discovery or upgrade-sensitive metadata
  - run `docker exec moodlemaster-webserver-1 php /var/www/html/admin/cli/purge_caches.php` if CSS, SCSS, templates, or lang strings changed
  - open `/login/index.php`
  - sign in as the configured admin user
  - navigate to the relevant page, for example `/admin/settings.php?section=<settingspageid>`
  - confirm the expected setting or UI control renders correctly
- Keep this lightweight. Use browser MCP to validate the real page, not to build a new browser framework inside this repo.

## Behat path guidance

- `./bin/behat` accepts either:
  - option-style arguments such as `--tags=@mytag`
  - Moodle-checkout-relative feature paths such as `public/local/example/tests/behat/example.feature`
  - short feature paths relative to `public/`, such as `local/example/tests/behat/example.feature`, when this checkout uses the `public/` layout
  - absolute host paths under `MOODLE_DIR`, which the wrapper normalizes to container-visible paths
- For targeted feature execution, prefer Moodle-checkout-relative feature paths from the repo root.
- The wrapper now normalizes feature paths before handing them to Moodle's Behat runner so feature execution does not depend on the container working directory.
- If Behat or the acceptance site requires reinitialisation during the task, report that clearly as an environment/setup step and do not blur it into product-level validation.

## Working with a large codebase

- Prefer targeted search (`rg`) and narrow edits.
- If unsure about conventions, find and mirror nearby Moodle patterns.
- Avoid broad refactors unless explicitly requested.
- For Moodle JavaScript work:
  - edit source files in `amd/src/`, not generated `amd/build/*.min.js` files
  - treat `amd/build/` as generated output that must be rebuilt when committed assets need refreshing
  - prefer the narrowest practical Grunt run, usually `./bin/grunt amd --files=<sourcefile>` or `./bin/grunt amd --root=<component>`
  - do not claim success on JS changes without saying what Grunt command ran, or why no Grunt run was needed
- For theme SCSS changes that feed committed precompiled CSS, run the narrowest applicable CSS Grunt build and commit the generated stylesheet outputs it updates.
- When editing Mustache templates, prefer the clearest readable markup for the local template rather than blindly copying inherited formatting patterns from related templates.
- Do not cargo-cult Mustache whitespace-control comment fragments such as `{{! ... !}}` when plain multiline HTML attributes are clearer and do not change rendering.
- Use `.claude.identity` for new file author metadata when present. The file is sourced as shell, so variables must use shell syntax (`AUTHOR_NAME="..."`, `AUTHOR_EMAIL="..."`). Use `.claude.identity.example` as the template.
- If `.claude.identity` is missing and the task requires new Moodle source files, do not fall back to git identity or invent personal author details. Say the local identity config is missing and stop until the user creates it or explicitly approves a fallback.

## Self peer review

After implementation and initial validation on non-trivial tasks, perform a single-pass self peer review before proposing a commit:
- Use a compact `Y / N / -` checklist format
- Classify each issue as `MUST FIX` or `SHOULD FIX`
- Perform exactly one review pass — treat it as a correction step, not a redesign
- Apply MUST FIX items, then re-run only the affected validation steps
- Include a short post-fix summary
- For trivial local edits, this step is optional unless explicitly requested

## Git expectations

- One logical change per commit.
- Use `docs/moodle-branching.md` as the canonical source for Moodle base branches and issue-branch naming.
- Never commit directly to Moodle core `main` or `MOODLE_*_STABLE` branches.
- Before starting Jira-driven implementation work, inspect the current Moodle checkout branch and correct it if it is unrelated to the issue.
- Treat an unexpected existing developer branch in the Moodle checkout as a warning sign that must be resolved before new implementation starts.
- Create per-issue development branches from the correct base branch, for example `MOODLE_502_STABLE_MDL-12345`.
- Push development branches to the developer's own fork or repository, not the main Moodle LMS repository.
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
