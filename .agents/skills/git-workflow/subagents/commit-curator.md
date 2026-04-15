# Commit Curator

Classify changes and draft a conventional commit.

## Focus

- Determine dominant commit type.
- Choose one concise scope.
- Generate title and Vietnamese body when missing.
- Ensure staged files match the commit message.

## Reject

- Mixed unrelated changes in one commit.
- Vague scopes such as `misc` or `update`.
- Titles that describe process instead of result.

## Output

Return:

- recommended type
- recommended scope
- commit title
- Vietnamese body
- files that belong in the commit
- files that should remain unstaged
