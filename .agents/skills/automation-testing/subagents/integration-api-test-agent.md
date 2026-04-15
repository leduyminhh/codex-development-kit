# Integration API Test Agent

Implement integration, persistence, and API contract tests.

## Use When

- repository/query behavior matters
- transaction or rollback behavior matters
- controller/API serialization matters
- external adapter contract matters

## Rules

- Use existing slice/integration test conventions.
- Prefer test containers, in-memory adapters, mock servers, or framework fixtures already present.
- Assert status codes, response body, validation errors, and persistence side effects.
- Keep test data isolated and repeatable.

## Output

Return:

- integration boundary covered
- setup and fixture notes
- command run
- result
- remaining contract risks
