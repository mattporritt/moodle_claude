# Prompt Library

Use these reusable prompts from `~/projects/moodle/claude` as starting points for real Moodle Claude tasks.
Run the `./bin/*` commands from that `claude/` repo root, not from the parent Moodle checkout.

## Core Development Prompts

- `create-local-plugin.md`
  - for scaffolding a minimal local plugin
  - orchestrator-first when the plugin pattern or target structure is not already known
  - typical validation: `./bin/preflight`, `./bin/upgrade`, browser validation when the plugin has an admin-visible footprint
- `add-plugin-admin-settings.md`
  - for adding or extending plugin admin settings
  - orchestrator-first unless the exact settings pattern and file are already known
  - typical validation: `./bin/preflight`, `./bin/upgrade`, admin login, `/admin/settings.php?section=<settingspageid>`, browser confirmation
- `create-web-service.md`
  - for implementing a minimal Moodle external API call using the modern `classes/external/` pattern
  - orchestrator-first unless the exact modern pattern and target files are already known
  - typical validation: `./bin/preflight`, `./bin/upgrade`, targeted PHPUnit, optional lightweight runtime validation
- `create-scheduled-task.md`
  - for implementing a minimal Moodle scheduled task using `classes/task/` and `db/tasks.php`
  - orchestrator-first unless the exact scheduled-task pattern and target files are already known
  - typical validation: `./bin/preflight`, `./bin/upgrade`, targeted PHPUnit where practical, explicit single-task CLI execution using `--execute='\component\task\classname' --force`, admin login on `/admin/tool/task/scheduledtasks.php`, and confirmation of a safe observable effect
- `create-renderer-mustache-ui.md`
  - for implementing a small user-visible Moodle UI feature using a renderer, a Mustache template, and PHP-provided dynamic values
  - orchestrator-first unless the exact renderer/template pattern, target files, and validation path are already known
  - typical validation: `./bin/preflight`, `./bin/upgrade`, `./bin/behat-init` when needed, targeted Behat, and browser validation of the rendered output
- `create-javascript-change.md`
  - for bounded Moodle JavaScript work using the normal AMD source/build workflow
  - orchestrator-first unless the exact JS pattern, source file, and validation path are already known
  - typical validation: `./bin/preflight`, targeted `./bin/grunt amd --files=...` or `./bin/grunt amd --root=...`, and browser/runtime validation when behaviour is visible in the UI

## Jira Ticket Authoring / Refinement

- `user-ticket-template.md`
  - the user-facing starting template for drafting a Jira ticket
  - use this first when the problem is still being defined and you want a human-friendly intake structure
- `agent-create-ticket.md`
  - the agent-side prompt for turning a rough draft into a complete Jira ticket
  - use after the user-facing template when the goal is clarification, structured ticket writing, and Jira-ready content that should prefer Atlassian Rovo MCP first for write-back
  - can suggest `Bug`, `Improvement`, or `New Feature` before ticket finalisation, but should ask for confirmation before writing that type back

## Development From Existing Jira Issue

- `jira-driven-moodle-development-workflow-v1.md`
  - for starting from an existing Jira issue and driving the work through issue reading, clarification, testing instructions, branching, implementation, and final Jira-ready updates
  - use when the Jira issue already exists and is the source of truth for the development task
  - invoke it by passing the Jira issue key explicitly, for example `Jira issue key: MDL-88194`
  - use `docs/moodle-branching.md` with it to map target versions to Moodle base branches and form developer-owned issue branches
  - fits the broader workflow by front-loading issue understanding before coding, then preparing Jira-ready updates after the normal implementation and validation steps
  - use `docs/jira-writeback.md` with it when Jira work needs to distinguish public reads from authenticated writes or choose between MCP, API, and browser fallback

## Shared expectations

- Read `CLAUDE.md` first and follow it strictly.
- For new Moodle source files, `.claude.identity` is required unless the user explicitly approves a fallback.
- For Moodle AMD work, `amd/src/` is the source of truth and `amd/build/` is generated output.
- For new files, use whole-file PHPCS.
- For edits in large legacy files, prefer changed-line-focused PHPCS with `./bin/preflight --changed-lines`.
- Report the PHPCS scope used and the exact validation commands run.
- For Jira-driven work, use `config/jira_field_map.yaml` as the source of truth for field IDs, issue-type rules, and future Jira write-back automation.
- For Jira-driven work, use `docs/moodle-branching.md` as the source of truth for Moodle version-to-branch mapping and issue-branch naming.
- For Jira-driven work, use `docs/jira-writeback.md` as the source of truth for read-vs-write access expectations and Jira write-back fallback order.
