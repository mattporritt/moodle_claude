# Create A Minimal Moodle Web Service

Use this prompt from `~/projects/moodle/claude` when you want Claude to add a small Moodle web service in the parent Moodle checkout.

```text
Read CLAUDE.md first and follow it strictly.

Task
Implement a minimal Moodle web service using the current recommended pattern.

Workflow requirements
- Classify the task first.
- Treat this as orchestrator-first discovery unless the exact implementation pattern and target files are already known.
- Use orchestrator to identify:
  - the modern external API pattern for this Moodle version
  - whether the implementation should use classes/external/ rather than externallib.php
  - how db/services.php should expose the function
  - how context validation and capability checks should be applied
  - how PHPUnit tests for the external function are typically structured
- If the first orchestrator query is too thin, refine it before coding.
- After discovery, make direct local code changes in the Moodle checkout.
- Use ./.claude.identity for any new Moodle files created during the task.
- If ./.claude.identity is missing and the task requires creating new Moodle source files, stop and say the local identity file must be created or a fallback explicitly approved first.

Implementation expectations
- Prefer an isolated local plugin unless there is a strong reason to extend an existing component.
- Prefer one web service class per call under public/<component>/classes/external/ when this checkout uses the public/ layout.
- Do not use the legacy externallib.php pattern unless orchestrator-backed findings clearly justify it.
- Keep the web service intentionally small but real.
- Include explicit context validation and capability checks inside the external function.
- Add the required registration and metadata files, typically including:
  - version.php
  - db/access.php when introducing a new capability
  - db/services.php
  - classes/external/<functionname>.php
  - lang/en/<component>.php
  - tests/external/<functionname>_test.php
- For new generated files, use local author metadata from ./.claude.identity and format headers as:
  - `@copyright  {year} {Author} <{email}>`

Validation requirements
- Run ./bin/preflight on the touched plugin or file paths.
- For edits in large existing legacy files, prefer changed-line-focused linting with ./bin/preflight --changed-lines.
- Run ./bin/upgrade if the plugin, capability definitions, or service metadata changed.
- Run targeted PHPUnit for the new external test.
- For ./bin/phpunit, pass a Moodle-relative test path visible inside the container, such as public/local/<plugin>/tests/external/<testname>_test.php, not a host absolute path.
- If lightweight runtime validation is practical, describe it and use it; otherwise explain why PHPUnit is the main validation path.
- State whether PHPCS ran on whole files or changed lines.

Output
- Summarise the orchestrator findings.
- Explain how context validation and capability checks were implemented.
- Explain the PHPUnit coverage added.
- List exact commands run and outcomes.
- Suggest a concise Moodle-style commit message.
- After implementation and validation, perform the standard single-pass self peer review from CLAUDE.md, then fix any MUST FIX issues and re-run only affected validation.
```
