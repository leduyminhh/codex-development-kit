param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$skillsRoot = Join-Path $Root ("scripts/tmp-skills-root-" + [guid]::NewGuid().ToString('N'))

try {
    $output = & (Join-Path $Root 'scripts/install-skill-link.ps1') `
        -SourceRoot $Root `
        -SkillsRoot $skillsRoot `
        -LinkName 'codex-workflow-kit' `
        -Force `
        -WhatIf

    $linkPath = Join-Path $skillsRoot 'codex-workflow-kit'
    Assert-True ($output -contains "WhatIf: ensure skills root $skillsRoot") 'WhatIf output did not mention skills root.'
    Assert-True ($output -contains "WhatIf: link $linkPath -> $(Join-Path $Root '.agents/skills')") 'WhatIf output did not mention expected link target.'
    Assert-True (Test-Path -LiteralPath (Join-Path $Root '.agents/skills/java-architect/SKILL.md')) 'Source java-architect skill is missing.'
    Assert-True (Test-Path -LiteralPath (Join-Path $Root '.agents/skills/react-js/SKILL.md')) 'Source react-js skill is missing.'
    Assert-True (Test-Path -LiteralPath (Join-Path $Root '.agents/skills/qa-reviewer/SKILL.md')) 'Source qa-reviewer skill is missing.'
    Assert-True (Test-Path -LiteralPath (Join-Path $Root '.agents/skills/automation-testing/SKILL.md')) 'Source automation-testing skill is missing.'
    Assert-True (Test-Path -LiteralPath (Join-Path $Root '.agents/skills/design-pattern/SKILL.md')) 'Source design-pattern skill is missing.'

    Write-Output 'install-skill-link tests passed'
} finally {
    if (Test-Path -LiteralPath $skillsRoot) {
        try {
            $linkPath = Join-Path $skillsRoot 'codex-workflow-kit'
            if (Test-Path -LiteralPath $linkPath) {
                cmd /c rmdir "$linkPath" | Out-Null
            }
            Remove-Item -LiteralPath $skillsRoot -Recurse -Force
        } catch {
            Write-Warning "Could not remove temporary skills root ${skillsRoot}: $($_.Exception.Message)"
        }
    }
}

