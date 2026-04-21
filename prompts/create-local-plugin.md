# Create A Minimal Moodle Local Plugin

Use this prompt from `~/projects/moodle/claude` when you want Claude to scaffold a small local plugin in the Moodle checkout.

```text
Read CLAUDE.md first and follow it strictly.

Task
Create a minimal Moodle local plugin in the current checkout.

Workflow requirements
- Classify the task first.
- If the task is non-trivial, use orchestrator first for Moodle pattern discovery before coding.
- If the first orchestrator query is too thin for implementation, refine it until the minimal plugin pattern is concrete and usable.
- Make direct code changes in the Moodle checkout, not in the claude repo.
- Keep the implementation minimal and Moodle-native.
- Use ./.claude.identity for new Moodle file headers.
- If ./.claude.identity is missing and the task requires creating new Moodle source files, stop and say the local identity file must be created or a fallback explicitly approved first.

Implementation expectations
- Create the smallest valid local plugin under public/local/<pluginname> when this checkout uses the public/ layout.
- Include the minimum required files such as:
  - version.php
  - lang/en/local_<pluginname>.php
- For new generated files, use local author metadata from ./.claude.identity and format headers as:
  - `@copyright  {year} {Author} <{email}>`
- For real end-to-end trials, include one small admin-visible or browser-visible footprint so browser validation is meaningful.
- Add any extra files only if the requested feature truly needs them.

Validation requirements
- Run ./bin/preflight on the touched paths.
- Full-file PHPCS is appropriate for the newly created plugin files.
- State that PHPCS ran on whole files for this task.
- Run ./bin/upgrade if plugin discovery or upgrade-sensitive metadata changed.
- If the feature is admin-facing, log in with MOODLE_ADMIN_USERNAME and MOODLE_ADMIN_PASSWORD and validate the page in-browser.

Output
- Summarise the Moodle pattern used.
- List files created or modified.
- List exact commands run and outcomes.
- Suggest a concise Moodle-style commit message.
- After implementation and validation, perform the standard single-pass self peer review from CLAUDE.md, then fix any MUST FIX issues and re-run only affected validation.
```
