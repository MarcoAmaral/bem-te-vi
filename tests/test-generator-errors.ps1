# test-generator-errors.ps1 - generate-adapters.ps1 refuses a source tree it would turn into broken
# adapters, and says why (plan 054).
#
# PowerShell counterpart to tests/test-generator-errors.sh, reading the same
# tests/fixtures/generator-errors.txt, so the two generators are held to the same words: each case
# is planted in a scratch tree, a copy of generate-adapters.ps1 runs there, and every error line it
# prints is compared with the file. tests/verify-adapters.ps1 runs this script. Kept ASCII-only on
# purpose.

$ErrorActionPreference = 'Stop'

$RepoDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Cases = Join-Path $RepoDir 'tests/fixtures/generator-errors.txt'
$Generator = Join-Path $RepoDir 'generate-adapters.ps1'
$Shell = (Get-Process -Id $PID).Path
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("generator-errors-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null

$script:Failed = $false
$script:Count = 0

# A small Markdown file, with that id in its frontmatter if one is given.
function Add-Plant {
    param([string]$Tree, [string]$Rel, [string]$Id)
    $path = Join-Path $Tree $Rel
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $text = "---`n"
    if ($Id) { $text += "id: $Id`n" }
    $text += "description: `"Planted by tests/test-generator-errors (plan 054).`"`n---`n# $(Split-Path -Leaf $path)`n"
    [System.IO.File]::WriteAllText($path, $text, $Utf8NoBom)
}

function Invoke-Case {
    param([string]$Name, [string[]]$Plants, [string[]]$Expected)
    $script:Count++
    $tree = Join-Path $Tmp $Name
    New-Item -ItemType Directory -Path $tree -Force | Out-Null
    Copy-Item -LiteralPath $Generator -Destination $tree
    foreach ($plant in $Plants) {
        $parts = @($plant -split ' ')
        $id = if ($parts.Count -gt 1) { $parts[1] } else { '' }
        Add-Plant $tree $parts[0] $id
    }
    $ErrorActionPreference = 'Continue'
    $out = @(& $Shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $tree 'generate-adapters.ps1') -NoColor 2>&1 |
        ForEach-Object { "$_".TrimEnd([char]13) })
    $rc = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $got = @($out | Where-Object { $_.StartsWith('[ERR]', [System.StringComparison]::Ordinal) })
    $bad = $false
    if ($Expected.Count -eq 0) {
        if ($rc -ne 0 -or $got.Count -ne 0) {
            Write-Host "  X ${Name}: expected a clean run, got exit $rc"
            $out | ForEach-Object { Write-Host "      | $_" }
            $bad = $true
        }
        elseif (-not (Test-Path -LiteralPath (Join-Path $tree 'adapters/skills/qa/SKILL.md')) -or
                -not (Test-Path -LiteralPath (Join-Path $tree 'adapters/skills/qa-plan/SKILL.md'))) {
            Write-Host "  X ${Name}: the skills qa and qa-plan were not generated"
            $bad = $true
        }
    }
    else {
        if ($rc -eq 0) { Write-Host "  X ${Name}: expected a non-zero exit, got 0"; $bad = $true }
        if (($got -join "`n") -cne ($Expected -join "`n")) {
            Write-Host "  X ${Name}: error lines differ from tests/fixtures/generator-errors.txt"
            Write-Host '      expected:'; $Expected | ForEach-Object { Write-Host "      | $_" }
            Write-Host '      got:'
            if ($got.Count -eq 0) { Write-Host '      | (none)' } else { $got | ForEach-Object { Write-Host "      | $_" } }
            $bad = $true
        }
        if (Test-Path -LiteralPath (Join-Path $tree 'adapters')) {
            Write-Host "  X ${Name}: adapters/ was written although the generator refused the tree"
            $bad = $true
        }
    }
    if ($bad) { $script:Failed = $true } else { Write-Host "  OK $Name" }
}

try {
    $base = @(); $name = $null; $plants = @(); $errs = @()
    foreach ($raw in [System.IO.File]::ReadAllLines($Cases, $Utf8NoBom)) {
        $line = $raw.TrimEnd([char]13)
        if ($line -eq '' -or $line.StartsWith('#')) { continue }
        if ($line.StartsWith('== ')) {
            if ($null -ne $name) { Invoke-Case $name ($base + $plants) $errs }
            $name = $line.Substring(3); $plants = @(); $errs = @()
        }
        elseif ($line.StartsWith('plant ')) {
            if ($null -eq $name) { $base += $line.Substring(6) } else { $plants += $line.Substring(6) }
        }
        elseif ($line.StartsWith('[ERR]')) { $errs += $line }
        else { Write-Host "  X unreadable line in ${Cases}: $line"; $script:Failed = $true }
    }
    if ($null -ne $name) { Invoke-Case $name ($base + $plants) $errs }
}
finally {
    Remove-Item -LiteralPath $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:Failed) {
    Write-Host 'Generator error check failed.'
    exit 1
}
Write-Host "OK generate-adapters.ps1 handled all $($script:Count) planted trees as tests/fixtures/generator-errors.txt says."
exit 0
