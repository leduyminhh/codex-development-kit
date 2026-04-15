---
name: automation-testing
description: Use when creating, updating, running, debugging, or planning automated tests across stacks, including unit tests, integration/API tests, end-to-end tests, test fixtures/data, coverage gap analysis, and flaky test stabilization. Use after QA review when the next step is executable automated test implementation or verification.
---

# Automation Testing

## Overview

Use this skill to turn requirements, QA review findings, bug reports, architecture notes, or code changes into executable automated tests. This skill is implementation-oriented; use `qa-reviewer` first when the work is only independent review or manual test planning.

## Operating Mode

1. Identify the behavior under test, acceptance criteria, and affected files.
2. Detect the stack and existing test framework before adding tests.
3. Load only the relevant resource or subagent prompt.
4. Prefer test-first for bug fixes and new behavior:
   - write the smallest failing test
   - verify the failure is meaningful
   - implement or adjust code only when requested or required by the test task
   - verify the test passes
5. Reuse existing test helpers, fixtures, factories, page objects, mock servers, and CI commands.
6. Keep tests deterministic, isolated, and behavior-focused.
7. Run the narrowest useful command first, then broader commands when risk justifies it.
8. Report commands, results, coverage gaps, and any remaining manual checks in Vietnamese.

## Resource Map

- `resources/framework-detection.md`: identify stack, package manager, test runner, and command selection.
- `resources/test-implementation-rules.md`: rules for deterministic, behavior-first automated tests.
- `resources/verification-report.md`: final test result and evidence format.

## Must-Have Subagents

- `subagents/test-strategy-planner.md`: choose test level and execution order.
- `subagents/unit-test-agent.md`: implement focused unit tests.
- `subagents/integration-api-test-agent.md`: implement integration, persistence, and API contract tests.
- `subagents/e2e-test-agent.md`: implement browser/user-flow tests.
- `subagents/fixture-data-agent.md`: design fixtures, factories, mocks, and test data.
- `subagents/coverage-gap-agent.md`: identify missing automated coverage.
- `subagents/flaky-test-debugger.md`: stabilize nondeterministic tests.

## Anti-Overuse Rules

- Do not add E2E tests for logic that a unit or integration test can cover reliably.
- Do not mock the class under test.
- Do not assert private implementation order.
- Do not create large test frameworks when one focused test is enough.
- Do not rewrite production code unless the user asks for implementation or the test task requires a small fix.

## Output Format

```text
Pham vi automation:
Test level da chon:
Files changed:
Commands run:
Ket qua:
Coverage gaps:
Rui ro / manual checks:
```
