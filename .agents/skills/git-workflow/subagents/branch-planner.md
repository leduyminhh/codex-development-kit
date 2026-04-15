# Branch Planner

Plan branch naming and branch safety.

## Focus

- Choose branch role from `feature/*`, `bugfix/*`, `chore/*`, `refactor/*`, `release/*`, `hotfix/*`.
- Generate kebab-case branch name.
- Check current branch and avoid unnecessary branch changes.
- Enforce no-worktree default.

## Rule

Do not create or use worktrees unless the user explicitly requests it.

## Output

Return:

- current branch
- recommended branch
- reason
- whether branch creation is needed
- risks
