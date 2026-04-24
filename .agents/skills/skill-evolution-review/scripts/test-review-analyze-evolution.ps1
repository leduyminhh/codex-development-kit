param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path)

$ErrorActionPreference = 'Stop'

function Assert-Equal {
    param([object]$Expected, [object]$Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message Expected '$Expected' but got '$Actual'."
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

$scriptPath = Join-Path $PSScriptRoot 'write-skill-upgrade-proposal.py'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-review-analyze-evolution-" + [guid]::NewGuid().ToString())

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/security-code-review') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/test-qa-review') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/architecture-onion-design') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/code-shared-design') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/security-code-review/resources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/test-qa-review/resources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/architecture-onion-design/resources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/code-shared-design/resources') -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/security-code-review/SKILL.md') -Encoding utf8 -Value @'
---
name: security-code-review
description: Use when reviewing source code security.
---

# Security Code Review

## Review Defaults

- Treat missing authorization as high risk unless strong evidence says otherwise.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/security-code-review/resources/auth-session-review.md') -Encoding utf8 -Value @'
# Auth Session Review

- Session and token handling:
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/test-qa-review/SKILL.md') -Encoding utf8 -Value @'
---
name: test-qa-review
description: Use when reviewing QA scenarios.
---

# QA Reviewer

## Review Focus

- Regression risk.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/test-qa-review/resources/regression-review.md') -Encoding utf8 -Value @'
# Regression Review

- Backward compatibility of request and response contracts.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/architecture-onion-design/SKILL.md') -Encoding utf8 -Value @'
---
name: architecture-onion-design
description: Use when designing Onion Architecture.
---

# Onion Architecture

## Review Checklist

7. Verify domain has no outer ring or framework dependency leakage.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/architecture-onion-design/resources/java-package-template.md') -Encoding utf8 -Value @'
# Java Spring Boot Onion Package Template

8. Verify domain has no outer ring or framework dependency leakage.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/code-shared-design/SKILL.md') -Encoding utf8 -Value @'
---
name: code-shared-design
description: Use when designing shared modules.
---

# Shared Module Architecture

## Nexus Rule

- Breaking changes require a new major version or explicit migration plan.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/code-shared-design/resources/module-boundary-rules.md') -Encoding utf8 -Value @'
# Shared Module Boundary Rules

- Publish via Nexus with semantic versioning.
'@

    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/manifest.toml') -Encoding utf8 -Value @'
[repo_structure]
skills_root = ".agents/skills"

[evolution.defaults]
enabled = true
reviewer = "skill-evolution-review"
mode = "hybrid"
min_pattern_count = 3
allow_fast_track = true
auto_apply = false

[[evolution.profile]]
skill = "security-code-review"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/security-code-review/SKILL.md", ".agents/skills/security-code-review/resources"]
max_patch_lines = 40
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/security-code-review/scripts/test-security-code-review.ps1"]

[[evolution.profile]]
skill = "test-qa-review"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/test-qa-review/SKILL.md", ".agents/skills/test-qa-review/resources"]
max_patch_lines = 40
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/codex-structure-validate/scripts/validate-codex-structure.ps1 -Root ."]

[[evolution.profile]]
skill = "architecture-onion-design"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/architecture-onion-design/SKILL.md", ".agents/skills/architecture-onion-design/resources"]
max_patch_lines = 40
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/java-analyze/scripts/test-architecture-skills.ps1"]

[[evolution.profile]]
skill = "code-shared-design"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/code-shared-design/SKILL.md", ".agents/skills/code-shared-design/resources"]
max_patch_lines = 40
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/java-analyze/scripts/test-architecture-skills.ps1"]
'@

    $cases = @(
        @{ target = 'security-code-review'; evidence = 'missing-auth-session-checklist'; validation = 'test-security-code-review.ps1'; paths = @('.agents/skills/security-code-review/SKILL.md', '.agents/skills/security-code-review/resources/auth-session-review.md'); snippets = @('auth, session, token, and permission checklist', 'session invalidation after logout') },
        @{ target = 'test-qa-review'; evidence = 'missing-regression-scope-checklist'; validation = 'validate-codex-structure.ps1'; paths = @('.agents/skills/test-qa-review/SKILL.md', '.agents/skills/test-qa-review/resources/regression-review.md'); snippets = @('Regression scope checklist', 'Impacted user flows, persistence paths') },
        @{ target = 'architecture-onion-design'; evidence = 'missing-framework-leakage-check'; validation = 'test-architecture-skills.ps1'; paths = @('.agents/skills/architecture-onion-design/SKILL.md', '.agents/skills/architecture-onion-design/resources/java-package-template.md'); snippets = @('application services stay free from Spring', 'application services do not import Spring Web') },
        @{ target = 'code-shared-design'; evidence = 'missing-version-compatibility-checklist'; validation = 'test-architecture-skills.ps1'; paths = @('.agents/skills/code-shared-design/SKILL.md', '.agents/skills/code-shared-design/resources/module-boundary-rules.md'); snippets = @('compatibility checklist that covers consumer impact', 'review consumer impact, deprecation window') }
    )

    foreach ($case in $cases) {
        $snapshotPath = Join-Path $tempRoot ($case.target + '.snapshot.json')
        $proposalPath = Join-Path $tempRoot ($case.target + '.proposal.json')
        Set-Content -LiteralPath $snapshotPath -Encoding utf8 -Value @"
{
  "targetType": "skill",
  "targetName": "$($case.target)",
  "targetAgent": "$($case.target)",
  "targetSkills": ["$($case.target)"],
  "feedbackEntries": [
    {
      "agentName": "$($case.target)",
      "skillNames": ["$($case.target)"],
      "targetType": "skill",
      "targetName": "$($case.target)",
      "severity": "medium",
      "reproducible": true,
      "evidenceKey": "$($case.evidence)",
      "wrongNotes": "",
      "missingNotes": "Repeated missing checklist",
      "taskSummary": "Review target"
    },
    {
      "agentName": "$($case.target)",
      "skillNames": ["$($case.target)"],
      "targetType": "skill",
      "targetName": "$($case.target)",
      "severity": "medium",
      "reproducible": true,
      "evidenceKey": "$($case.evidence)",
      "wrongNotes": "",
      "missingNotes": "Repeated missing checklist",
      "taskSummary": "Review target"
    },
    {
      "agentName": "$($case.target)",
      "skillNames": ["$($case.target)"],
      "targetType": "skill",
      "targetName": "$($case.target)",
      "severity": "medium",
      "reproducible": true,
      "evidenceKey": "$($case.evidence)",
      "wrongNotes": "",
      "missingNotes": "Repeated missing checklist",
      "taskSummary": "Review target"
    }
  ]
}
"@

        & python $scriptPath --root $tempRoot --snapshot-file $snapshotPath --proposal-file $proposalPath | Out-Null
        Assert-Equal 0 $LASTEXITCODE "Writer should succeed for $($case.target)."
        $proposal = Get-Content -LiteralPath $proposalPath -Raw | ConvertFrom-Json
        Assert-Equal 'safe-auto-apply' $proposal.recommendation "$($case.target) should be safe-auto-apply for repeated evidence."
        Assert-Equal 2 $proposal.updates.Count "$($case.target) should patch both SKILL.md and resources."
        Assert-Equal $case.paths[0] $proposal.updates[0].path "$($case.target) should patch the expected skill file first."
        Assert-Equal $case.paths[1] $proposal.updates[1].path "$($case.target) should patch the expected resource file second."
        Assert-True (($proposal.updates[0].content | Out-String) -match [regex]::Escape($case.snippets[0])) "$($case.target) skill patch should contain the expected snippet."
        Assert-True (($proposal.updates[1].content | Out-String) -match [regex]::Escape($case.snippets[1])) "$($case.target) resource patch should contain the expected snippet."
        Assert-True (($proposal.validationCommands -join "`n") -match [regex]::Escape($case.validation)) "$($case.target) should attach its policy validation command."
    }

    Write-Output 'review-analyze evolution tests passed.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
