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
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-generate-execute-evolution-" + [guid]::NewGuid().ToString())

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.codex') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/test-automation-validate/resources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/test-automation-validate/scripts') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/diagram-generate/resources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/doc-write/resources') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot '.agents/skills/react-code-generate/resources') -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/test-automation-validate/SKILL.md') -Encoding utf8 -Value @'
---
name: test-automation-validate
description: Use when validating automated tests.
---

# Automation Testing

## Operating Mode

7. Run the narrowest useful command first, then broader commands when risk justifies it.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/test-automation-validate/resources/framework-detection.md') -Encoding utf8 -Value @'
# Framework Detection

- Run broader suites when touching shared helpers, contracts, test config, or CI behavior.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/test-automation-validate/scripts/test-automation-validate-strategy.ps1') -Encoding utf8 -Value @'
Assert-FileContains -Path $rules -Pattern 'consumer|provider|schema|OpenAPI|Pact' 'Rules should cover contract testing choices.'
'@

    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/diagram-generate/SKILL.md') -Encoding utf8 -Value @'
---
name: diagram-generate
description: Use when generating diagrams.
---

# Diagram-W

## Operating Mode

4. Select the smallest useful PlantUML diagram type.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/diagram-generate/resources/plantuml-diagram-selection.md') -Encoding utf8 -Value @'
# PlantUML Diagram Selection

Avoid more than two diagrams unless the user explicitly asks for a diagram pack.
'@

    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/doc-write/SKILL.md') -Encoding utf8 -Value @'
---
name: doc-write
description: Use when writing docs.
---

# Documentation Writer

9. If writing under protected paths such as `docs/` or `reports/`, request explicit confirmation before creating or updating files.
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/doc-write/resources/project-doc-output-catalog.md') -Encoding utf8 -Value @'
# Project Documentation Output Catalog

For multiple files, list every `docs/` path and summary. Do not write until the user explicitly confirms.
'@

    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/react-code-generate/SKILL.md') -Encoding utf8 -Value @'
---
name: react-code-generate
description: Use when generating React code.
---

# React JS

7. Translate API examples into a small client layer or existing data-fetching pattern:
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.agents/skills/react-code-generate/resources/api-integration-from-curl.md') -Encoding utf8 -Value @'
# API Integration From Curl

- Reuse the app's existing API client, fetch wrapper, query library, or server action pattern.
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
skill = "test-automation-validate"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/test-automation-validate/SKILL.md", ".agents/skills/test-automation-validate/resources", ".agents/skills/test-automation-validate/scripts/test-automation-validate-strategy.ps1"]
max_patch_lines = 40
max_files_per_patch = 3
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/test-automation-validate/scripts/test-automation-validate-strategy.ps1"]

[[evolution.profile]]
skill = "diagram-generate"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/diagram-generate/SKILL.md", ".agents/skills/diagram-generate/resources"]
max_patch_lines = 40
max_files_per_patch = 2
validation_commands = ["powershell -ExecutionPolicy Bypass -File scripts/test-resolve-output-file.ps1"]

[[evolution.profile]]
skill = "doc-write"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/doc-write/SKILL.md", ".agents/skills/doc-write/resources"]
max_patch_lines = 40
max_files_per_patch = 2
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/codex-structure-validate/scripts/validate-codex-structure.ps1 -Root ."]

[[evolution.profile]]
skill = "react-code-generate"
mode = "hybrid"
auto_apply = true
allowed_paths = [".agents/skills/react-code-generate/SKILL.md", ".agents/skills/react-code-generate/resources"]
max_patch_lines = 40
max_files_per_patch = 2
validation_commands = ["powershell -ExecutionPolicy Bypass -File .agents/skills/codex-structure-validate/scripts/validate-codex-structure.ps1 -Root ."]
'@
    Set-Content -LiteralPath (Join-Path $tempRoot '.codex/config.toml') -Encoding utf8 -Value @'
[skill_upgrade]
statePath = "audit/skill-upgrade-state"
'@

    $cases = @(
        @{ target = 'test-automation-validate'; evidence = 'missing-test-scope-selection-guard'; validation = 'test-automation-validate-strategy.ps1'; expectedCount = 3; paths = @('.agents/skills/test-automation-validate/SKILL.md', '.agents/skills/test-automation-validate/resources/framework-detection.md', '.agents/skills/test-automation-validate/scripts/test-automation-validate-strategy.ps1'); snippets = @('smallest useful level', 'smallest useful automated scope', 'smallest useful test scope selection') },
        @{ target = 'diagram-generate'; evidence = 'missing-diagram-type-selection-guard'; validation = 'test-resolve-output-file.ps1'; expectedCount = 2; paths = @('.agents/skills/diagram-generate/SKILL.md', '.agents/skills/diagram-generate/resources/plantuml-diagram-selection.md'); snippets = @('rejection reason for the loser', 'Reject a richer diagram') },
        @{ target = 'doc-write'; evidence = 'missing-protected-path-confirmation-reminder'; validation = 'validate-codex-structure.ps1'; expectedCount = 2; paths = @('.agents/skills/doc-write/SKILL.md', '.agents/skills/doc-write/resources/project-doc-output-catalog.md'); snippets = @('inline draft', 'confirmation is missing or ambiguous') },
        @{ target = 'react-code-generate'; evidence = 'missing-api-integration-routing'; validation = 'validate-codex-structure.ps1'; expectedCount = 2; paths = @('.agents/skills/react-code-generate/SKILL.md', '.agents/skills/react-code-generate/resources/api-integration-from-curl.md'); snippets = @('route curl, OpenAPI, and backend contract tasks', 'Decide the integration route first') }
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
      "missingNotes": "Repeated missing guard",
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
      "missingNotes": "Repeated missing guard",
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
      "missingNotes": "Repeated missing guard",
      "taskSummary": "Review target"
    }
  ]
}
"@

        & python $scriptPath --root $tempRoot --snapshot-file $snapshotPath --proposal-file $proposalPath | Out-Null
        Assert-Equal 0 $LASTEXITCODE "Writer should succeed for $($case.target)."
        $proposal = Get-Content -LiteralPath $proposalPath -Raw | ConvertFrom-Json
        Assert-Equal 'safe-auto-apply' $proposal.recommendation "$($case.target) should be safe-auto-apply for repeated evidence."
        Assert-Equal $case.expectedCount $proposal.updates.Count "$($case.target) should patch the expected number of files."
        for ($i = 0; $i -lt $case.expectedCount; $i++) {
            Assert-Equal $case.paths[$i] $proposal.updates[$i].path "$($case.target) should patch the expected file at index $i."
            Assert-True (($proposal.updates[$i].content | Out-String) -match [regex]::Escape($case.snippets[$i])) "$($case.target) update $i should contain the expected snippet."
        }
        Assert-True (($proposal.validationCommands -join "`n") -match [regex]::Escape($case.validation)) "$($case.target) should attach its policy validation command."
        $stateFiles = @(Get-ChildItem -LiteralPath (Join-Path $tempRoot 'audit/skill-upgrade-state') -Filter '*.jsonl' -File -ErrorAction SilentlyContinue)
        Assert-True ($stateFiles.Count -ge 1) 'Writer should create skill evolution state logs.'
    }

    $stateRows = @()
    foreach ($stateFile in $stateFiles) {
        $stateRows += @(Get-Content -LiteralPath $stateFile.FullName | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_ | ConvertFrom-Json })
    }
    Assert-Equal $cases.Count (@($stateRows | Where-Object { $_.phase -eq 'propose' -and $_.status -eq 'completed' -and $_.reason -eq 'proposal_generated' })).Count 'Writer should log one proposal_generated row per generated proposal.'

    Write-Output 'generate-execute evolution tests passed.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
