param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [string]$AuditRoot,
    [string]$SessionId,
    [string]$AgentName,
    [string]$Model,
    [string]$Reasoning,
    [string]$SummaryJob,
    [string]$StartAt,
    [string]$EndAt,
    [ValidateSet('started', 'completed', 'failed', 'cancelled', 'skipped')]
    [string]$Status = 'completed',
    [decimal]$Cost = 0,
    [int]$RemainingDays = -1
)

$ErrorActionPreference = 'Stop'

function Get-ConfigValue {
    param([string]$ConfigText, [string]$Section, [string]$Key)

    $sectionPattern = "(?ms)^\[$([regex]::Escape($Section))\]\s*(.*?)(?=^\[|\z)"
    $sectionMatch = [regex]::Match($ConfigText, $sectionPattern)
    if (-not $sectionMatch.Success) { return $null }

    $keyPattern = "(?m)^\s*$([regex]::Escape($Key))\s*=\s*(.+?)\s*$"
    $keyMatch = [regex]::Match($sectionMatch.Groups[1].Value, $keyPattern)
    if (-not $keyMatch.Success) { return $null }

    return $keyMatch.Groups[1].Value.Trim().Trim('"')
}

function Get-HoChiMinhTimeZone {
    try {
        return [TimeZoneInfo]::FindSystemTimeZoneById('SE Asia Standard Time')
    } catch {
        return [TimeZoneInfo]::CreateCustomTimeZone('Asia/Ho_Chi_Minh', [TimeSpan]::FromHours(7), 'Asia/Ho_Chi_Minh', 'Asia/Ho_Chi_Minh')
    }
}

function Convert-ToUtcDateTimeOffset {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [DateTimeOffset]::UtcNow
    }

    $parsed = [DateTimeOffset]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture)
    return $parsed.ToUniversalTime()
}

function Format-UtcInstant {
    param([DateTimeOffset]$Value)
    return $Value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss'Z'", [Globalization.CultureInfo]::InvariantCulture)
}

function Format-LocalInstant {
    param([DateTimeOffset]$Value, [TimeZoneInfo]$TimeZone)
    $local = [TimeZoneInfo]::ConvertTime($Value, $TimeZone)
    return $local.ToString('yyyy-MM-ddTHH:mm:sszzz', [Globalization.CultureInfo]::InvariantCulture)
}

$configPath = Join-Path $Root '.codex/config.toml'
$configText = ''
if (Test-Path -LiteralPath $configPath) {
    $configText = Get-Content -LiteralPath $configPath -Raw
}

if ([string]::IsNullOrWhiteSpace($AuditRoot)) {
    $configuredRoot = Get-ConfigValue -ConfigText $configText -Section 'audit.agent' -Key 'path'
    if ([string]::IsNullOrWhiteSpace($configuredRoot)) {
        $configuredRoot = 'audit/agent'
    }
    $AuditRoot = Join-Path $Root $configuredRoot
}

if ($RemainingDays -lt 0) {
    $configuredRemainingDays = Get-ConfigValue -ConfigText $configText -Section 'audit.agent' -Key 'remainingDays'
    if ([string]::IsNullOrWhiteSpace($configuredRemainingDays)) {
        $RemainingDays = 30
    } else {
        $RemainingDays = [int]$configuredRemainingDays
    }
}

if ([string]::IsNullOrWhiteSpace($SessionId)) {
    $SessionId = [guid]::NewGuid().ToString()
}

$startUtc = Convert-ToUtcDateTimeOffset -Value $StartAt
$endUtc = if ([string]::IsNullOrWhiteSpace($EndAt)) { $startUtc } else { Convert-ToUtcDateTimeOffset -Value $EndAt }
$timeZone = Get-HoChiMinhTimeZone

New-Item -ItemType Directory -Path $AuditRoot -Force | Out-Null

if ($RemainingDays -gt 0) {
    $cutoff = (Get-Date).ToUniversalTime().AddDays(-$RemainingDays)
    Get-ChildItem -LiteralPath $AuditRoot -Filter '*_action.csv' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTimeUtc -lt $cutoff } |
        Remove-Item -Force
}

$localStart = [TimeZoneInfo]::ConvertTime($startUtc, $timeZone)
$auditFile = Join-Path $AuditRoot ($localStart.ToString('yyMMdd', [Globalization.CultureInfo]::InvariantCulture) + '_action.csv')
$row = [pscustomobject]@{
    sessionId  = $SessionId
    agentName  = $AgentName
    model      = $Model
    reasoning  = $Reasoning
    summaryJob = $SummaryJob
    startTime  = Format-LocalInstant -Value $startUtc -TimeZone $timeZone
    endTime    = Format-LocalInstant -Value $endUtc -TimeZone $timeZone
    startAt    = Format-UtcInstant -Value $startUtc
    endAt      = Format-UtcInstant -Value $endUtc
    status     = $Status
    cost       = $Cost.ToString([Globalization.CultureInfo]::InvariantCulture)
}

if (Test-Path -LiteralPath $auditFile) {
    $row | Export-Csv -LiteralPath $auditFile -NoTypeInformation -Append
} else {
    $row | Export-Csv -LiteralPath $auditFile -NoTypeInformation
}

Write-Output $auditFile
