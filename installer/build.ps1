# Builds release\Bitwarden-AutoType-Setup-<ver>.exe from a CLEAN copy of the source.
#   powershell -NoProfile -ExecutionPolicy Bypass -File installer\build.ps1 [-Source <clean checkout>] [-Cache <folder with the two zips>]
# Needs: Inno Setup 6 (ISCC.exe) and internet (or -Cache). Downloads AutoHotkey 1.1.37.02 (compiler + base file)
# and Bitwarden CLI 2026.10.1 from their official GitHub releases and checks both SHA-256 hashes.
# IMPORTANT: the compiler embeds bw-at.ini from the source folder into the exe (FileInstall). After a login that
# file holds the API client id and secret, so this script refuses to build from a folder whose ini is filled in.
# Build from a fresh clone or from:  git archive HEAD | tar -x -C <empty folder>
param(
    [string]$Source = (Split-Path -Parent $PSScriptRoot),
    [string]$Cache = "",
    [string]$Work = (Join-Path $env:TEMP 'bwat-build')
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AhkUrl = 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.1.37.02/AutoHotkey_1.1.37.02.zip'
$AhkSha = '6F3663F7CDD25063C8C8728F5D9B07813CED8780522FD1F124BA539E2854215F'
$BwUrl  = 'https://github.com/bitwarden/clients/releases/download/cli-v2026.10.1/bw-windows-2026.10.1.zip'
$BwSha  = '5043129FFBAD5FA494B387CCD5E14E19EC9411B3DFC7F75C276AADC9F070E7F1'

$Source = (Resolve-Path $Source).Path
$filled = Select-String -Path (Join-Path $Source 'bw-at.ini') -Pattern '^(user|client-id|client-secret)[ \t]*=[ \t]*\S'
if ($filled) { throw "bw-at.ini in $Source holds credentials. Build from a clean checkout (see the top of this script)." }

$iscc = @("$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe", "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:ProgramFiles\Inno Setup 6\ISCC.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 (ISCC.exe) not found. Install it: winget install JRSoftware.InnoSetup' }

if (Test-Path $Work) { Remove-Item $Work -Recurse -Force }
New-Item -ItemType Directory -Path "$Work\out" -Force | Out-Null

function Get-VerifiedZip([string]$Url, [string]$Sha, [string]$Dest) {
    $name = Split-Path $Url -Leaf
    $zip = Join-Path $Work $name
    if ($Cache -and (Test-Path (Join-Path $Cache $name))) { Copy-Item (Join-Path $Cache $name) $zip }
    else { Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing }
    $h = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($h -ne $Sha) { throw "SHA-256 mismatch for $name. Expected $Sha, got $h." }
    Expand-Archive -Path $zip -DestinationPath $Dest -Force
}

Write-Host '1/4 AutoHotkey 1.1.37.02 (compiler), hash checked'
Get-VerifiedZip $AhkUrl $AhkSha "$Work\ahk"
Copy-Item "$Work\ahk\AutoHotkeyU64.exe" "$Work\ahk\AutoHotkey.exe"   # the compiler looks for this name

Write-Host '2/4 Bitwarden CLI 2026.10.1, hash and signature checked'
Get-VerifiedZip $BwUrl $BwSha "$Work\bw"
$sig = Get-AuthenticodeSignature "$Work\bw\bw.exe"
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike 'CN=Bitwarden Inc.*') { throw "bw.exe signature check failed: $($sig.Status)" }
Copy-Item "$Work\bw\bw.exe" "$Work\out\bw.exe"

Write-Host '3/4 Compiling bw-at.ahk'
$p = Start-Process -FilePath "$Work\ahk\Compiler\Ahk2Exe.exe" -Wait -PassThru -ArgumentList @('/in', "`"$Source\bw-at.ahk`"", '/out', "`"$Work\out\bw-at.exe`"", '/base', "`"$Work\ahk\Compiler\Unicode 64-bit.bin`"", '/silent', 'verbose')
if ($p.ExitCode -ne 0 -or -not (Test-Path "$Work\out\bw-at.exe")) { throw "Ahk2Exe failed (exit $($p.ExitCode))" }

Write-Host '4/4 Building the installer'
& $iscc "/DSrc=$Work\out" "/DRepo=$Source" /Q (Join-Path $Source 'installer\setup.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC failed (exit $LASTEXITCODE)" }

$setup = Get-ChildItem (Join-Path $Source 'release') -Filter 'Bitwarden-AutoType-Setup-*.exe' | Sort-Object LastWriteTime | Select-Object -Last 1
Write-Host ''
Write-Host ("Built: {0}  ({1:n1} MB)" -f $setup.FullName, ($setup.Length / 1MB))
Write-Host ("SHA-256: {0}" -f (Get-FileHash $setup.FullName -Algorithm SHA256).Hash)
