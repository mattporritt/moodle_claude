# GitHub MCP

GitHub MCP provides authenticated access to GitHub repositories, Actions runs, job logs, pull requests, and issues. It is the correct path for any GitHub data that requires authentication — particularly Actions workflow logs, which return 403 via the public REST API.

## Connectivity check

Before relying on GitHub MCP in a task, confirm it is available by listing recent workflow runs:

```
mcp__github__list_workflow_runs  (or equivalent list/search tool)
```

If the tool call fails, fall back to unauthenticated public API endpoints where they suffice (PR metadata, commit info, public check annotations).

## CI diagnostics — the right tool for each step

| Goal | Tool |
|---|---|
| Find run IDs for a branch | `mcp__github__list_workflow_runs` (filter by branch/actor) |
| Get job names and failure step | `mcp__github__get_workflow_run_jobs` or equivalent jobs listing |
| Read the actual test failure output | `mcp__github__get_job_logs` (authenticated — this is the one that needs MCP) |
| Read high-level check annotations | Unauthenticated: `curl https://api.github.com/repos/{owner}/{repo}/check-runs/{id}/annotations` — but these only show summary annotations, not test output |

### What the unauthenticated annotations API gives you

The check-runs annotations endpoint (`/actions/runs/{id}/annotations`) is public and works without a token. It returns top-level annotations such as Node.js deprecation warnings and "Process completed with exit code 1". It does **not** return the actual PHPUnit failure message or stack trace — for that you need the full job log, which requires authentication via GitHub MCP.

## Typical CI failure investigation flow

1. `curl https://api.github.com/repos/{owner}/{repo}/actions/runs/{run_id}/jobs` — get job IDs (public, no auth needed).
2. For each failing job, use GitHub MCP `get_job_logs` (or equivalent) with the job ID to retrieve the full log text.
3. Search the log for `FAILURES!`, `Error`, `Fatal`, or the specific PHPUnit test class names to locate the failing test.
4. Once the failing test is identified, reproduce locally: `./bin/phpunit <path/to/test_file.php>`.

## Developer fork convention

The Moodle developer fork used in this project is `mattporritt/moodle`. The developer remote is named `mattp`. Workflow runs triggered by pushes to `mattporritt/moodle` branches are visible at `https://github.com/mattporritt/moodle/actions`.

## Notes

- GitHub MCP tools are available as MCP server tools in the Claude Code client; they do not appear in Bash.
- Tool names may vary slightly by MCP server version — use ToolSearch with `github` if a specific tool name is uncertain.
- Do not hardcode GitHub tokens or credentials in committed files. GitHub MCP handles authentication transparently.
