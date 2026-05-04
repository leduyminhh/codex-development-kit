param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
    [Parameter(Mandatory = $true)]
    [string]$SnapshotFile,
    [Parameter(Mandatory = $true)]
    [string]$ProposalFile,
    [string[]]$ValidationCommands = @()
)

$ErrorActionPreference = 'Stop'

. (Join-Path $Root 'scripts/lib/codex-config.ps1')

function Write-SkillUpgradeState {
    param(
        [string]$RootPath,
        [string]$StatePath,
        [string]$TargetAgent,
        [string]$ProposalPath,
        [int]$FeedbackCount,
        [string]$Recommendation,
        [string]$ApprovalStatus
    )

    $stateRoot = Join-Path $RootPath ($(if ([string]::IsNullOrWhiteSpace($StatePath)) { 'audit/skill-upgrade-state' } else { $StatePath }))
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    $timeZone = Get-CodexHoChiMinhTimeZone
    $now = [TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $timeZone)
    $logFile = Join-Path $stateRoot ($now.ToString('yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture) + '_skill-upgrade-state.jsonl')
    $record = [ordered]@{
        schema         = 'codex.skill-upgrade.state.v1'
        timestamp      = $now.ToString('yyyy-MM-ddTHH:mm:sszzz', [Globalization.CultureInfo]::InvariantCulture)
        phase          = 'propose'
        status         = 'completed'
        reason         = 'proposal_generated'
        targetAgent    = $TargetAgent
        proposalFile   = $ProposalPath
        feedbackCount  = $FeedbackCount
        recommendation = $Recommendation
        approvalStatus = $ApprovalStatus
    }
    Add-Content -LiteralPath $logFile -Value ($record | ConvertTo-Json -Compress -Depth 5) -Encoding utf8
}

$snapshot = Get-Content -LiteralPath $SnapshotFile -Raw | ConvertFrom-Json
$feedbackEntries = @($snapshot.feedbackEntries)
$configPath = Join-Path $Root '.codex/config.toml'
$configText = if (Test-Path -LiteralPath $configPath) {
    Get-Content -LiteralPath $configPath -Raw
} else {
    ''
}
$configuredStatePath = Get-CodexTomlStringValue -TomlText $configText -Section 'skill_upgrade' -Key 'statePath'
if ([string]::IsNullOrWhiteSpace($configuredStatePath)) {
    $configuredStatePath = 'audit/skill-upgrade-state'
}

$correctNotes = @($feedbackEntries | ForEach-Object { $_.correctNotes } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
$wrongNotes = @($feedbackEntries | ForEach-Object { $_.wrongNotes } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
$missingNotes = @($feedbackEntries | ForEach-Object { $_.missingNotes } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

$proposedChanges = New-Object System.Collections.Generic.List[string]
foreach ($note in $wrongNotes) {
    $proposedChanges.Add("Tighten or replace guidance related to: $note")
}
foreach ($note in $missingNotes) {
    $proposedChanges.Add("Add missing guidance for: $note")
}
if ($proposedChanges.Count -eq 0 -and $correctNotes.Count -gt 0) {
    $proposedChanges.Add('Preserve current guidance and review for overfitting before changing the skill.')
}

$proposal = [ordered]@{
    createdAt          = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
    targetAgent        = $snapshot.targetAgent
    targetSkills       = @($snapshot.targetSkills)
    feedbackCount      = @($feedbackEntries).Count
    observedPatterns   = @(
        "correct_notes=$($correctNotes.Count)"
        "wrong_notes=$($wrongNotes.Count)"
        "missing_notes=$($missingNotes.Count)"
    )
    correctGuidance    = $correctNotes
    incorrectGuidance  = $wrongNotes
    missingGuidance    = $missingNotes
    proposedChanges    = $proposedChanges.ToArray()
    validationCommands = @($ValidationCommands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    approvalStatus     = 'pending'
    updates            = @()
}

$proposalJson = $proposal | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($ProposalFile, $proposalJson, (New-Object System.Text.UTF8Encoding($false)))
Write-SkillUpgradeState `
    -RootPath $Root `
    -StatePath $configuredStatePath `
    -TargetAgent ([string]$snapshot.targetName) `
    -ProposalPath $ProposalFile `
    -FeedbackCount @($feedbackEntries).Count `
    -Recommendation 'manual-review' `
    -ApprovalStatus 'pending'

Write-Output $ProposalFile
