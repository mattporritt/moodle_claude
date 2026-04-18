# Create A Minimal Moodle Scheduled Task

Use this prompt from `~/projects/moodle/claude` when you want Claude to add a small scheduled task in the parent Moodle checkout.

```text
Read CLAUDE.md first and follow it strictly.

Task
Implement a minimal Moodle scheduled task using the current recommended pattern.

Workflow requirements
- Classify the task first.
- Treat this as orchestrator-first discovery unless the exact implementation pattern and target files are already known.
- Use orchestrator to identify:
  - the modern scheduled-task pattern for this Moodle version
  - the task class structure under classes/task/
  - how db/tasks.php should register the task
  - how plugin versioning interacts with task discovery
  - what practical validation and PHPUnit coverage look like for this task shape
- If the first orchestrator query is too thin, refine it before coding.
- After discovery, make direct local code changes in the Moodle checkout.
- Use ./.claude.identity for any new Moodle files created during the task.
- If ./.claude.identity is missing and the task requires creating new Moodle source files, stop and say the local identity file must be created or a fallback explicitly approved first.

Implementation expectations
- Prefer an isolated local plugin unless there is a strong reason to extend an existing component.
- Use the normal scheduled-task class pattern under public/<component>/classes/task/ when this checkout uses the public/ layout.
- Define the task in public/<component>/db/tasks.php.
- Keep the task safe for repeated execution in a dev environment.
- Keep the task intentionally small but real, with a bounded observable effect.
- For new generated files, use local author metadata from ./.claude.identity and format headers as:
  - `@copyright  {year} {Author} <{email}>`

Validation requirements
- Run the validation helpers from the `claude/` harness directory (for example `~/projects/moodle/claude`), not the parent Moodle repo root.
- Run ./bin/preflight on the touched plugin or file paths.
- Full-file PHPCS is appropriate for newly created scheduled-task plugin files.
- Run ./bin/upgrade if the plugin or task metadata changed.
- Add targeted PHPUnit where practical.
- For ./bin/phpunit, use a Moodle-relative test path visible inside the container.
- Validate runtime execution through the scheduled task CLI, for example:
  - ./bin/web sh -lc "cd /var/www/html && php admin/cli/scheduled_task.php --execute='\\component\\task\\classname' --force"
- Reuse the single-quoted fully qualified classname form exactly; the leading backslash matters and the whole task classname should stay inside one quoted argument.
- Log in as admin and validate the task is visible on /admin/tool/task/scheduledtasks.php.
- Confirm one safe observable effect of the task after execution.
- The expected validation order is:
  - ./bin/preflight
  - ./bin/upgrade
  - targeted PHPUnit where practical
  - explicit single-task CLI execution
  - admin login and validation on /admin/tool/task/scheduledtasks.php
  - confirmation of the observable effect
- State whether PHPCS ran on whole files or changed lines.

Output
- Summarise the orchestrator findings.
- Explain how the task is structured and scheduled.
- Explain the practical validation path and any PHPUnit coverage added.
- List exact commands run and outcomes.
- Suggest a concise Moodle-style commit message.
```
