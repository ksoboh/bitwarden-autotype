# Bitwarden Auto-Type (Khalid's fork): install on a Windows PC in one command.
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 [-Destination <folder>]
# Needs: git on PATH and internet. Does: clone https://github.com/ksoboh/bitwarden-autotype (this fork, with its
# local patches), download AutoHotkey 1.1.37.02 and Bitwarden CLI 2026.10.1 from their official GitHub releases and
# check both SHA-256 hashes (+ bw.exe's Bitwarden signature), create the CLI state file, load-check the script and
# put a shortcut on the Desktop. Nothing goes outside the destination folder except that shortcut.
param(
    [string]$Destination = ""
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoUrl = 'https://github.com/ksoboh/bitwarden-autotype.git'
$AhkUrl  = 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.1.37.02/AutoHotkey_1.1.37.02.zip'
$AhkSha  = '6F3663F7CDD25063C8C8728F5D9B07813CED8780522FD1F124BA539E2854215F'   # as downloaded 2026-11-08 (the project publishes no checksum)
$BwUrl   = 'https://github.com/bitwarden/clients/releases/download/cli-v2026.10.1/bw-windows-2026.10.1.zip'
$BwSha   = '5043129FFBAD5FA494B387CCD5E14E19EC9411B3DFC7F75C276AADC9F070E7F1'   # = winget manifest Bitwarden.CLI 2026.10.1

# Destination per PC (Khalid's folder conventions), unless given
if (-not $Destination) {
    switch ($env:USERNAME) {
        'K'     { $Destination = 'C:\Users\K\Documents\Github installs\bitwarden-autotype' }
        'KS'    { $Destination = 'C:\Users\KS\Documents\Github repos\Intalled\Security\bitwarden-autotype' }
        'al_ar' { $Destination = 'C:\Users\al_ar\Documents\Github repos\Intalled\Security\bitwarden-autotype' }
        default { $Destination = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'bitwarden-autotype' }
    }
}
if (Test-Path $Destination) { throw "Already exists: $Destination (remove it first for a fresh install)" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is not on PATH' }

Write-Host "1/6 Cloning the fork into $Destination"
New-Item -ItemType Directory -Path (Split-Path $Destination) -Force | Out-Null
git clone -q $RepoUrl $Destination
# bw-at.ini is tracked (blank template) but will hold the API client id/secret after login: keep it out of git for good
git -C $Destination update-index --skip-worktree bw-at.ini

$Tmp = Join-Path $env:TEMP ('bw-at-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp | Out-Null
function Get-VerifiedZip([string]$Url, [string]$Sha, [string]$Name) {
    $zip = Join-Path $Tmp $Name
    Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing
    $h = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($h -ne $Sha) { throw "SHA-256 mismatch for $Name. Expected $Sha, got $h. The file changed upstream: stop and check before trusting it." }
    $out = Join-Path $Tmp ([IO.Path]::GetFileNameWithoutExtension($Name))
    Expand-Archive -Path $zip -DestinationPath $out -Force
    return $out
}

Write-Host "2/6 Downloading AutoHotkey 1.1.37.02 (official release zip) and checking its SHA-256"
$ahk = Get-VerifiedZip $AhkUrl $AhkSha 'AutoHotkey_1.1.37.02.zip'
New-Item -ItemType Directory -Path (Join-Path $Destination 'ahk') | Out-Null
Copy-Item (Join-Path $ahk 'AutoHotkeyU64.exe') (Join-Path $Destination 'ahk\AutoHotkeyU64.exe')
Copy-Item (Join-Path $ahk 'license.txt') (Join-Path $Destination 'ahk\license.txt')

Write-Host "3/6 Downloading Bitwarden CLI 2026.10.1 (official release zip), checking its SHA-256 and signature"
$bw = Get-VerifiedZip $BwUrl $BwSha 'bw-windows-2026.10.1.zip'
Copy-Item (Join-Path $bw 'bw.exe') (Join-Path $Destination 'bw.exe')
$sig = Get-AuthenticodeSignature (Join-Path $Destination 'bw.exe')
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike 'CN=Bitwarden Inc.*') {
    throw "bw.exe signature check failed: $($sig.Status) $($sig.SignerCertificate.Subject)"
}
Remove-Item $Tmp -Recurse -Force

Write-Host "4/6 Creating the CLI state file (so the first login answer is clean JSON)"
$env:BITWARDENCLI_APPDATA_DIR = $Destination
$status = cmd /c "`"$Destination\bw.exe`" status 2>nul"
if ("$status" -notlike '*"status":"unauthenticated"*') { throw "Unexpected bw status: $status" }

Write-Host "5/6 Load check of the script"
$chk = cmd /c "`"$Destination\ahk\AutoHotkeyU64.exe`" /ErrorStdOut /iLib NUL `"$Destination\bw-at.ahk`" 2>&1"
if ($chk) { throw "AutoHotkey reported: $chk" }

Write-Host "6/6 Desktop shortcut"
$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Bitwarden Auto-Type.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = "$Destination\ahk\AutoHotkeyU64.exe"
$s.Arguments = "`"$Destination\bw-at.ahk`""
$s.WorkingDirectory = $Destination
$s.IconLocation = "$Destination\assets\bw-at.ico,0"
$s.Description = 'Bitwarden Auto-Type (runs from source)'
$s.Save()

Write-Host ''
Write-Host "Installed: $Destination"
Write-Host "Next: double-click the 'Bitwarden Auto-Type' icon on the Desktop, tick 'Use Personal API Key', log in. Details in README.txt."
