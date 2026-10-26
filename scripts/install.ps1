# Pull this repo, then copy the skills into %USERPROFILE%\.agents\skills.
# Re-running is safe: each destination is replaced wholesale.
$ErrorActionPreference = 'Stop'

$skills  = @('ship', 'grilling', 'tdd', 'diagnosing-bugs')
$repoDir = Split-Path -Parent $PSScriptRoot
$dest    = Join-Path $env:USERPROFILE '.agents\skills'

if (Test-Path (Join-Path $repoDir '.git')) {
    # Only pull when a remote is configured; a fresh local repo has none, and
    # `git pull` would fail noisily with no tracking branch.
    $remote = git -C $repoDir remote 2>$null
    if ($remote) {
        Write-Host "Pulling $repoDir..."
        git -C $repoDir pull --ff-only
        if ($LASTEXITCODE -ne 0) { throw "git pull failed; skills were not updated." }
    } else {
        Write-Host "No remote configured; installing from the working tree."
    }
}

New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($name in $skills) {
    $source = Join-Path $repoDir $name
    if (-not (Test-Path $source)) {
        Write-Warning "skip ${name}: not in this repo"
        continue
    }
    $target = Join-Path $dest $name
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    Copy-Item -Recurse -Force $source $target
    Write-Host "installed $name"
}

Write-Host 'Done. Skills are re-read on the next session.'
