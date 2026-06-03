<#
.SYNOPSIS
  login-sync.ps1 — Windows port of login-sync.sh.
  Run at logon by the AvalonLotus-LoginSync Scheduled Task.

.DESCRIPTION
  1. Pulls the latest AvalonLotus Mac-Setup repo (the bootstrap definition).
  2. ONLY if the repo changed, re-runs install.ps1 so new tools / setups apply.
  3. If nothing changed, does nothing expensive.

  Idempotent. Installed/refreshed by install.ps1.
  Log: %USERPROFILE%\.local\state\git-autosync\login-sync.log

.NOTES
  Locates the repo via $PSScriptRoot (this script lives in the repo root), so it
  works regardless of where the repo was cloned. Verify on a real Windows box.
#>
$ErrorActionPreference = 'Continue'
$repo   = $PSScriptRoot
$logDir = Join-Path $HOME '.local\state\git-autosync'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'login-sync.log'
function Log($m) { "$([DateTime]::Now.ToString('u')) login-sync: $m" | Out-File -Append -Encoding utf8 $log }

if (-not (Test-Path (Join-Path $repo '.git'))) { Log 'no Mac-Setup repo, skip'; exit 0 }
Set-Location $repo

if (git status --porcelain) { Log 'repo dirty, skip'; exit 0 }

$before = (git rev-parse HEAD)
git pull --rebase --autostash *>> $log
$after  = (git rev-parse HEAD)

if ($before -eq $after) { Log "up to date ($after), nothing to apply"; exit 0 }

Log "updated $before -> $after, verifying signatures"

# Trust gate (model B): only run install.ps1 if every new commit is signed by a
# trusted key in allowed_signers. Fail safe — any non-'G' status blocks it.
$untrusted = git log --format='%H %G?' "$before..$after" | Where-Object { ($_ -split ' ')[1] -ne 'G' }
if ($untrusted) {
    Log "UNTRUSTED/unsigned commit(s) — NOT running install.ps1:"
    $untrusted | ForEach-Object { Log "    $_" }
    Log "content pulled, bootstrap NOT applied. Investigate before trusting."
    exit 0
}

Log "signatures trusted, running install.ps1"
powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'install.ps1') *>> $log
Log 'install.ps1 finished'
