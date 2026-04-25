# Jira Write-Back Access And Fallbacks

Use this file as the canonical reference for Jira write-back behavior in this repo.

## Core rule

Treat Jira read access and Jira write access as separate checks.

- Public readability does not imply authenticated write capability.
- Successful Jira reads through Atlassian Rovo MCP do not prove that Jira writes will succeed.
- Browser visibility does not prove that the browser session is authenticated for editing.

## Preferred fallback order

1. Atlassian Rovo MCP first (reads always; writes only for restricted/login-required MDL tickets)
2. Jira REST API fallback using local credentials from `.claude.env`
3. Browser-based Jira interaction as the final fallback

Browser interaction is a last resort, not the default.

## Rovo MCP write limitation for publicly readable MDL tickets

Rovo MCP cannot write to MDL tickets that are publicly readable without login. The MCP server
refuses writes to issues it accessed anonymously, returning:

> `This issue is anonymous and can't be updated using Rovo MCP Server.`

This is a structural Rovo MCP server-side limitation tied to anonymous read access, not to the
MDL project as a whole. It cannot be fixed by re-authenticating, switching accounts, or retrying.

**Ticket type determines which write path to use:**

| Ticket type | MCP read | MCP write | REST write |
|---|---|---|---|
| Standard MDL ticket (publicly readable) | ✓ works | ✗ fails (anonymous) | ✓ use `./bin/jira-update` |
| Restricted MDL ticket (security issues, login required) | ✓ works | ✓ works | ✓ also works |

For standard publicly readable MDL tickets, skip Rovo MCP for writes and go directly to
`./bin/jira-update`. For restricted/security tickets, Rovo MCP writes work normally.

### Verifying OAuth session health before writes

Before attempting a Rovo MCP write on any restricted ticket, verify the session is active:

1. Call `atlassianUserInfo` — confirms the OAuth token is active.
2. Call `getAccessibleAtlassianResources` — confirms the site is accessible.

If either call fails, switch to REST fallback. If both succeed but a write still fails with the
anonymous error, the ticket is publicly readable — use `./bin/jira-update` instead.

## Local credential contract

Store Jira REST fallback credentials in local `.claude.env` values:

- `JIRA_BASE_URL`
- `JIRA_USER_EMAIL`
- `JIRA_API_TOKEN`

These values are local-only and must not be committed.

## How to interpret access

### Read phase

- Prefer Atlassian Rovo MCP for Jira reads.
- Publicly visible Moodle Jira issues may be readable even when no authenticated write access is available.

### Write phase

- Always assume authenticated access is required for Jira write-back.
- Prefer Atlassian Rovo MCP first for writes.
- If MCP write fails because authentication or permissions are insufficient, use Jira REST API fallback if local credentials are configured.
- If both MCP and API fallback are unavailable or fail, browser-based Jira interaction may be used if the browser session is authenticated for editing.
- For common field and comment updates, prefer `./bin/jira-update` over ad hoc `curl` payloads.

## Fast path for REST writes

Use this sequence when a Jira write is needed and MCP is unavailable or unsuitable:

1. Read the issue through Rovo MCP when possible.
2. If the MCP write fails, switch to REST immediately rather than retrying the same MCP write.
3. Check `config/jira_field_map.yaml` for the expected field ID, endpoint style, and payload shape.
4. If the field is unfamiliar, inspect `editmeta` once before the first REST write.
5. Use `./bin/jira-update` for the write.
6. Read the updated field values back and report the verified outcome.

## Common field formats

These are the known-good payload shapes for the common Moodle Jira fields used from this repo.

| Logical field | Jira field | Endpoint style | REST payload format | Notes |
| --- | --- | --- | --- | --- |
| Summary | `summary` | `PUT /rest/api/2/issue/<key>` | string | Send inside `fields.summary`. |
| Description | `description` | `PUT /rest/api/2/issue/<key>` | string | Known-good as a plain string in this workspace. |
| Testing Instructions | `customfield_10214` | `PUT /rest/api/2/issue/<key>` | string | Jira textarea field. |
| Pull from Repository | `customfield_10244` | `PUT /rest/api/2/issue/<key>` | string | Use the developer fork URL, for example `https://github.com/mattporritt/moodle`. |
| Pull Main Branch | `customfield_10221` | `PUT /rest/api/2/issue/<key>` | string | Use the pushed issue branch name, for example `main_MDL-88194`. |
| Pull Main Diff URL | `customfield_10247` | `PUT /rest/api/2/issue/<key>` | string | Use upstream Moodle compare format with branch-point hash and fork owner branch. |
| Comment | `comment` | `POST /rest/api/2/issue/<key>/comment` | string body | Send as `{"body":"..."}`. |

`./bin/jira-update` currently optimises for the string and textarea cases above. For more complex field types, inspect `editmeta` first and extend the serializer deliberately.

## Branch field conventions

When writing Moodle branch metadata to Jira:

1. Set the relevant `Pull * Branch` field to the issue branch name.
2. Set `Pull from Repository` to the developer fork/repository URL hosting that branch.
3. Set the relevant `Pull * Diff URL` to:

   `https://github.com/moodle/moodle/compare/<branch-point-hash>...<fork-owner>:<branch-name>`

4. Derive `<branch-point-hash>` from the git branch point against the target base branch at branch-creation time.
5. Do not use a fork-local compare URL such as `https://github.com/<fork>/moodle/compare/main...branch` for Jira branch fields.

For final implementation comments:

- Keep them concise.
- Focus on what changed, how to test, and any meaningful limitations.
- Do not repeat requirement detail that is already clear in the description, acceptance criteria, or testing-instructions field.

For browser-facing UI changes:

- Capture a validation screenshot after final manual/browser verification when it materially shows the implemented result.
- Attach that screenshot to the Jira ticket.
- Mention the screenshot attachment in the final implementation comment when it was added.

## Known failure modes

- Rovo MCP reads standard publicly readable MDL tickets anonymously. A successful read does not mean the OAuth session is active or write-capable.
- Rovo MCP cannot write to publicly readable MDL tickets. The MCP refuses with `"This issue is anonymous and can't be updated using Rovo MCP Server."` Use `./bin/jira-update` for these.
- Rovo MCP can write to restricted MDL tickets (e.g. security issues) that require login — these use authenticated OAuth and work normally.
- Jira field formats are not uniform. Do not assume every editable field accepts a plain string.
- Python HTTPS calls may fail locally with certificate-chain issues that do not affect `curl`. Prefer `curl` for this repo's Jira REST helper path unless there is a clear reason not to.
- A successful read does not prove the chosen write endpoint or payload shape is valid.

## Wrapper usage

Examples:

```bash
./bin/jira-update MDL-88194 --field description --file /tmp/description.md --verify
./bin/jira-update MDL-88194 --field testing_instructions --file /tmp/testing.md --verify
./bin/jira-update MDL-88194 --comment-file /tmp/comment.md --verify
./bin/jira-update MDL-88194 \
  --field description --file /tmp/description.md \
  --field testing_instructions --file /tmp/testing.md \
  --comment-file /tmp/comment.md \
  --verify
```

Inspection helpers:

```bash
./bin/jira-update MDL-88194 --editmeta
./bin/jira-update MDL-88194 --get --fields summary,description,customfield_10214,comment
```

Supported aliases:

- `description`
- `summary`
- `testing_instructions`
- `testing-instructions`
- `customfield_10214`

Comments are handled with `--comment` or `--comment-file`, not `--field comment`.

For unsupported or complex fields, prefer:

1. `./bin/jira-update <issue> --editmeta`
2. inspect `config/jira_field_map.yaml`
3. extend the helper or use a deliberate one-off REST payload

## Required reporting

When a Jira update is part of the workflow, report:

- whether Jira read access succeeded
- whether MCP write was attempted
- whether MCP write failed because authentication or permissions were insufficient
- whether REST API fallback was attempted
- whether browser fallback was used
- what update types were successfully applied

Typical update types include:

- comment
- description update
- testing instructions update
- field update

## Setup expectation

Many Moodle LMS Jira issues are publicly readable.
That does not remove the need for authenticated write access when updating issues.
