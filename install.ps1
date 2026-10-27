# Windows installer for these dotfiles: psmux, NvChad, oh-my-posh (atomic).
#
#   irm https://raw.githubusercontent.com/WillJackson99/dotfiles/main/install.ps1 | iex
#
# or, with options:
#
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/WillJackson99/dotfiles/main/install.ps1))) -SkipFont
#
# Safe to re-run: it pulls the latest repo, skips installed packages and backs
# up any existing config it replaces (<name>.bak-<timestamp>).
# Keep this file ASCII-only - Windows PowerShell 5.1 misreads UTF-8 scripts.

[CmdletBinding()]
param(
    [switch]$SkipPackages,
    [switch]$SkipFont,
    [switch]$SkipPlugins,
    [string]$RepoUrl = 'https://github.com/WillJackson99/dotfiles.git',
    [string]$CloneDir = (Join-Path $HOME 'dotfiles')
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$fontFace = 'FiraCode Nerd Font'

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Info($msg) { Write-Host "    $msg" }
function Warn($msg) { Write-Host "    ! $msg" -ForegroundColor Yellow }

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Test-Command($name) {
    [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Install-WingetPackage($id) {
    winget list --id $id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) { Info "$id already installed"; return }
    Info "installing $id"
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Warn "winget could not install $id (exit code $LASTEXITCODE)" }
}

function Install-Config($src, $dst) {
    if (Test-Path $dst) {
        $bak = "$dst.bak-$stamp"
        Move-Item $dst $bak
        Info "backed up $dst -> $bak"
    }
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Copy-Item $src $dst -Recurse
    Info "installed $dst"
}

function Set-ProfileBlock($path, $body) {
    $begin = '# >>> dotfiles oh-my-posh >>>'
    $end = '# <<< dotfiles oh-my-posh <<<'
    $block = "$begin`r`n$body`r`n$end"
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $text = ''
    if (Test-Path $path) { $text = [IO.File]::ReadAllText($path) }
    $pattern = [regex]::Escape($begin) + '[\s\S]*?' + [regex]::Escape($end)
    if ($text -match $pattern) {
        $text = [regex]::Replace($text, $pattern, { param($m) $block })
    } else {
        if ($text -and -not $text.EndsWith("`n")) { $text += "`r`n" }
        $text += "$block`r`n"
    }
    [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $true))
    Info "updated $path"
}

function Set-TerminalFont($face) {
    $candidates = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    $found = $false
    foreach ($path in $candidates | Where-Object { Test-Path $_ }) {
        $found = $true
        try {
            # Strip whole-line // comments so Windows PowerShell 5.1 can parse it
            $raw = (Get-Content $path -Raw) -replace '(?m)^\s*//.*$', ''
            $json = $raw | ConvertFrom-Json
            if (-not $json.profiles.defaults) {
                $json.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
            }
            $defaults = $json.profiles.defaults
            if ($defaults.font) {
                $defaults.font | Add-Member -NotePropertyName face -NotePropertyValue $face -Force
            } else {
                $defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{ face = $face }) -Force
            }
            Copy-Item $path "$path.bak-$stamp"
            [IO.File]::WriteAllText($path, ($json | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding $false))
            Info "set Windows Terminal font to '$face' ($path)"
        } catch {
            Warn "could not update $path ($($_.Exception.Message)); set the font to '$face' by hand"
        }
    }
    if (-not $found) { Warn "Windows Terminal settings not found; set your terminal font to '$face'" }
}

# --- 0. Get the repo --------------------------------------------------------

$hasWinget = Test-Command winget
if (-not $SkipPackages -and -not $hasWinget) {
    Warn 'winget not found - install "App Installer" from the Microsoft Store, then re-run.'
    Warn 'Continuing with -SkipPackages.'
    $SkipPackages = $true
}

$root = $PSScriptRoot
if (-not $root -or -not (Test-Path (Join-Path $root 'config'))) {
    Step "Fetching dotfiles into $CloneDir"
    if (-not (Test-Command git)) {
        if (-not $hasWinget) { throw 'git is required to fetch the dotfiles and winget is unavailable to install it.' }
        Install-WingetPackage Git.Git
        Update-SessionPath
    }
    if (Test-Path (Join-Path $CloneDir '.git')) {
        git -C $CloneDir pull --ff-only
    } else {
        git clone $RepoUrl $CloneDir
    }
    if ($LASTEXITCODE -ne 0) { throw "git failed (exit code $LASTEXITCODE)" }
    $root = $CloneDir
}
$cfg = Join-Path $root 'config'

# --- 1. Packages ------------------------------------------------------------

if (-not $SkipPackages) {
    Step 'Installing packages with winget'
    @(
        'Git.Git',
        'Neovim.Neovim',
        'JanDeDobbeleer.OhMyPosh',
        'marlocarlo.psmux',
        # Telescope live grep
        'BurntSushi.ripgrep.MSVC',
        # C compiler for nvim-treesitter parsers
        'zig.zig'
    ) | ForEach-Object { Install-WingetPackage $_ }
    Update-SessionPath
}

# --- 2. Font ----------------------------------------------------------------

if (-not $SkipFont) {
    Step "Installing $fontFace"
    if (Test-Command oh-my-posh) {
        oh-my-posh font install FiraCode --user
        if ($LASTEXITCODE -ne 0) { Warn 'font install failed; install FiraCode Nerd Font from nerdfonts.com' }
    } else {
        Warn 'oh-my-posh not on PATH yet; open a new terminal and run: oh-my-posh font install FiraCode --user'
    }
    Set-TerminalFont $fontFace
}

# --- 3. Configs -------------------------------------------------------------

Step 'Installing configs'
Install-Config (Join-Path $cfg 'nvim') (Join-Path $env:LOCALAPPDATA 'nvim')
Install-Config (Join-Path $cfg 'psmux\psmux.conf') (Join-Path $HOME '.psmux.conf')
Install-Config (Join-Path $cfg 'oh-my-posh\atomic.omp.json') (Join-Path $HOME '.config\oh-my-posh\atomic.omp.json')

# --- 4. PowerShell prompt ---------------------------------------------------

Step 'Enabling oh-my-posh in PowerShell profiles'
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq 'Undefined' -or $policy -eq 'Restricted') {
    try {
        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
        Info 'set CurrentUser execution policy to RemoteSigned so profiles can load'
    } catch {
        Warn "could not change execution policy ($($_.Exception.Message)); profiles may not load"
    }
}
$docs = [Environment]::GetFolderPath('MyDocuments')
$init = 'oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\atomic.omp.json" | Invoke-Expression'
# Windows PowerShell 5.1 and PowerShell 7 keep separate profiles
Set-ProfileBlock (Join-Path $docs 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1') $init
Set-ProfileBlock (Join-Path $docs 'PowerShell\Microsoft.PowerShell_profile.ps1') $init

# --- 5. Neovim plugins ------------------------------------------------------

if (-not $SkipPlugins) {
    Step 'Installing NvChad plugins (first run can take a minute)'
    if (Test-Command nvim) {
        nvim --headless '+Lazy! sync' +qa
        if ($LASTEXITCODE -ne 0) { Warn 'plugin sync reported errors; opening nvim once will finish setup' }
    } else {
        Warn 'nvim not on PATH yet; plugins will install the first time you open nvim'
    }
}

Step 'Done'
Info 'Open a new terminal window, then run psmux and nvim.'
