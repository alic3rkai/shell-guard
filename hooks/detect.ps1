# Shell Guard: tell Claude what the USER's terminal can really run.
# Claude's own process PATH can differ from what a fresh user terminal gets,
# so read PATH from the registry (what a new terminal inherits), not $env:Path.
# ponytail: Windows only; macOS/Linux version would read the login shell instead.

$dirs = @(
    [Environment]::GetEnvironmentVariable('Path', 'Machine'),
    [Environment]::GetEnvironmentVariable('Path', 'User')
) -join ';' -split ';' |
    Where-Object { $_ } |
    ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).Trim().Trim('"').TrimEnd('\') } |
    Where-Object { $_ -and $_.IndexOfAny([IO.Path]::GetInvalidPathChars()) -lt 0 } |
    Select-Object -Unique

function Find-Tool($name) {
    foreach ($d in $dirs) {
        foreach ($ext in '.exe', '.cmd') {
            $p = Join-Path $d "$name$ext"
            if (Test-Path -LiteralPath $p) { return $p }
        }
    }
    return $null
}

$lines = @()
$lines += "Shell Guard: the user's own terminal (not yours) as a fresh window would see it."
$lines += "Default shell: Windows PowerShell $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor). No '&&' or '||'; use 'A; if (`$?) { B }'."

$pwsh = Find-Tool 'pwsh'
if ($pwsh) { $lines += "PowerShell 7 is installed ($pwsh), but do not assume the user opens it." }

foreach ($t in 'python', 'py', 'node', 'npm', 'git') {
    $p = Find-Tool $t
    if (-not $p) {
        $lines += "${t}: NOT on the user's PATH."
    } elseif ($p -like '*\WindowsApps\*') {
        $lines += "${t}: only the Microsoft Store stub ($p); it opens the Store instead of running."
    } else {
        $lines += "${t}: $p"
    }
}

# Real Python installs that are off PATH, so commands can use the full path.
$installed = Get-ChildItem "$env:LOCALAPPDATA\Programs\Python\*\python.exe", "$env:ProgramFiles\Python*\python.exe" -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
if ($installed) { $lines += "Python installs found: $($installed -join ', ')" }

$lines += "Rule: commands you give the user must run in this shell. If a tool is not on PATH, use & `"full\path.exe`" or tell them how to add it."
$lines -join "`n"
