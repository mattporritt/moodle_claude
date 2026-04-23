# moodle_claude

A Claude Code harness for Moodle LMS development.

This repo provides a stable `./bin/*` command surface for Docker-backed Moodle development and teaches Claude Code to use `agentic_orchestrator` for discovery-first workflows before coding.

## Repository layout

This repo is designed to live **inside** a Moodle LMS checkout:

```
~/projects/moodle/           ← Moodle LMS root (MOODLE_DIR)
    claude/                  ← this repo
        bin/
        CLAUDE.md
        .claude.env.example
    config.php
    version.php
    ...
```

`bin/lib.sh` defaults `MOODLE_DIR` to the parent directory, so no extra configuration is required if you follow this layout.

## Prerequisites

- [moodle-docker](https://github.com/moodlehq/moodle-docker) checked out, typically at `~/projects/moodle-docker`
- Docker running with the Moodle containers up (`./bin/up`)
- PHPCS and PHPCBF installed on the host with the `moodle` coding standard available
- Python 3.12+ and the `agentic_orchestrator` repo for non-trivial discovery tasks

## Setup

```bash
cp .claude.env.example .claude.env
# Edit .claude.env — adjust paths for your machine
./bin/doctor
```

`doctor` validates the environment, Docker wiring, host tooling, and Moodle checkout. Address any `ERROR` lines before proceeding; `WARN` lines indicate optional tooling that is missing.

## Workflow

### 1. Start the environment

```bash
./bin/up
./bin/ps
```

### 2. Install Moodle

```bash
./bin/install
```

### 3. Run tests

```bash
./bin/phpunit-init
./bin/phpunit path/to/tests/my_test.php

./bin/behat-init
./bin/behat --tags=@my_feature
```

### 4. Code quality

```bash
./bin/phpcs path/to/changed/file.php
./bin/phpcbf path/to/changed/file.php   # auto-fix
./bin/preflight                         # lint all changed files automatically
```

### 5. Validate the harness

```bash
./bin/smoke                  # lightweight, non-destructive
./bin/feature-smoke          # full install + PHPUnit + Behat workflow
./bin/feature-smoke --reset  # destroy and rebuild first
```

## Command reference

```
./bin/help
```

| Command | Description |
|---|---|
| `up` | Start Docker services |
| `down` | Stop Docker services |
| `ps` | Show service status |
| `logs [service]` | Follow Docker logs |
| `doctor` | Validate env and Docker wiring |
| `smoke` | Lightweight harness smoke test |
| `feature-smoke` | Full install + PHPUnit + Behat smoke workflow |
| `install` | Install Moodle database/site |
| `phpunit-init` | Initialise PHPUnit environment |
| `phpunit [args]` | Run PHPUnit tests |
| `behat-init` | Initialise Behat environment |
| `behat [args]` | Run Behat tests |
| `phpcs <path...>` | Run PHPCS on host |
| `phpcbf <path...>` | Run PHPCBF on host (auto-fix) |
| `changed-files [ref]` | List files changed vs base ref |
| `preflight [paths]` | Run PHPCS on changed/specified files |
| `web <cmd>` | Exec in web container as `WEBSERVER_USER` |
| `web-root <cmd>` | Exec in web container as root |
| `mdc <args>` | Raw `moodle-docker-compose` passthrough |

## Configuration

Copy `.claude.env.example` to `.claude.env` and adjust. Key variables:

| Variable | Default | Description |
|---|---|---|
| `MCC_ENV_FILE` | `<repo>/.claude.env` | Path to env file |
| `MOODLE_DIR` | parent of repo | Moodle LMS checkout path |
| `MOODLE_DOCKER_DIR` | `~/projects/moodle-docker` | moodle-docker checkout path |
| `WEBSERVER_SERVICE` | `webserver` | Docker service for PHP commands |
| `WEBSERVER_USER` | `www-data` | Container user for Behat/file-safe commands |
| `PHPUNIT_BIN` | `vendor/bin/phpunit` | PHPUnit binary inside container |
| `PHPCS_BIN` | `phpcs` | PHPCS binary on host |
| `PHPCBF_BIN` | `phpcbf` | PHPCBF binary on host |
| `PHPCS_STANDARD` | `moodle` | PHPCS standard name |
| `AGENTIC_ORCHESTRATOR_DIR` | _(none)_ | Path to `agentic_orchestrator` checkout |

## Agentic orchestrator integration

For non-trivial Moodle tasks, Claude Code is instructed (via `CLAUDE.md`) to use `agentic_orchestrator` for discovery before coding. This covers:

- Implementation-pattern discovery
- "How does Moodle do X?" questions
- Cross-source retrieval across docs, code index, and site context
- Broader debugging and investigation

Manual verification before orchestrator use:

```bash
cd "${AGENTIC_ORCHESTRATOR_DIR}"
# Ensure config.local.toml exists and points at valid sibling tools
PYTHONPATH=src python3 -m agentic_orchestrator.cli health --config ./config.local.toml
```

The health check must complete without `FAIL`. At least one real `query` or `pilot-run` should succeed before relying on the orchestrator for a task.

See the [agentic_orchestrator README](https://github.com/moodlehq/agentic_orchestrator) for full setup instructions.

## Reusable Prompt Templates

Start with the prompt index in [prompts/README.md](prompts/README.md).

For a brand new Claude Code session, use the priming prompt in [priming-prompt](priming-prompt) first.
This is not a task-specific workflow prompt. It is the short session-opening prompt that sets the scene, tells Claude about the harness, and establishes the required Moodle development workflow before you give the real task.

Practical use:

1. Start a fresh Claude Code session.
2. Paste the contents of [priming-prompt](priming-prompt) as the first message.
3. Then give the real development task.

Reusable task prompts live in `prompts/`:

- [create-local-plugin.md](prompts/create-local-plugin.md)
- [add-plugin-admin-settings.md](prompts/add-plugin-admin-settings.md)
- [create-web-service.md](prompts/create-web-service.md)
- [create-scheduled-task.md](prompts/create-scheduled-task.md)
- [create-javascript-change.md](prompts/create-javascript-change.md)
- [create-renderer-mustache-ui.md](prompts/create-renderer-mustache-ui.md)
- [jira-driven-moodle-development-workflow-v1.md](prompts/jira-driven-moodle-development-workflow-v1.md)

These are Moodle-specific, orchestrator-aware, and aligned with the current `./bin/*` harness so developers can start Claude Code sessions from a stronger baseline.

## Jira Workflows

Use the Jira-related prompts when the work starts from a Jira ticket or when you need to prepare a Jira ticket before development starts.

There are two distinct Jira entry paths:

### Quick Start

- Creating or refining a ticket: start with [user-ticket-template.md](prompts/user-ticket-template.md), then use [agent-create-ticket.md](prompts/agent-create-ticket.md).
- Working from an existing Jira issue: start with [jira-driven-moodle-development-workflow-v1.md](prompts/jira-driven-moodle-development-workflow-v1.md) and include the Jira issue key in your request, for example `MDL-88194`.

### Create Or Refine A Jira Ticket

Use [user-ticket-template.md](prompts/user-ticket-template.md) to draft the ticket, then give that draft to the agent with [agent-create-ticket.md](prompts/agent-create-ticket.md). The agent clarifies the problem, suggests an issue type for confirmation when not yet settled, and writes back to Jira via Atlassian Rovo MCP first, with REST API and browser fallback.

### Work From An Existing Jira Ticket

Use [jira-driven-moodle-development-workflow-v1.md](prompts/jira-driven-moodle-development-workflow-v1.md) with the Jira issue key, for example:

```md
Use prompts/jira-driven-moodle-development-workflow-v1.md.

Jira issue key: MDL-88194
Additional local constraints: none
```

The agent reads the Jira issue, clarifies ambiguity, determines branch targets from [docs/moodle-branching.md](docs/moodle-branching.md), implements the change, and prepares Jira-ready updates.

### Jira Field Mapping And Reference Files

- [config/jira_field_map.yaml](config/jira_field_map.yaml) — source of truth for Jira field IDs and workflow metadata
- [docs/moodle-branching.md](docs/moodle-branching.md) — Moodle version-to-branch mapping and issue-branch naming
- [docs/jira-writeback.md](docs/jira-writeback.md) — Jira read-vs-write access expectations and write-back fallback order

## Claude Code hooks

`.claude/settings.json` can define hooks for Claude Code-specific automation (pre-tool, post-tool, etc.). See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for details.

## License

GNU General Public License v3. See [LICENSE](LICENSE).
