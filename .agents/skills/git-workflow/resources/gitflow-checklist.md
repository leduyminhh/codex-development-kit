# Gitflow Checklist

## Before Staging

- Inspect `git status --short`.
- Inspect relevant diffs.
- Identify unrelated changes and leave them unstaged.
- Confirm whether generated/test artifacts should be excluded.

## Before Commit

- Confirm commit type and scope.
- Generate message and Vietnamese description if the user did not provide them.
- Run relevant verification when feasible.
- Do not commit failing work unless the user explicitly asks for a checkpoint commit.

## Push

- Push current branch only.
- Use tracking when pushing a new branch.
- Report remote and branch.

## Merge

- Inspect source and target branch.
- Avoid destructive reset or checkout.
- Resolve conflicts intentionally.
- Use `merge (<scope>): <short title>` when committing merge resolution.

## Revert

- Identify the exact commit to revert.
- Prefer `git revert` over history rewriting.
- Use `revert: revert "<original title>"` format.

## Release And Hotfix

- Release branches should focus on stabilization, versioning, changelog, and final verification.
- Hotfix branches should be narrow, verified, and merged back into active release/development branches as needed.
