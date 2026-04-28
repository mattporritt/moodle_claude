# moodle_claude

A Claude Code harness for Moodle LMS development.

This repository gives Claude Code a stable command surface for Moodle LMS development when the Moodle checkout and the moodle-docker checkout live in separate directories.

## Table of Contents

- [What this solves](#what-this-solves)
- [Recommended layout](#recommended-layout)
- [Phase-one orchestrator integration](#phase-one-orchestrator-integration)
- [First-day setup](#first-day-setup)
- [Optional MCP servers](#optional-mcp-servers)
- [Jira Write-Back Access](#jira-write-back-access)
- [MCP smoke checks](#mcp-smoke-checks)
- [Daily workflow with Claude Code](#daily-workflow-with-claude-code)
- [Workflow Stages](#workflow-stages)
- [Reusable Prompt Templates](#reusable-prompt-templates)
- [Jira Workflows](#jira-workflows)
- [JavaScript and Grunt workflow](#javascript-and-grunt-workflow)
- [Core commands](#core-commands)
- [What `smoke` does](#what-smoke-does)
- [What `feature-smoke` does](#what-feature-smoke-does)
- [Admin Credentials](#admin-credentials)
- [Post-Implementation Workflow](#post-implementation-workflow)
- [PHPCS Defaults](#phpcs-defaults)
- [Feature Smoke Defaults](#feature-smoke-defaults)
- [Branch and commit discipline](#branch-and-commit-discipline)
- [Notes](#notes)

## What this solves

- Keeps Claude Code commands consistent across projects.
- Targets a large external Moodle checkout instead of this repo.
- Runs PHPUnit, Behat, install, and runtime commands through moodle-docker while keeping PHPCS and PHPCBF on the host.
- Keeps host-side Grunt usage explicit for Moodle JavaScript and CSS work.
- Keeps all runner commands in a single `bin/` directory.
- Documents the optional MCP servers that make browser debugging and Jira/Confluence work practical in large Moodle tasks.

## Recommended layout

```text
~/projects/moodle                 # Moodle LMS checkout
~/projects/moodle-docker          # moodle-docker checkout
~/projects/agentic_orchestrator   # agentic orchestrator checkout
~/projects/moodle/claude          # this repository
```

Key paths and conventions:

- Repository root: `~/projects/moodle/claude`
- Wrapper scripts: `~/projects/moodle/claude/bin`
- Prompt library: `~/projects/moodle/claude/prompts`
- Prompt index: `~/projects/moodle/claude/prompts/README.md`
- Jira field map: `~/projects/moodle/claude/config/jira_field_map.yaml`
- Moodle branching guide: `~/projects/moodle/claude/docs/moodle-branching.md`
- Jira write-back guide: `~/projects/moodle/claude/docs/jira-writeback.md`

Working rules:

- Run commands from the `claude/` repository root.
- Invoke helpers as `./bin/<command>`.
- Do not run those helpers from the parent Moodle checkout.
- The Moodle LMS root is the parent directory, `~/projects/moodle`.
- PHPCS and PHPCBF run on the host against that checkout.
- PHPUnit, Behat, install, and runtime commands run in the web container against the mounted checkout.
- Grunt runs on the host against the parent Moodle checkout through `./bin/grunt`.

Local author metadata for generated Moodle file headers lives in:
- template: `~/projects/moodle/claude/.claude.identity.example`
- real local file: `~/projects/moodle/claude/.claude.identity`

The real `.claude.identity` file is ignored by git.
If `.claude.identity` is missing and a task needs new Moodle source files, Claude Code should stop that path and ask for the local identity file to be created or for an explicit fallback to be approved first.

## Phase-one orchestrator integration

Phase one keeps orchestrator integration intentionally light. This repository does not vendor, embed, or deeply integrate the orchestrator runtime. Instead, it teaches Claude Code when to prefer the sibling checkout at `~/projects/agentic_orchestrator` as a discovery tool before making changes in the local Moodle checkout.

The current orchestrator project is a thin Python CLI over four sibling runtime-facing tools:

- `agentic_devdocs`
- `agentic_indexer`
- `agentic_sitemap`
- `agentic_debug`

Its main CLI entrypoints are:

- `query` for grouped cross-source context retrieval
- `health` for local runtime health, resource presence, contract sanity, and drift checks
- `pilot-run` for a supervised live trial artifact
- `review_bundle` for a live verification artifact when needed

It is not a code editor, not a workflow engine, and not a replacement for direct local Moodle edits or the Docker-backed test harness.

Use orchestrator for:

- implementation-pattern discovery before coding
- "how does Moodle do X?" questions
- cross-source retrieval across docs, code, and site context
- broader debugging and investigation tasks

Do not use orchestrator for:

- simple local edits in already-identified files
- direct linting, PHPUnit, Behat, install, and docker lifecycle work
- direct execution tasks where the needed files and commands are already known

Preferred sequence for non-trivial Moodle work:

1. Use orchestrator first for discovery and pattern-finding, usually through its `query` command in the sibling repo.
2. Identify the right implementation pattern across docs, code, and site context.
3. Make direct local changes in the Moodle checkout.
4. Use this local harness for linting, tests, runtime checks, and Docker operations.

If orchestrator availability or health has not been manually verified in the current setup, Claude Code should explicitly say that and block orchestrator-dependent workflows until manual verification is done. Clearly local edits and direct execution tasks can still proceed without orchestrator.

Warnings should be interpreted explicitly rather than flattened into a single pass/fail:

- stale sitemap or stale resource warnings usually still allow code/docs pattern discovery
- those warnings reduce trust in live site-context freshness, so Claude Code should say that clearly
- warnings affecting a specific source backend or contract reduce trust in that source directly
- if a task depends heavily on a warned source, Claude Code should call that out and avoid overstating confidence

### What manual verification means in practice

In the current orchestrator project, "manually verified" should mean:

1. The orchestrator repo is installed in a local virtual environment.
2. A real local config exists, typically `config.local.toml`, pointing at valid sibling tool commands and resources.
3. A health check succeeds without `FAIL` statuses when run in the orchestrator repo, not in `~/projects/moodle/claude`:

```bash
cd ~/projects/agentic_orchestrator
PYTHONPATH=src python3 -m agentic_orchestrator.cli health --config ./config.local.toml
```

4. At least one real orchestrated retrieval succeeds from that orchestrator repo, for example:

```bash
cd ~/projects/agentic_orchestrator
PYTHONPATH=src python3 -m agentic_orchestrator.cli query \
  "add admin settings to a plugin" \
  --config ./config.local.toml \
  --json
```

Optional stronger verification:

```bash
cd ~/projects/agentic_orchestrator
PYTHONPATH=src python3 -m agentic_orchestrator.cli pilot-run \
  "add admin settings to a plugin" \
  --config ./config.local.toml \
  --task-label admin_settings
PYTHONPATH=src python3 -m agentic_orchestrator.review_bundle --config ./config.local.toml
```

Until that verification has happened, Claude Code should treat orchestrator-dependent discovery as unavailable.

## First-day setup

1. Clone this repo into a `claude` subdirectory inside your Moodle checkout:

```bash
git clone <YOUR_REPO_URL> ~/projects/moodle/claude
```

2. Change into the repository root and create your local environment file:

```bash
cd ~/projects/moodle/claude
cp .claude.env.example .claude.env
```

3. Edit `.claude.env` and confirm these values:

- `MOODLE_DIR="$HOME/projects/moodle"` or leave the default if this repository already lives at `~/projects/moodle/claude`
- `MOODLE_DOCKER_DIR="$HOME/projects/moodle-docker"`
- `AGENTIC_ORCHESTRATOR_DIR="$HOME/projects/agentic_orchestrator"` if you keep the orchestrator checkout in the recommended sibling location
- `WEBSERVER_SERVICE="webserver"` (or your service name)
- `WEBSERVER_USER="www-data"` (or your preferred container user)
- `MOODLE_ADMIN_USERNAME="admin"` for browser login and CLI install
- `MOODLE_ADMIN_PASSWORD="test"` for browser login and CLI install
- `PHPCS_BIN="phpcs"` and `PHPCBF_BIN="phpcbf"` unless your environment exposes them differently
- `PHPCS_STANDARD="moodle"` by default, or `moodle-extra` for a stricter pass when needed
- optional Jira REST fallback values when you want authenticated Jira write-back outside Atlassian Rovo MCP:
  - `JIRA_BASE_URL="https://moodle.atlassian.net"`
  - `JIRA_USER_EMAIL="you@example.com"`
  - `JIRA_API_TOKEN="your-jira-api-token"`

4. Create your local author metadata file for generated Moodle headers:

```bash
cp .claude.identity.example .claude.identity
```

Set:

- `AUTHOR_NAME`
- `AUTHOR_EMAIL`
- `COPYRIGHT_YEAR`

Claude Code should use these values for new Moodle file docblocks in the form:

- `@copyright  {year} {Author} <{email}>`

If this file is missing, Claude Code should not silently fall back to git identity for new Moodle source files.

5. Run a first environment check from `~/projects/moodle/claude`:

```bash
./bin/up
./bin/doctor
```

6. Prepare the test environments once per clean site build:

```bash
./bin/install
./bin/phpunit-init
./bin/behat-init
```

7. Run a lightweight smoke check:

```bash
./bin/smoke
```

## Optional MCP servers

This repository does not provision MCP servers itself. Chrome, Firefox, and Atlassian MCP servers are configured in the Claude Code client and then used alongside this harness.

Recommended MCP servers for Moodle work:

- Chrome browser MCP for Chromium-based UI reproduction, console/network inspection, and performance traces
- Firefox browser MCP for Gecko-specific checks and cross-browser verification
- Atlassian MCP for Jira and Confluence search, issue/page fetches, and lightweight project coordination

Practical setup expectations:

1. Enable the Chrome browser MCP server in your Claude Code client.
2. Enable the Firefox browser MCP server in your Claude Code client.
3. Enable the Atlassian MCP server in your Claude Code client and authorize the Moodle Atlassian site you need.
4. Restart the Claude Code session after connecting or reauthorizing the servers.

This repo does not use `.claude.env` for MCP configuration. Keep MCP credentials and tenant settings in the Claude Code client, not in committed files.

Jira REST API fallback credentials are different:

- put `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, and `JIRA_API_TOKEN` in local `.claude.env`
- keep them local-only
- do not commit real values
- use them only as the fallback path when Atlassian Rovo MCP cannot complete a Jira write

## Jira Write-Back Access

Use the canonical guidance in [jira-writeback.md](docs/jira-writeback.md).

Practical rules:

- many Moodle Jira issues are publicly readable
- public readability does not imply authenticated write access
- a successful Jira read through Atlassian Rovo MCP does not prove Jira write-back will succeed
- Jira write-back should use this order:
  1. Atlassian Rovo MCP first
  2. Jira REST API fallback second using local `.claude.env` credentials
  3. browser-based Jira interaction last when the browser session is authenticated for editing
- browser interaction is the final fallback, not the default

## MCP smoke checks

`./bin/smoke` and `./bin/feature-smoke` validate the shell and Docker harness only. They do not verify MCP servers because MCP connectivity is attached to the Claude Code client, not to the shell environment.

When setting up a machine or reconnecting auth, run lightweight MCP smoke checks in a Claude Code session:

- Chrome MCP:
  - open a blank or `data:` page
  - confirm the page snapshot loads
  - optionally read console or network state if the task depends on it
- Firefox MCP:
  - open a blank or `data:` page
  - confirm the page snapshot loads
  - optionally verify a second-browser reproduction path
- Atlassian MCP:
  - fetch the current Atlassian user
  - list accessible resources
  - run one small Jira or Confluence read, for example project search or space listing

If any of these fail, fix the Claude Code client MCP connection first before relying on browser automation or Atlassian lookups in a Moodle task.

## Daily workflow with Claude Code

1. Open Claude Code with cwd at `~/projects/moodle/claude`.
2. Start each session with `PROMPT_TEMPLATE.md`.
3. Choose the closest reusable workflow prompt from `prompts/README.md` when the task matches one.
4. Have Claude Code classify the task first:
   - trivial local edit in already-known files, or
   - non-trivial Moodle task that should use orchestrator first for discovery
5. For non-trivial Moodle work, require Claude Code to use the orchestrator checkout first, normally by relying on its `query`-style discovery workflow, unless you have not manually verified orchestrator availability yet.
6. When orchestrator is needed but not manually verified, require Claude Code to say that explicitly and stop before discovery-dependent implementation.
7. If the task needs new Moodle source files, require `.claude.identity` to exist before file generation. Do not allow silent fallback to git identity.
8. Ask Claude Code to edit code in `MOODLE_DIR`, run PHPCS on the host via `./bin/phpcs`, and run PHPUnit, Behat, and runtime commands via the Docker-backed `./bin/*` wrappers.
9. For Moodle JavaScript tasks, have Claude Code:
   - edit source files in `amd/src/`, not `amd/build/*.min.js`
   - treat generated `amd/build/` assets as rebuild targets rather than hand-edited source
   - prefer `./bin/grunt amd --files=<sourcefile>` or `./bin/grunt amd --root=<component>` over broad builds
   - only use broader tasks like `./bin/grunt js` when the task really spans multiple JS build families
10. For new files, use full-file PHPCS. For edits in large legacy files, prefer changed-line-focused linting with `./bin/preflight --changed-lines`.
11. After non-trivial Moodle code changes, have Claude Code run `./bin/upgrade` when the change introduces or updates plugin-discovered features such as settings pages, DB definitions, or other upgrade-sensitive plugin metadata.
12. When browser validation is needed, have Claude Code log in with the explicit admin credentials from `.claude.env`, navigate to the relevant page, and confirm the feature renders correctly.
13. For scheduled-task work, require the fuller validation path:

- `./bin/preflight`
- `./bin/upgrade`
- targeted PHPUnit where practical
- explicit single-task execution through `admin/cli/scheduled_task.php --execute='\component\task\classname' --force`
- admin login and validation on `/admin/tool/task/scheduledtasks.php`
- confirmation of a safe observable effect

14. When the task touches browser behaviour or Jira/Confluence context, explicitly tell Claude Code to use the connected Chrome, Firefox, or Atlassian MCP servers and to smoke-check them first if the session is fresh.
15. Require targeted checks before completion:

- `./bin/phpcs <touched paths>` for explicit whole-file linting
- `./bin/preflight` for the normal targeted PHPCS pass
- `./bin/preflight --changed-lines [--base-ref <ref>] [paths...]` for changed-line-focused linting of legacy-file edits
- `./bin/phpunit <targeted tests>`

## Workflow Stages

After setup and smoke validation, the normal human workflow is:

1. PRD
2. PRD-to-Jira decomposition and alignment
3. Ticket refinement where needed
4. Development from an existing Jira issue

Use the README in that same order:

1. Start with the PRD workflow when the work still needs product definition.
2. Move to PRD-to-Jira decomposition when the PRD is stable and you need a coherent ticket set.
3. Refine individual Jira tickets when a single ticket still needs clarification.
4. Start development only once the Jira issue is ready to drive implementation.

## JavaScript and Grunt workflow

For normal Moodle AMD work, the authoring source of truth is `amd/src/`.
Generated `amd/build/*.min.js` files are build output and should not be hand-edited in normal task work.

Practical Claude Code guidance:

- Edit the smallest relevant source module under `amd/src/`.
- Treat built files in `amd/build/` as generated artifacts that should be refreshed through Grunt when the workflow expects committed build output.
- Prefer targeted Grunt commands over broad rebuilds:
  - `./bin/grunt amd --files=public/mod/example/amd/src/widget.js`
  - `./bin/grunt amd --root=public/mod/example`
- Use broader tasks like `./bin/grunt js` only when the change genuinely spans AMD, YUI, and React/ESM surfaces.
- `./bin/upgrade` is usually not part of a normal JS-only change unless plugin metadata or other upgrade-sensitive behaviour also changed.

Minimal safe JS validation should usually include:

1. edit the `amd/src/` source file
2. run the narrowest practical Grunt build
3. confirm the generated build artifact exists or was refreshed as expected
4. run any bounded automated check that fits the feature
5. do real browser/runtime validation when the JS affects visible behaviour

Claude Code should report:

- which source files were treated as authoritative
- the exact Grunt command run
- whether built artifacts were refreshed
- what browser/runtime validation was used
- `./bin/behat <targeted tags>` for UI/behaviour changes

## Core commands

- `./bin/help` - show available commands
- `./bin/up` - start containers (`up -d`)
- `./bin/down` - stop containers
- `./bin/ps` - show docker service status
- `./bin/logs [service]` - follow docker logs
- `./bin/install` - install Moodle database/site
- `./bin/upgrade [upgrade-args...]` - run Moodle upgrade CLI in the web container
- `./bin/smoke` - run a lightweight end-to-end harness check
- `./bin/feature-smoke [--reset] [--skip-behat]` - run a real install/init/test workflow
- `./bin/phpunit-init` - initialize PHPUnit environment
- `./bin/phpunit [test-path-or-filter]`
- `./bin/behat-init`
- `./bin/behat --tags=@tagname`
- `./bin/behat public/local/example/tests/behat/example.feature`
- `./bin/behat local/example/tests/behat/example.feature`
- `./bin/phpcs <paths...>` - run PHPCS on the host with the `moodle` coding standard by default
- `./bin/preflight [paths...]` - targeted PHPCS pass; new and existing files are linted as whole files by default
- `./bin/preflight --changed-lines [--base-ref <ref>] [paths...]` - report PHPCS issues on changed lines in tracked files and whole new files
- `./bin/phpcs-changed [--base-ref <ref>] [paths...]` - report PHPCS issues on changed lines in tracked files and full new files
- `./bin/phpcbf <paths...>` - run PHPCBF on the host with the `moodle` coding standard by default
- `./bin/changed-files [base-ref]` - diff against an explicit ref or auto-detect a sensible base
- `./bin/web <command...>` - run arbitrary command in web container as `WEBSERVER_USER`
- `./bin/web-root <command...>` - run arbitrary command in web container as default/root user
- `./bin/mdc <compose args...>` - direct moodle-docker-compose passthrough

`./bin/behat` accepts:

- option-style arguments such as `--tags=@tagname`
- Moodle-checkout-relative feature paths such as `public/local/example/tests/behat/example.feature`
- short feature paths relative to `public/`, such as `local/example/tests/behat/example.feature`, when the checkout uses the `public/` layout

The wrapper normalizes supported feature paths to container-visible absolute paths before invoking Moodle's Behat runner, so targeted feature runs do not depend on the container working directory.

## What `smoke` does

`./bin/smoke` is a fast, non-destructive validation step. It:

- runs `./bin/doctor`
- checks that the web container is reachable
- verifies the mounted Moodle checkout is visible inside the container
- verifies the Moodle install, PHPUnit, and Behat CLI paths are reachable
- verifies the configured PHPUnit binary is executable

It does not install Moodle, initialize PHPUnit, initialize Behat, or run heavy test suites.

## What `feature-smoke` does

`./bin/feature-smoke` is the higher-value workflow validator for this harness. It:

- reuses the current Docker environment if it is already running
- starts the environment if it is not running
- supports `--reset` to run `./bin/down` and then `./bin/up`
- installs Moodle if the current environment does not appear to be installed
- runs `./bin/phpunit-init` and a small PHPUnit smoke target
- runs `./bin/behat-init` and a small Behat smoke selection

By default it uses:

- PHPUnit target: `public/lib/tests/check_test.php`
- Behat tags: `@core_cache&&~@javascript`

Use `--skip-behat` when you want the install and PHPUnit workflow without the slower Behat pass.
Use `--reset` only when you explicitly want a clean environment. `./bin/down` destroys the DB and implies a reinstall is needed.

## Admin Credentials

The harness uses explicit admin credentials for both install-time setup and browser login:

- `MOODLE_ADMIN_USERNAME`
- `MOODLE_ADMIN_PASSWORD`
- `MOODLE_ADMIN_EMAIL`

Default values remain:

- username: `admin`
- password: `test`
- email: `admin@example.com`

For compatibility, the install wrapper still accepts the older `ADMIN_USER`, `ADMIN_PASS`, and `ADMIN_EMAIL` names, but new configuration should use the `MOODLE_ADMIN_*` variables.

## Post-Implementation Workflow

After Claude Code writes non-trivial Moodle code, the normal sequence should be:

1. Run targeted linting with `./bin/preflight` or `./bin/phpcs`.
2. Run `./bin/upgrade` if the change affects plugin registration, settings discovery, upgrade steps, or other metadata-driven behaviour.
3. If browser validation is required, use Chrome MCP first:
   - open the Moodle login page
   - sign in with `MOODLE_ADMIN_USERNAME` and `MOODLE_ADMIN_PASSWORD`
   - navigate to the relevant admin page, for example `/admin/settings.php?section=<settingspageid>`
   - confirm the setting page loads and the new control renders with the expected label and default value
4. Use Firefox MCP for follow-up cross-browser validation when the task needs it.

For the local plugin admin settings example, the browser-validation path is:

- login at `/login/index.php`
- open `/admin/settings.php?section=local_claudedemo`
- confirm the page title and the example setting appear

This phase intentionally keeps browser validation lightweight and manual through Claude Code MCP tools rather than adding a full browser automation framework.

## Reusable Prompt Templates

Start with the prompt index in [prompts/README.md](prompts/README.md).

For a brand new Claude Code session, use the priming prompt in [priming-prompt](priming-prompt) first.
This is not a task-specific workflow prompt. It is the short session-opening prompt that sets the scene, tells Claude Code about the harness, and establishes the required Moodle development workflow before you give the real task.

Practical use:

1. Start a fresh Claude Code session.
2. Paste the contents of [priming-prompt](priming-prompt) as the first message.
3. Then give the real development task.

Reusable task prompts live in `prompts/`:

- [user-prd-template.md](prompts/user-prd-template.md)
- [agent-create-prd.md](prompts/agent-create-prd.md)
- [agent-decompose-prd-to-jira.md](prompts/agent-decompose-prd-to-jira.md)
- [user-ticket-template.md](prompts/user-ticket-template.md)
- [agent-create-ticket.md](prompts/agent-create-ticket.md)
- [jira-driven-moodle-development-workflow-v1.md](prompts/jira-driven-moodle-development-workflow-v1.md)
- [create-local-plugin.md](prompts/create-local-plugin.md)
- [add-plugin-admin-settings.md](prompts/add-plugin-admin-settings.md)
- [create-web-service.md](prompts/create-web-service.md)
- [create-scheduled-task.md](prompts/create-scheduled-task.md)
- [create-renderer-mustache-ui.md](prompts/create-renderer-mustache-ui.md)

These prompts cover Moodle development work plus adjacent Jira and PRD authoring workflows, and they are aligned with the current `./bin/*` harness so human developers can start Claude Code sessions from a stronger baseline.

Read them in workflow order:

1. Use the PRD workflow when the work is still at the product-definition stage and you need a complete Product Requirements Document before Jira epic or ticket creation.
2. Use the PRD-to-Jira decomposition workflow when the PRD is complete and you want an alignment-first decomposition pass before Jira-ready Epic and ticket content is produced.
3. Use the ticket-authoring prompt when the main goal is to refine or create a Jira ticket before development starts, including suggesting an issue type for confirmation when the type is not settled yet.
4. Use the Jira-driven workflow prompt when the work starts from a Jira issue and you want Claude Code to treat the ticket as the source of truth, read comments before coding, prepare testing instructions, plan branching, and prepare Jira-ready updates alongside the implementation work.
5. Use local markdown Jira artifacts as an optional review step when you want one file per ticket plus an index before any Jira write-back.
6. Use the development prompts after the Jira issue is ready and implementation can begin.

The committed Jira field map at [jira_field_map.yaml](config/jira_field_map.yaml) is the source of truth for Jira field IDs and Jira workflow metadata in this repo. It separates human concepts such as testing instructions, branch repository fields, and diff links from raw Jira custom field IDs, and it is groundwork for later MCP-backed Jira write-back automation.
The canonical Moodle version-to-branch mapping and issue-branch naming guidance live in [moodle-branching.md](docs/moodle-branching.md). Use that file when Jira-driven work needs to map target versions to base branches or form per-issue development branch names.
The canonical Jira write-back access and fallback guidance live in [jira-writeback.md](docs/jira-writeback.md). Use that file when Jira work needs to distinguish public reads from authenticated writes or choose between MCP, API fallback, and browser fallback.

## Jira Workflows

Use the Jira-related prompts when the work starts before implementation and needs to move from product definition into Jira-ready planning, then into development.

This sits earlier in the sequence:

1. PRD
2. PRD-to-Jira decomposition with alignment first
3. Optional local Jira review artifacts
4. Jira epic and supporting tickets
5. Development work

### Flow Overview

- Create or refine the PRD: use [user-prd-template.md](prompts/user-prd-template.md) with [agent-create-prd.md](prompts/agent-create-prd.md).
- Decompose the PRD into Jira-ready issues with alignment first: use [agent-decompose-prd-to-jira.md](prompts/agent-decompose-prd-to-jira.md).
- Optionally write the final aligned ticket set into local markdown review artifacts before Jira write-back.
- Refine a single Jira ticket when needed: use [user-ticket-template.md](prompts/user-ticket-template.md) with [agent-create-ticket.md](prompts/agent-create-ticket.md).
- Work from an existing Jira issue once implementation should begin: use [jira-driven-moodle-development-workflow-v1.md](prompts/jira-driven-moodle-development-workflow-v1.md).

### Create Or Refine A PRD

Use this path when the work needs a fuller product-definition pass before Jira authoring starts.

Quick start:

```md
Use prompts/agent-create-prd.md.

Here is my partially completed PRD based on prompts/user-prd-template.md:
[paste PRD draft here]

Reference tickets or examples:
- [optional links or notes]
```

Use the PRD workflow when:

- the problem space is still being shaped
- the user value or expected outcome needs clarification
- scope and non-goals are not yet crisp
- the team wants a Confluence-compatible PRD before creating an epic

Do not use it as a substitute for:

- direct Jira ticket authoring when a full PRD is unnecessary
- development-from-Jira workflows when the issue already exists and should drive implementation

How it works:

1. The user fills in as much of [user-prd-template.md](prompts/user-prd-template.md) as they can.
2. The agent uses [agent-create-prd.md](prompts/agent-create-prd.md) to review the draft, identify weak or missing sections, and ask one or two rounds of targeted clarification questions.
3. The agent produces a final PRD in Confluence-compatible markdown, preserving the template structure and making the problem, value, scope, non-goals, dependencies, risks, and success metrics explicit.
4. That finished PRD can then be used as the source material for later Jira epic and ticket creation.

### Decompose PRD Into Jira Issues

Use this path when the PRD is already complete and the next step is to break it into a coherent Jira issue set without jumping straight to final ticket generation.

Quick start:

```md
Use prompts/agent-decompose-prd-to-jira.md.

Epic key: MDL-EPIC-123 (or none yet)

Here is the completed PRD:
[paste PRD here]

Reference Jira tickets or epics:
- [optional links or notes]
```

Follow this sequence:

1. Start with the finished PRD from [user-prd-template.md](prompts/user-prd-template.md) and [agent-create-prd.md](prompts/agent-create-prd.md), or an equivalent completed PRD.
2. Give that PRD to the agent with [agent-decompose-prd-to-jira.md](prompts/agent-decompose-prd-to-jira.md).
3. Optionally include an existing Epic key and similar Jira tickets or epics as supporting examples.
4. The agent first summarises the PRD, identifies logical work slices, classifies draft issue types, surfaces assumptions and risks, and asks targeted clarification questions.
5. The user aligns on scope, grouping, and assumptions.
6. Only then does the agent generate final Jira-ready ticket content with summaries, descriptions, acceptance criteria, testing instructions, target branches, dependencies, labels where relevant, and any explicit uncertainties.
7. If requested, the agent can write that final ticket set into local markdown review artifacts, typically one file per ticket plus an index, before any Jira write-back.

This step is still planning work.
It does not write to Jira, create code, or replace the later Jira-driven development workflow.

Example local-artifact follow-up:

```md
Use prompts/agent-decompose-prd-to-jira.md.

The alignment phase is complete.
Write the final aligned ticket set into local markdown review artifacts with one file per ticket and an index file.
Do not write to Jira yet.
```

### Create Or Refine A Jira Ticket

Use this path when a single ticket is still rough, incomplete, or ambiguous and you do not need a full PRD-first flow.

Quick start:

```md
Use prompts/agent-create-ticket.md.

Here is my rough ticket draft based on prompts/user-ticket-template.md:
[paste ticket draft here]
```

Follow this sequence:

1. Start from [user-ticket-template.md](prompts/user-ticket-template.md).
2. Give that draft to the agent with [agent-create-ticket.md](prompts/agent-create-ticket.md).
3. The agent asks targeted questions about the problem, value, scope, users, and acceptance criteria.
4. If the issue type is not yet settled, the agent may suggest `Bug`, `Improvement`, or `New Feature` and explain why.
5. The user confirms the issue type before any Jira field write-back.
6. The agent prepares structured Jira-ready ticket content and prefers Atlassian Rovo MCP first for write-back.
7. If MCP write is unavailable or fails because authenticated write access is missing, the agent may use Jira REST API fallback when local `.claude.env` credentials are configured.
8. If both MCP and API fallback are unavailable or fail, browser-based Jira interaction may be used as the final fallback when the browser session is authenticated for editing.

### Work From An Existing Jira Ticket

Use this path when the Jira issue already exists and should drive the development work.

Quick start:

```md
Use prompts/jira-driven-moodle-development-workflow-v1.md.

Jira issue key: MDL-88194
Additional local constraints: none
```

Invoke it by giving the agent the workflow prompt together with the Jira issue key, for example:

```md
Use prompts/jira-driven-moodle-development-workflow-v1.md.

Jira issue key: MDL-88194
Additional local constraints: none
```

Follow this sequence:

1. Start with [jira-driven-moodle-development-workflow-v1.md](prompts/jira-driven-moodle-development-workflow-v1.md).
2. The agent reads the Jira fields and recent comments.
3. The agent asks clarification questions if the issue is still ambiguous.
4. Stop before coding until the issue and comments have been understood well enough to proceed.
5. The settled Jira issue type then drives branching and backport planning.
6. Map target versions to Moodle base branches using [moodle-branching.md](docs/moodle-branching.md).
7. Create per-issue development branches from those base branches, for example `MOODLE_502_STABLE_MDL-12345`, and do not commit directly to `main` or `MOODLE_*_STABLE`.
8. Read access can remain MCP-first, but do not assume public readability implies authenticated write capability.
9. Only then does the agent proceed to implementation, validation, and Jira-ready updates, preferring Atlassian Rovo MCP first for write-back.
10. If MCP write fails because authenticated write access is unavailable or insufficient, use Jira REST API fallback when local `.claude.env` credentials are configured.
11. If both MCP and API fallback are unavailable or fail, browser-based Jira interaction may be used as the final fallback when the browser session is authenticated for editing.

### Jira Field Mapping And Rules

The Jira field and workflow mapping files are:

- [jira_field_map.yaml](config/jira_field_map.yaml)
- [moodle-branching.md](docs/moodle-branching.md)
- [jira-writeback.md](docs/jira-writeback.md)

They contain the source of truth for:

- Jira field IDs
- branching rules
- testing instruction rules
- ticket completion expectations
- Moodle version-to-branch mapping
- issue-branch naming conventions
- Jira read-vs-write access expectations
- Jira write-back fallback order

Use these files rather than guessing Jira custom field mappings or Moodle branch names in prompts or future automation.

## PHPCS Defaults

PHPCS and PHPCBF run on the host from the parent Moodle checkout at `~/projects/moodle`.

- Default binary: `phpcs`
- Default fixer binary: `phpcbf`
- Default standard: `moodle`
- Optional stricter standard: `moodle-extra`
- New files should be linted as whole files.
- Existing legacy files should usually be linted with `./bin/preflight --changed-lines` so newly touched lines meet current PHPCS expectations without taking on all historical lint debt.

If your local setup differs, override `PHPCS_BIN`, `PHPCBF_BIN`, or `PHPCS_STANDARD` in `.claude.env`.
If `./bin/doctor` reports that `phpcs` is not runnable, point `PHPCS_BIN` or `PHPCBF_BIN` at the actual executable path on the host machine.

## Feature Smoke Defaults

`./bin/feature-smoke` supports simple overrides in `.claude.env`:

- `FEATURE_SMOKE_PHPUNIT_TARGET="public/lib/tests/check_test.php"`
- `FEATURE_SMOKE_BEHAT_TAGS="@core_cache&&~@javascript"`

These defaults are intentionally small and core-oriented so the command validates the harness without turning into a full test run.

## Branch and commit discipline

In your Moodle repo (`~/projects/moodle`):

- Create one branch per issue/task.
- Keep one logical change per commit.
- Include tests in same commit as behaviour changes.
- Use `./bin/changed-files <base-branch>` to scope linting, or let it auto-detect a base when your repo layout is conventional.

Suggested commit summary style when an issue key exists:

```text
MDL-12345 component_name: concise imperative summary
```

## Notes

- Use `./bin/*` commands directly from this repository.
- This repo does not need to be inside `~/projects/moodle-docker`; it points there via `.claude.env`.
- This repo does not need to be inside `~/projects/agentic_orchestrator`; phase one expects that checkout to remain a separate sibling directory.
- The orchestrator's real local verification flow currently lives in its own repo and centers on `health`, `query`, and optionally `pilot-run` or `review_bundle`.
- `./bin/web` uses `WEBSERVER_USER` to avoid creating root-owned files on the mounted Moodle checkout.
- `./bin/web-root` is available for commands that genuinely need the container default user.
- Chrome, Firefox, and Atlassian MCP servers are optional but strongly recommended for real Moodle debugging and project context work.

## License

GNU General Public License v3. See [LICENSE](LICENSE).
