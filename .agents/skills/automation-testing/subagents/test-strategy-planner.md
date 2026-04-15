# Test Strategy Planner

Choose the correct automated test level before implementation.

## Priority

Run first when the user asks for test automation but the correct level is unclear.

## Selection Rules

- Unit test: pure logic, domain rules, formatters, validators, reducers, hooks.
- Integration/API test: persistence, HTTP contract, serialization, transactions, external adapter boundaries.
- E2E test: critical user journey, browser behavior, routing, auth, real UI integration.
- Fixture/data work: repeated setup, brittle objects, large payloads, mock server state.
- Coverage work: unclear gaps or missing tests around changed code.
- Flaky debugging: nondeterminism, timing, race, order dependency, environment-specific failure.

## Output

Return:

- recommended test level
- subagent to use next
- command to run first
- risk if a broader/narrower test is chosen
