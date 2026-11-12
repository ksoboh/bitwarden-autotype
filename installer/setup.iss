; Inno Setup script for Bitwarden Auto-Type (ksoboh fork). Built by installer\build.ps1, which passes Src and Repo.
; Per-user install, no admin rights. The tool runs in "portable" mode: its settings (bw-at.ini, holds the API
; client id/secret after login) and the CLI state (data.json, the encrypted vault) live next to bw-at.exe.
#define AppVer "1.0b"

[Setup]
AppId={{6B6F0A3E-5C1D-4E0B-9A54-7C1B0F2D91A7}
AppName=Bitwarden Auto-Type
AppVersion={#AppVer}
AppVerName=Bitwarden Auto-Type {#AppVer}
AppPublisher=ksoboh
AppPublisherURL=https://github.com/ksoboh/bitwarden-autotype
AppSupportURL=https://github.com/ksoboh/bitwarden-autotype/issues
DefaultDirName={localappdata}\Programs\Bitwarden Auto-Type
DefaultGroupName=Bitwarden Auto-Type
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#Repo}\release
OutputBaseFilename=Bitwarden-AutoType-Setup-{#AppVer}
SetupIconFile={#Repo}\assets\bw-at.ico
UninstallDisplayIcon={app}\bw-at.exe
UninstallDisplayName=Bitwarden Auto-Type {#AppVer}
LicenseFile={#Repo}\installer\NOTICE.txt
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"

[Files]
Source: "{#Src}\bw-at.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\bw.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Repo}\README.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Repo}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Repo}\installer\NOTICE.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Bitwarden Auto-Type"; Filename: "{app}\bw-at.exe"; WorkingDir: "{app}"
Name: "{group}\Read me"; Filename: "{app}\README.txt"
Name: "{userdesktop}\Bitwarden Auto-Type"; Filename: "{app}\bw-at.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\bw-at.exe"; Description: "Start Bitwarden Auto-Type"; WorkingDir: "{app}"; Flags: nowait postinstall skipifsilent

[Registry]
; the tool's own Autorun switch writes this value; make sure an uninstall takes it away
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "Bitwarden Auto-Type"; ValueType: none; Flags: dontcreatekey uninsdeletevalue

[UninstallDelete]
; never leave the API key or the vault copy behind
Type: files; Name: "{app}\bw-at.ini"
Type: files; Name: "{app}\data.json"
Type: files; Name: "{app}\data.json.*"
Type: files; Name: "{app}\debug.txt"
Type: filesandordirs; Name: "{app}\icons"
