# Create A Focused Moodle JavaScript Change

Use this prompt from `~/projects/moodle/claude` when you want Claude to make a bounded Moodle JavaScript change in the parent Moodle checkout.

```text
Read CLAUDE.md first and follow it strictly.

Task
Implement a focused Moodle JavaScript change using the current recommended AMD/Grunt workflow.

Workflow requirements
- Classify the task first.
- Treat this as orchestrator-first discovery unless the exact implementation pattern, source module, and validation path are already known.
- Use orchestrator to identify:
  - the correct Moodle JS pattern for this feature
  - the real source-of-truth files
  - whether the change is normal AMD work, generated/vendor asset work, or another JS build family
  - what the smallest practical Grunt validation path is
  - what browser/runtime validation is appropriate
- If the first orchestrator query is too thin, refine it before coding.
- After discovery, make direct local code changes in the Moodle checkout.
- Do not edit generated/built files directly unless the findings clearly justify that and you explain why.

Implementation expectations
- For normal Moodle AMD work, edit source files under `public/<component>/amd/src/` when this checkout uses the `public/` layout.
- Treat `public/<component>/amd/build/*.min.js` as generated output, not hand-edited source.
- Keep the change intentionally bounded and Moodle-native.
- Mirror nearby Moodle JS patterns before introducing new structure.
- If the task affects visible browser behaviour, plan for real browser validation rather than relying only on static build success.

Validation requirements
- Run the validation helpers from the `claude/` harness directory, not the parent Moodle repo root.
- Run `./bin/preflight` on the touched paths.
- For edits in large legacy files, prefer `./bin/preflight --changed-lines` when that is the more honest PHPCS scope.
- Run the smallest practical Grunt build, usually one of:
  - `./bin/grunt amd --files=public/<component>/amd/src/<file>.js`
  - `./bin/grunt amd --root=public/<component>`
- Only use broader tasks like `./bin/grunt js` when the change genuinely spans AMD, YUI, and React/ESM surfaces.
- If the JS change affects visible behaviour, perform browser/runtime validation and describe the exact page and evidence used.
- After a successful Grunt run, prefer clearing Moodle caches from the CLI before browser validation:
  - `./bin/mdc exec webserver php admin/cli/purge_caches.php`
- If the rebuilt AMD module still does not appear to load in the browser after cache purge, hard-refresh before treating the edit as broken.
- Run `./bin/upgrade` only if the task also changes plugin metadata or other upgrade-sensitive behaviour.
- State whether PHPCS ran on whole files or changed lines.
- Report the exact Grunt command run and which source files were treated as authoritative.

Output
- Summarise the orchestrator findings.
- Explain which JS files were treated as the source of truth.
- Explain whether any built/generated artifacts were refreshed and why.
- Explain the practical validation path, including the exact Grunt command and any browser/runtime validation.
- List exact commands run and outcomes.
- Suggest a concise Moodle-style commit message.
- After implementation and validation, perform the standard single-pass self peer review from CLAUDE.md, then fix any MUST FIX issues and re-run only affected validation.
```
