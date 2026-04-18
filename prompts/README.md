# Prompt Library

Use these reusable prompts from `~/projects/moodle/claude` as starting points for real Moodle Claude tasks.
Run the `./bin/*` commands from that `claude/` repo root, not from the parent Moodle checkout.

## Prompts

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
- `create-javascript-change.md`
  - for bounded Moodle JavaScript work using the normal AMD source/build workflow
  - orchestrator-first unless the exact JS pattern, source file, and validation path are already known
  - typical validation: `./bin/preflight`, targeted `./bin/grunt amd --files=...` or `./bin/grunt amd --root=...`, and browser/runtime validation when behaviour is visible in the UI

## Shared expectations

- Read `CLAUDE.md` first and follow it strictly.
- For new Moodle source files, `.claude.identity` is required unless the user explicitly approves a fallback.
- For Moodle AMD work, `amd/src/` is the source of truth and `amd/build/` is generated output.
- For new files, use whole-file PHPCS.
- For edits in large legacy files, prefer changed-line-focused PHPCS with `./bin/preflight --changed-lines`.
- Report the PHPCS scope used and the exact validation commands run.
