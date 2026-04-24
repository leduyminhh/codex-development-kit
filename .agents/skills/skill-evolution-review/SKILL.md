---
name: skill-evolution-review
description: Use when reviewing repeated feedback, audit evidence, or workflow drift to evolve runtime skills and agents with guarded upgrades.
---

# Skill Evolution Review

## Overview

Use this skill as the central evolution engine for runtime skills and agents. Prefer audit output and explicit feedback when those inputs are available, then evolve guidance through small, validated upgrades.

If audit or feedback flows are not yet implemented, perform a focused static review using the smallest useful set of repository evidence such as skill files, agent entries, config, and related test or automation scripts. In that case, clearly state that the review is based on repository evidence rather than runtime history.

## Operating Mode

1. Identify the target skill or agent.
2. Collect only the relevant audit and feedback evidence when that flow exists.
3. If runtime evidence is unavailable, collect only the smallest useful static repository evidence needed for the review.
4. Separate signals into:
   - correct guidance that should be preserved
   - incorrect guidance that should be removed or tightened
   - missing guidance that should be added
   - one-off noise that should not change the skill
5. Require pattern evidence before recommending an actionable upgrade; do not learn from a single anecdote unless the failure is severe and reproducible.
6. Classify the result into:
   - reject as noise
   - preserve current guidance because evidence is insufficient
   - manual review required
   - safe auto-apply for small, local, validated patches
7. Keep each proposal focused on one capability area per review.
8. Recommend the smallest patch that resolves the observed drift.
9. Produce validation steps for the proposed patch.
10. Auto-apply only when the patch is small, local, allowed by policy, and passes validation. Otherwise stop at pending approval.

## Resource Map

- `subagents/skill-drift-review.md`: classify repeated patterns, drift, and safe patch scope.
- `scripts/test-run-skill-upgrade-cycle.ps1`: validate proposal generation flow from feedback intake to pending approval output.
- `scripts/test-apply-skill-upgrade-proposal.ps1`: validate approval gate and in-scope apply behavior for approved proposals.

## Validation Commands

- `powershell -ExecutionPolicy Bypass -File .agents/skills/skill-evolution-review/scripts/test-run-skill-upgrade-cycle.ps1`
- `powershell -ExecutionPolicy Bypass -File .agents/skills/skill-evolution-review/scripts/test-apply-skill-upgrade-proposal.ps1`

## Output Format

Return Markdown with:

- Summary
- Evidence Scope
- Observed Patterns
- Correct Guidance
- Incorrect Guidance
- Missing Guidance
- Proposed Changes
- Validation Plan
- Recommendation
- Approval Status
