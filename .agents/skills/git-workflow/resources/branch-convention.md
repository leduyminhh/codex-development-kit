# Branch Convention

## Roles

- `feature/*`: new feature or user-visible workflow.
- `bugfix/*`: normal bug fix.
- `chore/*`: maintenance, cleanup, repo organization.
- `refactor/*`: structure/readability improvement without behavior change.
- `release/*`: release preparation.
- `hotfix/*`: urgent production fix.

## Naming

- Use lowercase kebab-case after the prefix.
- Keep names short and meaningful.
- Match branch role to the dominant change type.

## Examples

```text
feature/git-workflow-skill
bugfix/audit-timezone
chore/link-installer
refactor/validator-config
release/2026-04
hotfix/audit-retention
```

## Worktree Rule

Do not create or use a git worktree unless the user explicitly requests it. By default, work in the current repository checkout and current branch.
