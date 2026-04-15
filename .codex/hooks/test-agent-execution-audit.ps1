param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path)

$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param([object]$Expected, [object]$Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message Expected=[$Expected] Actual=[$Actual]"
    }
}

$script = Join-Path $Root '.codex/hooks/agent-execution-audit.ps1'
$auditRoot = Join-Path $Root '.codex/hooks'

Get-ChildItem -LiteralPath $auditRoot -Filter '*_action.csv' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

& $script `
    -AuditRoot $auditRoot `
    -SessionId '11111111-1111-1111-1111-111111111111' `
    -AgentName 'java-architect' `
    -Model 'gpt-5.4' `
    -Reasoning 'high' `
    -SummaryJob 'Review payment flow' `
    -StartAt '2026-04-15T00:00:00Z' `
    -EndAt '2026-04-15T00:05:00Z' `
    -Status 'completed' `
    -Cost 1.25 `
    -RemainingDays 7

$expectedFile = Join-Path $auditRoot '260415_action.csv'
Assert-True (Test-Path -LiteralPath $expectedFile) 'Audit file was not created using yyMMdd_action.csv.'

$rows = @(Import-Csv -LiteralPath $expectedFile)
Assert-Equal 1 $rows.Count 'Audit file should contain exactly one row.'
Assert-Equal '11111111-1111-1111-1111-111111111111' $rows[0].sessionId 'Session ID mismatch.'
Assert-Equal 'java-architect' $rows[0].agentName 'Agent name mismatch.'
Assert-Equal 'gpt-5.4' $rows[0].model 'Model mismatch.'
Assert-Equal 'high' $rows[0].reasoning 'Reasoning mismatch.'
Assert-Equal 'Review payment flow' $rows[0].summaryJob 'Summary job mismatch.'
Assert-Equal '2026-04-15T07:00:00+07:00' $rows[0].startTime 'startTime should be Asia/Ho_Chi_Minh time.'
Assert-Equal '2026-04-15T07:05:00+07:00' $rows[0].endTime 'endTime should be Asia/Ho_Chi_Minh time.'
Assert-Equal '2026-04-15T00:00:00Z' $rows[0].startAt 'startAt should remain UTC.'
Assert-Equal '2026-04-15T00:05:00Z' $rows[0].endAt 'endAt should remain UTC.'
Assert-Equal 'completed' $rows[0].status 'Status mismatch.'
Assert-Equal '1.25' $rows[0].cost 'Cost mismatch.'

& $script `
    -AuditRoot $auditRoot `
    -AgentName 'react-js' `
    -Model 'gpt-5.4' `
    -Reasoning 'medium' `
    -SummaryJob 'Build checkout UI' `
    -StartAt '2026-04-16T01:00:00Z' `
    -Status 'started' `
    -RemainingDays 7

$secondFile = Join-Path $auditRoot '260416_action.csv'
$secondRows = @(Import-Csv -LiteralPath $secondFile)
Assert-True ([guid]::TryParse($secondRows[0].sessionId, [ref]([guid]::Empty))) 'Missing sessionId should generate a UUID.'
Assert-Equal '0' $secondRows[0].cost 'Missing cost should default to 0.'

& $script `
    -AuditRoot $auditRoot `
    -SessionId '22222222-2222-2222-2222-222222222222' `
    -AgentName 'design-pattern' `
    -Model 'gpt-5.4' `
    -Reasoning 'high' `
    -SummaryJob 'Verify local date file naming' `
    -StartAt '2026-04-14T18:00:00Z' `
    -Status 'completed' `
    -RemainingDays 7

$localDateFile = Join-Path $auditRoot '260415_action.csv'
$localDateRows = @(Import-Csv -LiteralPath $localDateFile)
Assert-True ($localDateRows.sessionId -contains '22222222-2222-2222-2222-222222222222') 'Audit filename should use Asia/Ho_Chi_Minh local date, not UTC date.'

$oldFile = Join-Path $auditRoot '260101_action.csv'
New-Item -ItemType File -Path $oldFile -Force | Out-Null
(Get-Item -LiteralPath $oldFile).LastWriteTimeUtc = (Get-Date).ToUniversalTime().AddDays(-10)

& $script `
    -AuditRoot $auditRoot `
    -AgentName 'qa-reviewer' `
    -Model 'gpt-5.4' `
    -Reasoning 'low' `
    -SummaryJob 'Cleanup old audit files' `
    -StartAt '2026-04-17T01:00:00Z' `
    -Status 'completed' `
    -RemainingDays 7

Assert-True (-not (Test-Path -LiteralPath $oldFile)) 'Old audit file should be deleted after remainingDays.'

Get-ChildItem -LiteralPath $auditRoot -Filter '*_action.csv' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

Write-Output 'agent-execution-audit tests passed'

