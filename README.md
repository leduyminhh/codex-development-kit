# Codex Workflow Kit

This workspace stores reusable Codex workflow building blocks: validators, agents, skills, and domain-specific agent capabilities.

## Quick Install

Clone this repository, then link its skills into Codex native skill discovery:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-skill-link.ps1 -Force
```

The installer creates a Windows junction or symlink:

```text
~\.agents\skills\codex-workflow-kit -> <repo>\.agents\skills
```

After that, update this repository with:

```powershell
git pull
```

Skills update immediately through the link. No per-project copy step is required.

Agents, hooks, and workflow config remain in this repository as project-local templates. Import them intentionally into a project when that project needs named agents or audit hooks.

## Core Validator

The first core workflow is `codex-structure-validator`, an Agent -> Skill validator for Codex best-practice repository structure.

It validates:

- `AGENTS.md` guidance boundaries.
- `.agents/skills/<name>/SKILL.md` skill structure.
- `.codex/agents/<name>.toml` agent structure.
- `.codex/config.toml` safety defaults and profiles.
- Optional hooks and reports.
- Separation between core validator rules and domain skills.

## Domain Skills And Agents

Domain-specific skills and agents live outside the validator core.

Current domain capabilities:

- `java-architect`: Java backend architecture review and design for flow, clean code, Spring patterns, persistence, async/concurrency, and test strategy.
- `react-js`: React UI implementation from Figma, requirements, tickets, and API contracts.
- `qa-reviewer`: QA reviewer review across stacks.
- `automation-testing`: automated unit, integration/API, E2E, fixture/data, coverage, and flaky test workflows.
- `design-pattern`: design pattern advisor with approval gates before applying patterns.

Every domain skill or agent must pass `codex-best-practice-validator` before it is considered complete.

## Reference Material

`references/external/codex-cli-best-practice/` is an optional local clone path for `shanraisshan/codex-cli-best-practice` analysis. Do not treat it as source code owned by this repo unless it is explicitly converted into a submodule or vendored reference later.

## Legacy Superpowers Aliases

The earlier `superpowers-workflow` aliases are still useful as process references. Keep them until the validator and domain skills replace the need for a dedicated alias list.


