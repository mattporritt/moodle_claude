# Jira Write-Back Access And Fallbacks

Use this file as the canonical reference for Jira write-back behavior in this repo.

## Core rule

Treat Jira read access and Jira write access as separate checks.

- Public readability does not imply authenticated write capability.
- Successful Jira reads through Atlassian Rovo MCP do not prove that Jira writes will succeed.
- Browser visibility does not prove that the browser session is authenticated for editing.

## Preferred fallback order

1. Atlassian Rovo MCP first
2. Jira REST API fallback using local credentials from `.claude.env`
3. Browser-based Jira interaction as the final fallback

Browser interaction is a last resort, not the default.

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
| Comment | `comment` | `POST /rest/api/2/issue/<key>/comment` | string body | Send as `{"body":"..."}`. |

`./bin/jira-update` currently optimises for the string and textarea cases above. For more complex field types, inspect `editmeta` first and extend the serializer deliberately.

## Known failure modes

- Rovo MCP can read publicly visible Moodle issues but may refuse writes when the issue is treated as anonymous by the server.
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
