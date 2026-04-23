# Moodle Branching Reference

Use this file as the canonical branch-mapping reference for this repo.

## Core rules

- Moodle version numbers map to stable maintenance branches.
- `main` is the future-version branch.
- Do not commit directly to Moodle core stable branches or `main`.
- Create issue-specific development branches from the correct base branch.
- Push those development branches to the developer's own fork or repository, not the main Moodle LMS repository.

## Version to base-branch mapping

| Moodle version | Base branch |
| --- | --- |
| 4.0 | `MOODLE_400_STABLE` |
| 4.1 | `MOODLE_401_STABLE` |
| 4.2 | `MOODLE_402_STABLE` |
| 4.3 | `MOODLE_403_STABLE` |
| 4.4 | `MOODLE_404_STABLE` |
| 4.5 | `MOODLE_405_STABLE` |
| 5.0 | `MOODLE_500_STABLE` |
| 5.1 | `MOODLE_501_STABLE` |
| 5.2 | `MOODLE_502_STABLE` |

Notes:

- All Moodle `5.2.x` minor releases use `MOODLE_502_STABLE`.
- `main` represents the next future Moodle version.

## Development branch naming

Create a per-issue development branch from each required base branch.

Pattern:

- `<BASE_BRANCH>_<JIRA_KEY>`

Examples:

- `MOODLE_405_STABLE_MDL-81304`
- `MOODLE_500_STABLE_MDL-81304`
- `MOODLE_501_STABLE_MDL-81304`
- `main_MDL-81304`

## How to apply this in Jira-driven work

- The settled Jira issue type determines which Moodle versions need branches.
- Those target versions then map to Moodle base branches using the table above.
- Create one developer-owned issue branch per required base branch.
- Do not treat `main` or any `MOODLE_*_STABLE` branch as a working branch for direct commits.
