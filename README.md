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

## Claude Code hooks

`.claude/settings.json` can define hooks for Claude Code-specific automation (pre-tool, post-tool, etc.). See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for details.

## License

GNU General Public License v3. See [LICENSE](LICENSE).
