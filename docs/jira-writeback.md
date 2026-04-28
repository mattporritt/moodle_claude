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

If the REST write fails with sandboxed DNS or network-resolution errors, retry with escalation and treat that as an environment restriction rather than as a Jira payload or permission failure.

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

`./bin/jira-update` currently optimises for the string and textarea cases above. Branch metadata fields are part of the normal ticket-completion workflow, but the helper does not yet provide dedicated serializers for that branch-field writeback path, so use deliberate REST fallback for those fields and verify with a read-back afterward.

## Formatting guidance for Jira content

Jira Cloud's editor supports markdown-style typing in the browser editor, but rich text is stored as Atlassian Document Format (ADF). In this repo, the current REST fallback path for the common description and textarea updates is still documented as a plain string write.

That means the safest default for REST-written issue content is conservative formatting rather than rich markdown structure.

### Preferred formatting for REST-written descriptions and comments

When writing Jira content through the current REST fallback path:

- prefer plain paragraphs
- prefer short, flat bullet lists
- prefer explicit section labels such as `Summary:`, `Problem:`, `Testing instructions:`
- use bold section labels only if they are known to render correctly in the chosen write path
- separate sections with a blank line
- keep list indentation shallow and consistent

### Avoid for REST-written content unless the renderer has been verified

- markdown heading syntax such as `#`, `##`, `###`
- deeply nested bullet or numbered lists
- mixed bullet styles in the same section
- indentation-dependent layout tricks
- HTML
- tables

### Safe formatting pattern

Prefer shapes like:

```text
Summary:
Short outcome-focused summary.

Problem:
Plain paragraph text.

Acceptance criteria:
- First criterion
- Second criterion

Testing instructions:
Setup:
- Step one

Steps:
- Step one
- Step two

Expected result:
- Result one
```

This is intentionally more conservative than what the browser editor may allow. The goal is reliable rendering in Jira when content is supplied through the current REST string path.

### If richer structure is required

- prefer MCP or browser-based editing when the task depends on Jira's rich editor behavior
- or move deliberately to an ADF-based write path rather than assuming markdown headings will render correctly through REST string writes

### Practical rule

If a Jira issue update is going through the REST string path, optimize for rendering reliability over pretty source markdown.

## Branch field conventions

When writing Moodle branch metadata to Jira:

1. Set the relevant `Pull * Branch` field to the issue branch name.
2. Set `Pull from Repository` to the developer fork/repository URL hosting that branch.
3. Set the relevant `Pull * Diff URL` to:

   `https://github.com/moodle/moodle/compare/<branch-point-hash>...<fork-owner>:<branch-name>`

4. Derive `<branch-point-hash>` from the git branch point against the target base branch at branch-creation time.
5. Do not use a fork-local compare URL such as `https://github.com/<fork>/moodle/compare/main...branch` for Jira branch fields.

Capture this metadata at branch-creation time and keep it available for later write-back:

- base branch name
- issue branch name
- branch-point hash

Which fields to update depends on which branches were actually pushed:

- `main`-only work: update `Pull from Repository`, `Pull Main Branch`, and `Pull Main Diff URL`
- stable-branch work: update `Pull from Repository` plus the corresponding version-specific `Pull * Branch` and `Pull * Diff URL` fields for each pushed stable branch

Treat these branch metadata updates as a required completion step after push, not as an optional extra after the Jira comment.

After writing branch metadata:

1. Read the values back.
2. Verify the expected repository URL, branch name, and diff URL are present.
3. Report the exact fields updated.

## Publish and write-back sequence

After code is committed and ready to leave the agent in a reviewable state:

1. Push the issue branch.
2. Confirm the pushed remote and branch name.
3. Update Jira repository, branch, and diff metadata fields.
4. Add the implementation or status comment.
5. Read back and verify the Jira values.

Treat the status comment and the structured branch metadata fields as separate completion requirements. A good implementation comment does not replace the branch metadata update.

For final implementation comments:

- Keep them concise.
- Focus on what changed, how to test, and any meaningful limitations.
- Do not repeat requirement detail that is already clear in the description, acceptance criteria, or testing-instructions field.
- If validation is blocked by a third-party entitlement, service access, or other external dependency, say so explicitly rather than letting the ticket read as fully validated.

Preferred blocker wording:

- `Implementation complete`
- `Validation partially blocked by external dependency`
- `Remaining verification steps once blocker is removed`

Reusable implementation handoff template:

```text
Implementation complete:
- Branch pushed: <branch-name>
- Repository: <fork-url>
- Updated: <short change summary>

Validation completed:
- <targeted automated/manual checks that passed>

Validation partially blocked by external dependency:
- <service, entitlement, or external dependency>

Remaining verification steps once blocker is removed:
- <manual or entitlement-dependent checks still to run>
```

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

For current branch metadata fields specifically:

- use `./bin/jira-update` for supported text and comment fields around the ticket update
- use deliberate REST fallback for the branch metadata fields
- verify those field values with a read-back afterward

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
- branch metadata update

## Setup expectation

Many Moodle LMS Jira issues are publicly readable.
That does not remove the need for authenticated write access when updating issues.
