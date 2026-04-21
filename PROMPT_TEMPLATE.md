# Claude Session Prompt (Moodle LMS)

Use this at the start of a Claude Code task in `~/projects/moodle/claude`.

```text
You are working on Moodle LMS code located at $MOODLE_DIR from .claude.env.
The harness repo lives inside the Moodle checkout at ~/projects/moodle/claude and commands are run from that repo root, not the parent Moodle checkout.
The agentic orchestrator checkout lives separately at $AGENTIC_ORCHESTRATOR_DIR when available, typically ~/projects/agentic_orchestrator.
Use ./bin/* scripts from the repository root.
Run PHPCS/PHPCBF on the host.
Run Grunt on the host through ./bin/grunt when a Moodle JS/CSS build is required.
Run PHPUnit, Behat, install, and runtime commands via the Docker-backed wrappers.
Use ./bin/upgrade when plugin discovery or upgrade-sensitive metadata changes.
Use ./.claude.identity for local author metadata when generating new Moodle files.
Treat the current orchestrator as a thin CLI over agentic_devdocs, agentic_indexer, agentic_sitemap, and agentic_debug.
Use connected MCP servers when they materially help:
- Chrome MCP for Chromium-based browser debugging and DevTools inspection
- Firefox MCP for cross-browser checks
- Atlassian MCP for Jira and Confluence context

Rules:
- First classify the task:
  - trivial local edit in already-known files
  - non-trivial Moodle task requiring orchestrator-first discovery
- Follow Moodle coding style and existing APIs/patterns.
- Use the `moodle` PHPCS standard by default; use `moodle-extra` only when stricter checks are explicitly wanted.
- For normal Moodle AMD work, treat `amd/src/` as the source of truth and `amd/build/*.min.js` as generated output.
- For new files, full-file PHPCS is appropriate.
- For edits in large legacy files, prefer changed-line-focused linting rather than cleaning all historical issues in the file.
- Keep changes minimal and local to the requested issue.
- Before editing, identify nearby Moodle examples and follow them.
- For JavaScript tasks:
  - edit source modules in `amd/src/`, not generated `amd/build` files
  - do not hand-edit built assets unless the task explicitly concerns generated/vendor output and that choice is justified
  - prefer targeted Grunt commands such as `./bin/grunt amd --files=<sourcefile>` or `./bin/grunt amd --root=<component>`
  - only run broader tasks like `./bin/grunt js` when the change really spans AMD, YUI, and React/ESM surfaces
- For new generated Moodle files, use AUTHOR_NAME, AUTHOR_EMAIL, and COPYRIGHT_YEAR from ./.claude.identity and format headers as:
  - `@copyright  {year} {Author} <{email}>`
- If ./.claude.identity is missing and the task requires creating new Moodle source files, stop that path and say the local identity file must be created or a fallback explicitly approved first.
- For non-trivial Moodle tasks, use orchestrator first for discovery, pattern-finding, and broader investigation before writing code, normally using its query-style workflow.
- For trivial local edits, do not use orchestrator unless the task unexpectedly expands.
- Report whether orchestrator availability and health have been manually verified in this setup.
- Treat manual verification as concrete, not vague:
  - a real config such as config.local.toml exists in the orchestrator repo, not in ~/projects/moodle/claude
  - `PYTHONPATH=src python3 -m agentic_orchestrator.cli verify --config ./config.local.toml` returns READY or DEGRADED when run in ~/projects/agentic_orchestrator
  - at least one real orchestrator query or pilot-run has succeeded from that orchestrator repo
- Surface orchestrator warnings explicitly:
  - stale sitemap/resource warnings usually still allow docs/code pattern discovery
  - those warnings reduce trust in site-context freshness
  - warnings affecting a specific source backend reduce trust in that source and may require pausing if the task depends on it
- If the task depends on orchestrator-style discovery and orchestrator has not been manually verified, stop and say manual verification is required first.
- Do not treat orchestrator as a code editor, workflow engine, or replacement for direct local Moodle commands.
- If a task depends on Chrome, Firefox, or Atlassian MCP, start with a lightweight connectivity smoke check before relying on it.
- Run targeted checks for changed code:
  - ./bin/phpcs <touched paths> for explicit whole-file linting
  - ./bin/preflight for the normal targeted PHPCS pass
  - ./bin/preflight --changed-lines [--base-ref <ref>] [paths...] for legacy-file edits where changed-line-focused PHPCS is more practical
  - ./bin/grunt amd --files=<sourcefile> or ./bin/grunt amd --root=<component> for targeted JS rebuilds when AMD changed
  - ./bin/upgrade when new plugin-discovered features or upgrade-sensitive changes were added
  - ./bin/phpunit <targeted tests>
  - ./bin/behat <targeted tags or feature paths> for behaviour/UI changes
  - ./bin/feature-smoke when validating the full install/init/test workflow
- For non-trivial tasks, include a required Self Peer Review section after initial validation:
  - use the compact `Y / N / -` checklist format
  - classify each issue as `MUST FIX` or `SHOULD FIX`
  - perform exactly one review pass
  - treat it as a correction step, not a redesign step
  - apply fixes
  - re-run only the affected validation steps
  - include a final post-fix checklist and short summary
- For scheduled-task work, treat the expected validation path as:
  - ./bin/preflight
  - ./bin/upgrade
  - targeted PHPUnit where practical
  - explicit single-task execution through admin/cli/scheduled_task.php --execute='\component\task\classname'
  - admin login and validation on /admin/tool/task/scheduledtasks.php
  - confirmation of the safe observable effect
- For admin-facing features, validate in-browser after coding:
  - log in via /login/index.php
  - use MOODLE_ADMIN_USERNAME and MOODLE_ADMIN_PASSWORD from .claude.env
  - navigate to the relevant admin page, for example /admin/settings.php?section=<settingspageid>
  - confirm the feature renders correctly
- For targeted Behat feature execution, prefer Moodle-checkout-relative paths such as:
  - ./bin/behat public/local/example/tests/behat/example.feature
  - or, in public-layout checkouts, ./bin/behat local/example/tests/behat/example.feature
- Include/adjust tests for every behavioural change.
- For JS tasks, report the exact Grunt/build command run, the source files treated as authoritative, and any browser/runtime validation used after the rebuild.
- State whether PHPCS ran on whole files, changed files, or changed lines.
- Summarize changed files, commands run, and outcomes.
- Propose commit message(s) and branch name suggestion.
- For trivial local edits, a self peer-review step is optional unless the task explicitly calls for it.

Git expectations:
- One logical change per commit.
- Keep commit history reviewable.
- Suggest MDL issue style commit summary if issue key is known.
```
