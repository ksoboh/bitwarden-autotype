Bitwarden Auto-Type (bitwarden-autotype): KeePass-style auto-type for Bitwarden on Windows
==========================================================================================

Installed 2026-11-08 on the gaming PC from https://github.com/anonymous1184/bitwarden-autotype
(commit e55cca1 of 2022-05-17, licence WTFPL, 205 stars). Upstream is abandoned: last commit 2022,
issue #71 "Someone please fork this thing" (2025). It runs from SOURCE with a portable AutoHotkey,
not from the prebuilt exe or installer, so what was audited is exactly what runs.
(This file replaces upstream's 4-line README.txt, which only said to put bw.exe next to the exe.)
VERSION 1.0b (2026-11-12): the tool's windows (login, unlock, search picker, chooser, generator) have a dark
Bitwarden-style look (Lib\Theme.ahk; colours matched by eye, not an official palette), the generator uses secure
random numbers, and there is a one-file installer: Bitwarden-AutoType-Setup-1.0b.exe on the fork's Releases page
(per-user, no admin, Start menu + desktop icon, uninstall removes the settings and vault copy). It is built by
installer\build.ps1 from a CLEAN copy of the source: the compiler embeds bw-at.ini, so never build from a folder
whose ini holds the API key (the script refuses). The installer is unsigned, so Windows warns on first run.
Still plain Windows look: message boxes, the settings window, the 2FA code box. No Linux version (AutoHotkey is
Windows-only).
Windows check without a vault: ahk\AutoHotkeyU64.exe uitest.ahk login|unlock|generator|select|search

This is Khalid's fork: https://github.com/ksoboh/bitwarden-autotype (public; upstream kept as the git remote
"upstream"). Other PCs get the identical install with its install.ps1: it clones the fork, downloads the two official
binaries with hash checks and puts a shortcut on the Desktop. Record: vault note "Bitwarden Auto-Type".

WHAT IS IN THIS FOLDER
  bw-at.ahk, Lib\          the tool's source (AutoHotkey v1 script, about 5,200 lines), audited, 7 local patches (below)
  bw-at.ini                its settings file (portable mode). After login it holds the Bitwarden email, and the API
                           client id + client secret in PLAIN TEXT when the API-key login is used.
  bw.exe                   Bitwarden CLI 2026.10.1, official release (GitHub bitwarden/clients, tag cli-v2026.10.1).
                           SHA-256 5043129ffbad5fa494b387ccd5e14e19ec9411b3dfc7f75c276aadc9f070e7f1 = the hash in the
                           winget manifest (microsoft/winget-pkgs, Bitwarden.CLI 2026.10.1); Authenticode-signed by
                           Bitwarden Inc. (checked with Get-AuthenticodeSignature: Valid).
  data.json                the CLI's state: the encrypted vault copy + tokens once logged in. Treat it like a vault export.
  ahk\AutoHotkeyU64.exe    AutoHotkey 1.1.37.02 from the official GitHub release zip (AutoHotkey/AutoHotkey, 2024-03-16).
                           Unsigned, and the project publishes no checksum; zip SHA-256 was
                           6f3663f7cdd25063c8c8728f5d9b07813ced8780522fd1f124ba539e2854215f. Portable, nothing installed.
  Start Bitwarden Auto-Type.cmd   double-click to start (a tray icon appears)
  icons\, debug.txt        only appear if favicons are turned on / an error is dumped

START AND LOG IN (Khalid does this himself; Claude never types vault credentials)
  1. Double-click "Start Bitwarden Auto-Type.cmd".
  2. In the login window tick "Use Personal API Key" (Bitwarden flags plain CLI password logins as a bot).
     Get the key at vault.bitwarden.com: Settings > Security > Keys > View API key (client_id, client_secret).
     Enter client ID, client secret and the master password, OK. The toast "Auto-Type Ready" means it works.
  3. Later starts ask only for the master password (the login is kept in data.json).

USE
  Click into a login's username field and press Ctrl+Alt+A: it types username, Tab, password. You press Enter.
  Ctrl+Alt+U = username only, Ctrl+Alt+P = password only, Ctrl+Alt+O = TOTP code.
  No automatic Enter since 2026-11-10 (upstream's default ended both with {Enter}): on 2026-11-09 Ctrl+Alt+A with
  the Claude desktop app in front typed a login into the chat box and the Enter sent it. NEVER use the hotkeys
  while a chat app (Claude, Teams, WhatsApp...) is the active window: after the picker closes, the app puts the
  cursor in its message box, not in the field you clicked. In Claude's browser pane: copy from Bitwarden, Ctrl+V.
  A single item can still end with Enter through its own "auto-type" field, e.g. {Username}{Tab}{Password}{Enter}.
  If no item matches the window, a picker opens (patch 6): type part of the login's name or user, Enter (or
  double-click). So URIs are optional; add one only for programs you use every day, to skip the picker.
  Which entry is typed without the picker comes from the URIs of the Bitwarden login item:
    app://notepad.exe            match by program (exe name): most reliable
    My App Login                 match by window title, partial (plain text, no prefix)
    app://?title=Exact Title     match by exact window title
  The tool works from its own copy of the vault, taken at login. After adding or changing a URI in Bitwarden:
  right-click the tray icon > Sync (or wait: sync = 5 in bw-at.ini re-syncs every 5 minutes, set 2026-11-09 after
  "No auto-type match found" turned out to be a copy from before the URI was added).
  Several matches open a picker window. A custom typing order goes in a custom field named "auto-type",
  e.g. {Username}{Tab}{Password}{Enter} (all placeholders are listed in bw-at.ini).
  Admin (elevated) windows ignore the keystrokes unless the .cmd itself is run as administrator.
  Websites: keep using the Bitwarden browser extension. This tool's browser URL matching is weak (see the audit).

SETTINGS THAT STAY OFF (decided 2026-11-08 after the audit)
  Unlock via PIN / Authenticator    pin = 0        the PIN is encrypted with one plain SHA-512 of the master password
                                                   (no salt, no stretching), so the file allows offline guessing; the
                                                   authenticator variant sent its secret to Google Charts in a URL.
                                                   Unlock with the master password instead.
  Favicons                          favicons = 0   would fetch an icon for every vault domain with curl -k (no TLS
                                                   check) and so reveal the vault's site list to those sites.
  Update check                      updates = 0    (patch 3) upstream is dead; saves a daily call to GitHub.
  Auto-Type Obfuscation (TCATO)     tcato = 0      puts half of every password through the clipboard.
  Password generator (tray menu)    fine since 1.0b: it now draws from Windows' cryptographic random numbers.
                                                   (Upstream's was seeded with the clock.)
  Autorun (tray > Settings)         off            one click to turn on; patch 2 makes it start via ahk\ correctly.

SECURITY AUDIT 2026-11-08
  Claude read every .ahk file; Codex (ChatGPT) did an independent review; both agree.
  No backdoor, no telemetry, nothing is sent anywhere except by bw.exe to Bitwarden's own servers, plus the
  optional features above when they are turned on. The only binary blob in the source (Lib\JSON.ahk, a JSON
  parser shipped as machine code) is byte-identical to the published cJson.ahk 0.4.0 release by G33kDude.
  Know this before trusting it:
  - While it is unlocked, the WHOLE vault (usernames, passwords, TOTP seeds) sits decrypted in the script's
    memory, like KeePass with the database open. Upstream's "Lock" only hid it (cleared the CLI session, kept the
    data and the master password in memory); local patch 5 makes Lock and Logout drop both and reloads the items
    after the next unlock. Best effort: AutoHotkey cannot zero memory, the strings are released and get
    overwritten over time. Lock when leaving the PC (tray menu, or Settings > Vault timeout > Lock app).
  - The master password reaches bw.exe through its environment (Bitwarden's documented BW_PASSWORD way).
    The script encodes that environment as CP1252, so a master password with non-Latin characters would be
    mangled and the unlock would fail.
  - bw-at.ini keeps the API client secret in plain text and data.json keeps the encrypted vault, both in this
    folder (Documents is not OneDrive-synced on this PC). Never commit them and never copy the folder to Drive.
  - An error dump (debug.txt) masks credentials but can contain one character of decrypted vault JSON.
  - Its browser matching treats "Exact" and "Starts with" URI rules as substring searches, so a lookalike URL
    could receive a password: another reason to leave websites to the browser extension.

LOCAL PATCHES (git shows the files as modified; re-apply after any git pull)
  1. bw-at.ahk line 115   logged-in detection also accepts the data.json key global_account_activeAccountId
                          (Bitwarden CLI 2024.09+ renamed activeUserId; without it every start says
                          "You are already logged in", upstream issues #65 and #67)
  2. Lib\Autorun.ahk 17   the Run-key value is "<ahk\AutoHotkeyU64.exe>" "<bw-at.ahk>" instead of the bare .ahk
                          path (the .ahk file association points at AutoHotkey v2, which cannot run this v1 script)
  3. bw-at.ini            updates = 0; sync = 5 (auto-sync every 5 min, 2026-11-09); no {Enter} at the end of the
                          default and password sequences (2026-11-10)
  4. Lib\Bitwarden.ahk    Bitwarden_Data(): when the CLI answers plain text (e.g. "Vault is locked.") show it
                          instead of crashing on the JSON parse (idea from fork t-hermanns, 2026-09)
  5. Lib\Lock.ahk, Lib\Login.ahk, bw-at.ahk   Lock and Logout clear the cached vault items (BwFields) and the
                          master password; a successful unlock or login reloads the items (startup no longer loads
                          them itself). Applied 2026-11-08 on Khalid's OK. Side effect: a PIN unlock would always
                          fall back to the master password after a Lock (PIN is off anyway)
  6. Lib\Match_Search.ahk (new), Lib\Match.ahk, Lib\Bitwarden.ahk   when no item matches the active window, a
                          search picker lists every login (one row each, logins without any URI included) instead
                          of the "No auto-type match found" box; type part of name or user, Enter or double-click
                          types it; Escape cancels. Added 2026-11-09 on Khalid's "Yes, add the picker". Self-check:
                          pickertest.ahk (fake entries, driven by keystrokes) passed 3/3
  7. Lib\Match.ahk        after a picker closes, wait for the target window to be active again (WinWaitActive +
                          150 ms) before typing. Added 2026-11-09 after Ubisoft Connect (a Chromium web view, not
                          elevated) received nothing when the login was chosen from the picker
  Also: data.json was pre-created with one "bw status" run, because a fresh CLI prints "Could not find data
  file..., creating it instead." and the script would have read that line as part of the session key.
  Git in this folder: never "git add" or commit here. bw-at.ini is a tracked upstream file that now holds the API
  client id and secret; it is marked skip-worktree (git update-index --skip-worktree bw-at.ini, 2026-11-09) so
  git diff/status ignore it. When copying patched files to the Drive handoff, copy code files only, never the ini.

TESTED 2026-11-08 (again after patch 5): load check clean, starts with the portable AutoHotkey, accepts bw.exe (file version 22.15.1 >= 1.11), binds the
4 hotkeys and shows the login window; no debug.txt. Login and the actual auto-type were NOT tested (they need
Khalid's vault). First real check: log in, add app://notepad.exe to a test login in Bitwarden, open Notepad,
press Ctrl+Alt+A.

UPDATE: none expected from upstream. If ever: git pull, then re-apply the 7 patches. New bw.exe: download the
bw-windows-<ver>.zip from GitHub bitwarden/clients (cli-v<ver> tag) and compare its SHA-256 with the winget manifest
(microsoft/winget-pkgs, manifests/b/Bitwarden/CLI/<ver>/Bitwarden.CLI.installer.yaml) before replacing it.
REMOVE: Exit the tray app and delete this folder. If Autorun was turned on, turn it off first (or delete the
"Bitwarden Auto-Type" value under HKCU\Software\Microsoft\Windows\CurrentVersion\Run). Nothing else is on the PC.
