param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
    [Parameter(Mandatory = $true)]
    [string]$AgentName,
    [string[]]$SkillNames = @(),
    [ValidateSet('skill', 'agent')]
    [string]$TargetType = 'skill',
    [string]$TargetName = '',
    [ValidateSet('correct', 'wrong', 'mixed')]
    [string]$Outcome = 'mixed',
    [ValidateSet('low', 'medium', 'high')]
    [string]$Severity = 'medium',
    [switch]$Reproducible,
    [string]$EvidenceKey = '',
    [Parameter(Mandatory = $true)]
    [string]$TaskSummary,
    [string]$CorrectNotes = '',
    [string]$WrongNotes = '',
    [string]$MissingNotes = ''
)

$ErrorActionPreference = 'Stop'

. (Join-Path $Root 'scripts/lib/codex-config.ps1')

function Write-SkillUpgradeState {
    param(
        [string]$RootPath,
        [string]$StatePath,
        [string]$Reason,
        [string]$AgentName,
        [string]$TargetAgent,
        [string]$FeedbackFile,
        [string[]]$SkillNames,
        [string]$Outcome,
        [string]$Severity
    )

    $stateRoot = Join-Path $RootPath ($(if ([string]::IsNullOrWhiteSpace($StatePath)) { 'audit/skill-upgrade-state' } else { $StatePath }))
    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    $timeZone = Get-CodexHoChiMinhTimeZone
    $now = [TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $timeZone)
    $logFile = Join-Path $stateRoot ($now.ToString('yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture) + '_skill-upgrade-state.jsonl')
    $record = [ordered]@{
        schema       = 'codex.skill-upgrade.state.v1'
        timestamp    = $now.ToString('yyyy-MM-ddTHH:mm:sszzz', [Globalization.CultureInfo]::InvariantCulture)
        phase        = 'capture'
        status       = 'completed'
        reason       = $Reason
        agentName    = $AgentName
        targetAgent  = $TargetAgent
        feedbackFile = $FeedbackFile
        skillNames   = @($SkillNames)
        outcome      = $Outcome
        severity     = $Severity
    }
    Add-Content -LiteralPath $logFile -Value ($record | ConvertTo-Json -Compress -Depth 5) -Encoding utf8
}

if (
    [string]::IsNullOrWhiteSpace($CorrectNotes) -and
    [string]::IsNullOrWhiteSpace($WrongNotes) -and
    [string]::IsNullOrWhiteSpace($MissingNotes)
) {
    throw 'At least one of CorrectNotes, WrongNotes, or MissingNotes is required.'
}

$configPath = Join-Path $Root '.codex/config.toml'
$configText = if (Test-Path -LiteralPath $configPath) {
    Get-Content -LiteralPath $configPath -Raw
} else {
    ''
}

$configuredFeedbackPath = Get-CodexTomlStringValue -TomlText $configText -Section 'skill_upgrade' -Key 'feedbackPath'
if ([string]::IsNullOrWhiteSpace($configuredFeedbackPath)) {
    $configuredFeedbackPath = 'audit/skill-feedback'
}
$configuredStatePath = Get-CodexTomlStringValue -TomlText $configText -Section 'skill_upgrade' -Key 'statePath'
if ([string]::IsNullOrWhiteSpace($configuredStatePath)) {
    $configuredStatePath = 'audit/skill-upgrade-state'
}

$feedbackRoot = Join-Path $Root $configuredFeedbackPath
New-Item -ItemType Directory -Path $feedbackRoot -Force | Out-Null

$timeZone = Get-CodexHoChiMinhTimeZone
$now = [TimeZoneInfo]::ConvertTime([DateTimeOffset]::UtcNow, $timeZone)
$feedbackFile = Join-Path $feedbackRoot ($now.ToString('yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture) + '_skill-feedback.jsonl')
$resolvedTargetName = if ([string]::IsNullOrWhiteSpace($TargetName)) { $AgentName } else { $TargetName }

$entry = [ordered]@{
    timestamp    = $now.ToString('yyyy-MM-ddTHH:mm:sszzz', [Globalization.CultureInfo]::InvariantCulture)
    agentName    = $AgentName
    skillNames   = @($SkillNames | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    targetType   = $TargetType
    targetName   = $resolvedTargetName
    outcome      = $Outcome
    severity     = $Severity
    reproducible = [bool]$Reproducible
    evidenceKey  = $EvidenceKey
    taskSummary  = $TaskSummary
    correctNotes = $CorrectNotes
    wrongNotes   = $WrongNotes
    missingNotes = $MissingNotes
}

$json = $entry | ConvertTo-Json -Compress -Depth 4
Add-Content -LiteralPath $feedbackFile -Value $json -Encoding utf8
Write-SkillUpgradeState `
    -RootPath $Root `
    -StatePath $configuredStatePath `
    -Reason 'feedback_added' `
    -AgentName $AgentName `
    -TargetAgent $resolvedTargetName `
    -FeedbackFile $feedbackFile `
    -SkillNames @($entry.skillNames) `
    -Outcome $Outcome `
    -Severity $Severity

Write-Output $feedbackFile
