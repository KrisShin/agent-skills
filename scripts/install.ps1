# Pull this repo, then install the selected skills into %USERPROFILE%\.agents\skills.
#
# Local skills are copied (never symlinked). External plugins are NOT installed by
# this script: it prints the upstream repo link and the exact commands to run.
# Re-running is safe: each local destination is replaced wholesale.

$ErrorActionPreference = 'Stop'

$repoDir = Split-Path -Parent $PSScriptRoot
$dest    = Join-Path $env:USERPROFILE '.agents\skills'
$catalog = Join-Path $repoDir 'catalog.tsv'

# Host facts the "already installed?" checks need. Kept in one place so a change
# in profile naming is a one-line edit. The script never invokes dsh: external
# plugins are printed as instructions only.
if ($env:DSH_PROFILE) { $dshProfile = $env:DSH_PROFILE } else { $dshProfile = 'desktop' }

if (-not (Test-Path $catalog)) { throw "catalog.tsv not found at $catalog" }

if (Test-Path (Join-Path $repoDir '.git')) {
    # Only pull when a remote is configured; a fresh local repo has none, and
    # `git pull` would fail noisily with no tracking branch.
    $remote = git -C $repoDir remote 2>$null
    if ($remote) {
        # A dirty working tree is normal here: you edit a skill, then re-run the
        # installer to publish it. `pull --ff-only` refuses that, so warn and
        # carry on with the files on disk instead of aborting the install.
        Write-Host "Pulling $repoDir..."
        git -C $repoDir pull --ff-only 2>&1 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) {
            Write-Warning 'git pull failed (usually uncommitted changes); installing from the working tree instead.'
        }
    } else {
        Write-Host "No remote configured; installing from the working tree."
    }
}

# --- Load the catalog -------------------------------------------------------
$entries = @()
foreach ($line in Get-Content $catalog) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
    $parts = $trimmed -split '\|'
    if ($parts.Count -ne 6) { throw "catalog.tsv: expected 6 columns, got $($parts.Count): $trimmed" }
    $entries += [pscustomobject]@{
        Kind         = $parts[0]
        Name         = $parts[1]
        Source       = $parts[2]
        Spec         = $parts[3]
        VerifiedHost = $parts[4]
        Description  = $parts[5]
    }
}

# --- Detect what is already installed --------------------------------------
function Test-PluginInstalled([string]$name) {
    # Authoritative check: the package must be present in the profile's dependency
    # tree AND listed as a profile bundle, which is what actually loads it.
    $profileDir = Join-Path $env:USERPROFILE ".dsh\profiles\$dshProfile"
    $manifest = Join-Path $profileDir 'package.json'
    if (-not (Test-Path $manifest)) { return $false }
    if (-not (Test-Path (Join-Path $profileDir "node_modules\$name"))) { return $false }
    $doc = Get-Content $manifest -Raw | ConvertFrom-Json
    return ($doc.dsh.profile.bundles -contains $name)
}

$missingLocal = @()
$missingExternal = @()
$present = @()

foreach ($entry in $entries) {
    if ($entry.Kind -eq 'local') {
        if (Test-Path (Join-Path $dest "$($entry.Name)\SKILL.md")) { $present += $entry }
        else { $missingLocal += $entry }
    } elseif ($entry.Kind -eq 'external') {
        if (Test-PluginInstalled $entry.Name) { $present += $entry }
        else { $missingExternal += $entry }
    } else {
        throw "catalog.tsv: unknown kind '$($entry.Kind)' for $($entry.Name)"
    }
}

# --- Report -----------------------------------------------------------------
Write-Host ''
Write-Host 'Already installed (skipped):'
if ($present.Count -eq 0) {
    Write-Host '  (none)'
} else {
    foreach ($e in $present) { Write-Host "  - $($e.Name)" }
}
Write-Host ''

$candidates = @($missingLocal) + @($missingExternal)

# Validate caller-supplied names against the whole catalog first: a typo must be
# reported even when there is nothing left to install, or automation would treat
# a misspelled name as success.
if ($args.Count -gt 0) {
    $unknown = @()
    foreach ($a in $args) {
        foreach ($token in ($a -split '[,;\s]+' | Where-Object { $_ -ne '' })) {
            if ($token -match '^[0-9]+$') { continue }  # range-checked later
            if ($token -eq 'all') { continue }          # selects every missing entry
            if (-not ($entries | Where-Object { $_.Name -eq $token })) { $unknown += $token }
        }
    }
    if ($unknown.Count -gt 0) { throw "not in the catalog: $($unknown -join ', ')" }
}

if ($candidates.Count -eq 0) {
    Write-Host 'Everything in the catalog is already installed. Nothing to do.'
    exit 0
}

Write-Host 'Not installed yet:'
for ($i = 0; $i -lt $candidates.Count; $i++) {
    $e = $candidates[$i]
    $tag = if ($e.Kind -eq 'local') { 'local skill' } else { 'external plugin' }
    Write-Host ("  [{0}] {1} ({2}) - {3}" -f ($i + 1), $e.Name, $tag, $e.Description)
}
Write-Host ''

# Map a list of tokens (1-based numbers or skill names) onto $candidates.
# Only not-yet-installed entries are selectable, so a name that is already
# installed reports that instead of reinstalling it silently.
function Resolve-Selection([string[]]$tokens) {
    $picked = @()
    foreach ($token in $tokens) {
        if ($token -match '^[0-9]+$') {
            $index = [int]$token
            if ($index -lt 1 -or $index -gt $candidates.Count) {
                throw "out of range: $index (1-$($candidates.Count))"
            }
            $picked += $candidates[$index - 1]
            continue
        }
        $match = $candidates | Where-Object { $_.Name -eq $token }
        if ($match) {
            $picked += $match
        } elseif ($present | Where-Object { $_.Name -eq $token }) {
            Write-Host "already installed, skipping: $token"
        } else {
            throw "not in the catalog: $token"
        }
    }
    # Dedupe by Name. `Select-Object -Unique` compares whole objects and collapses
    # distinct catalog entries, so it cannot be used here.
    $seen = @{}
    $unique = @()
    foreach ($item in $picked) {
        if (-not $seen.ContainsKey($item.Name)) {
            $seen[$item.Name] = $true
            $unique += $item
        }
    }
    Write-Output -NoEnumerate $unique
}

# --- Ask --------------------------------------------------------------------
# Selection precedence: values supplied on the command line win, so the script is
# usable from automation and from the message this installer prints. Otherwise
# read one line from stdin, which may be a real terminal *or* a pipe.
$selected = @()
if ($args.Count -gt 0) {
    $tokens = @()
    foreach ($a in $args) { $tokens += ($a -split '[,;\s]+' | Where-Object { $_ -ne '' }) }
    if ($tokens.Count -eq 1 -and $tokens[0].ToLowerInvariant() -eq 'all') {
        $selected = $candidates
    } else {
        $selected = Resolve-Selection $tokens
    }
} else {
    $answer = ''
    try { $answer = Read-Host 'Install which? Enter numbers (e.g. 1,3), "all", or press Enter to cancel' } catch { $answer = '' }
    if ([string]::IsNullOrWhiteSpace($answer)) {
        Write-Host 'Cancelled; nothing was installed.'
        exit 0
    }
    if ($answer.Trim().ToLowerInvariant() -eq 'all') {
        $selected = $candidates
    } else {
        $selected = Resolve-Selection ($answer -split '[,;\s]+' | Where-Object { $_ -ne '' })
    }
}
if ($selected.Count -eq 0) { Write-Host 'Nothing selected.'; exit 0 }

# --- Install local skills ---------------------------------------------------
$installedLocal = @($selected | Where-Object { $_.Kind -eq 'local' })
if ($installedLocal.Count -gt 0) {
    New-Item -ItemType Directory -Force $dest | Out-Null
    foreach ($entry in $installedLocal) {
        $source = Join-Path $repoDir $entry.Source
        if (-not (Test-Path $source)) { Write-Warning "skip $($entry.Name): not in this repo"; continue }
        $target = Join-Path $dest $entry.Name
        # Copy, not symlink: dsh-ops refuses to traverse reparse points, and /ship
        # reads references/ at Stages 5 and 6.
        if (Test-Path $target) { Remove-Item $target -Recurse -Force }
        Copy-Item -Recurse -Force $source $target
        Write-Host "installed $($entry.Name)"
    }
}

# --- Print external instructions, never run them ----------------------------
$chosenExternal = @($selected | Where-Object { $_.Kind -eq 'external' })
if ($chosenExternal.Count -gt 0) {
    Write-Host ''
    Write-Host 'External plugins are not installed by this script. Run these yourself:'
    foreach ($entry in $chosenExternal) {
        Write-Host ''
        Write-Host "  $($entry.Name)  ($($entry.Source))"
        Write-Host "  verified against DSH $($entry.VerifiedHost)"
        Write-Host "    dsh plugin --profile $dshProfile add $($entry.Spec)"
        Write-Host '  Quit DeepSeek Harness before installing, then start it again.'
        Write-Host '  If the host reports an incompatible version, the gate is on the'
        Write-Host '  package peer range; grant it explicitly with:'
        Write-Host "    dsh plugin --profile $dshProfile allow-version $($entry.Spec) --dsh-version <host-version> --accept-risk"
    }
    Write-Host ''
}

Write-Host 'Done. Skills are re-read on the next session.'
