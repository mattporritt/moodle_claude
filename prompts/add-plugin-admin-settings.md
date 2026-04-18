# Add Admin Settings To A Moodle Plugin

Use this prompt from `~/projects/moodle/claude` when you want Claude to add or extend plugin admin settings in the Moodle checkout.

```text
Read CLAUDE.md first and follow it strictly.

Task
Add a minimal admin setting to a Moodle plugin using the correct Moodle pattern.

Workflow requirements
- Classify the task first.
- Treat this as orchestrator-first discovery unless the exact Moodle pattern and target file are already known.
- Use orchestrator to identify:
  - the correct settings.php location
  - the standard local plugin settings structure
  - the relevant admin_setting_config* API to use
- After discovery, make direct local code changes in the Moodle checkout.
- Use ./.claude.identity for any new Moodle files created during the task.
- If ./.claude.identity is missing and the task requires creating new Moodle source files, stop and say the local identity file must be created or a fallback explicitly approved first.

Implementation expectations
- Use or create plugin settings.php in the correct plugin directory.
- Follow Moodle admin settings conventions:
  - defined('MOODLE_INTERNAL') || die();
  - guard with $hassiteconfig where appropriate
  - add the settings page to the correct admin category
  - only add actual settings inside $ADMIN->fulltree
- Use language strings, not hardcoded labels.
- Keep the feature minimal.
- If you create any new files, use local author metadata from ./.claude.identity and format headers as:
  - `@copyright  {year} {Author} <{email}>`

Validation requirements
- Run ./bin/preflight on the touched paths.
- For edits in large existing legacy files, prefer changed-line-focused linting with ./bin/preflight --changed-lines rather than trying to fix every historical PHPCS issue.
- Run ./bin/upgrade if the settings page is new or plugin metadata changed.
- Log in with MOODLE_ADMIN_USERNAME and MOODLE_ADMIN_PASSWORD.
- Open /admin/settings.php?section=<settingspageid> and confirm the setting renders correctly.
- State whether PHPCS ran on whole files or changed lines.

Output
- Summarise the orchestrator findings.
- Explain how the final implementation matches Moodle conventions.
- List exact commands run and outcomes.
- Suggest a concise Moodle-style commit message.
```
