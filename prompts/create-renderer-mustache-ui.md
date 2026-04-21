# Create A Moodle Renderer + Mustache UI Change

Use this prompt from `~/projects/moodle/claude` when you want Claude to implement a small Moodle UI feature rendered through PHP into a Mustache template.

```text
Read CLAUDE.md first and follow it strictly.

Task
Implement a bounded Moodle UI feature using a renderer and a Mustache template, with PHP passing real dynamic values into the template.

Workflow requirements
- Classify the task first.
- Treat this as orchestrator-first discovery unless the exact renderer, template, and validation path are already known.
- Use orchestrator to identify:
  - the correct renderer + Mustache pattern for this Moodle version and subsystem
  - whether a renderable + templatable + export_for_template structure is appropriate
  - the right file locations for renderer, output classes, templates, and any page entrypoint
  - one or two concrete examples to mirror
  - a practical Behat and browser validation path for the chosen UI surface
- If the first orchestrator query is too thin, refine it before coding.
- Make direct code changes in the Moodle checkout, not in the claude repo.
- Use ./.claude.identity for any new Moodle source files created during the task.
- If ./.claude.identity is missing and the task requires creating new Moodle source files, stop and say the local identity file must be created or a fallback explicitly approved first.

Implementation expectations
- Keep the feature intentionally small, visible, and bounded.
- Prefer a local plugin page when that is the cleanest isolated trial surface.
- Use a renderer and a Mustache template for the main rendered UI, not echoed HTML.
- Prefer a renderable + templatable + export_for_template pattern when the UI has more than trivial dynamic data.
- Pass real dynamic values from PHP into the template.
- Add the minimum required plugin files for a valid implementation, typically including:
  - version.php
  - index.php or the relevant page/controller entrypoint
  - classes/output/renderer.php
  - classes/output/<renderable>.php when using export_for_template
  - templates/<template>.mustache
  - lang/en/<component>.php
  - classes/privacy/provider.php for new plugins
  - tests/behat/<feature>.feature
- For new generated files, use local author metadata from ./.claude.identity and format headers as:
  - `@copyright  {year} {Author} <{email}>`

Validation requirements
- Run ./bin/preflight on the touched paths.
- For new plugin files, use full-file PHPCS and state that whole-file scope was used.
- Run ./bin/upgrade if the plugin or other upgrade-sensitive metadata changed.
- Run ./bin/behat-init if the Behat environment is not ready.
- Run targeted Behat for the new scenario.
- Prefer Moodle-checkout-relative feature paths such as:
  - `./bin/behat public/local/<plugin>/tests/behat/<feature>.feature`
  - or, in public-layout checkouts, `./bin/behat local/<plugin>/tests/behat/<feature>.feature`
- If the wrapper still needs a fallback, use tag-based invocation: `./bin/behat --tags=@<component>`
- Validate the rendered page in the browser:
  - log in with MOODLE_ADMIN_USERNAME and MOODLE_ADMIN_PASSWORD when admin access is needed
  - open the target page URL
  - confirm the rendered UI is visible
  - confirm the expected PHP-provided values appear in the template output
- If language strings or templates look stale after upgrade, clear Moodle caches before judging the UI broken.
- After implementation and validation, perform the standard single-pass self peer review from CLAUDE.md, then fix any MUST FIX issues and re-run only affected validation.

Output
- Summarise the orchestrator findings.
- Explain how PHP values are passed into the template.
- Explain the Behat coverage added.
- List exact commands run and outcomes.
- Report the PHPCS scope used.
- Suggest a concise Moodle-style commit message.
```
