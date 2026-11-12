; Self-check for the search picker (Lib\Match_Search.ahk) with fake entries, driven by keystrokes.
; Run:  ahk\AutoHotkeyU64.exe tests\pickertest.ahk   -> tests\result.txt says PASS or FAIL (trace.txt has every step).
; A watchdog ends it after 25 s. The picker window opens three times on screen for a moment.
#NoEnv
#SingleInstance Force
SetTitleMatchMode 2
SetWorkingDir %A_ScriptDir%
FileDelete %A_ScriptDir%\result.txt
FileDelete %A_ScriptDir%\trace.txt
SetTimer Watchdog, -25000

entries := [ {name: "Gmail", username: "khalid@example.com", otpauth: ""}
	, {name: "Remote Desktop office", username: "admin", otpauth: ""}
	, {name: "FileZilla hosting", username: "ftpuser", otpauth: ""} ]

Trace("case1 start: filter by name, Enter -> entry 2")
SetTimer Case1, -400
picked1 := Match_Search(entries, "default")
Trace("case1 returned " picked1)

Trace("case2 start: no match, Enter does nothing, Escape -> 0")
SetTimer Case2, -400
picked2 := Match_Search(entries, "default")
Trace("case2 returned " picked2)

Trace("case3 start: filter by username, Enter -> entry 3")
SetTimer Case3, -400
picked3 := Match_Search(entries, "default")
Trace("case3 returned " picked3)

ok := (picked1 = 2 && picked2 = 0 && picked3 = 3)
FileAppend, % (ok ? "PASS" : "FAIL") " picked1=" picked1 " (want 2) picked2=" picked2 " (want 0) picked3=" picked3 " (want 3)`n", %A_ScriptDir%\result.txt
ExitApp

Trace(msg)
{
	FileAppend, % A_Hour ":" A_Min ":" A_Sec "." A_MSec " " msg "`n", %A_ScriptDir%\trace.txt
}

Case1:
	WinWait, Auto-Type: pick a login,, 5
	ControlSend, Edit1, office, Auto-Type: pick a login
	Sleep 300
	ControlSend, Edit1, {Enter}, Auto-Type: pick a login
return

Case2:
	WinWait, Auto-Type: pick a login,, 5
	ControlSend, Edit1, zzz, Auto-Type: pick a login
	Sleep 300
	ControlSend, Edit1, {Enter}, Auto-Type: pick a login
	Sleep 300
	IfWinExist, Auto-Type: pick a login
		ControlSend, Edit1, {Escape}, Auto-Type: pick a login
return

Case3:
	WinWait, Auto-Type: pick a login,, 5
	ControlSend, Edit1, ftp, Auto-Type: pick a login
	Sleep 300
	ControlSend, Edit1, {Enter}, Auto-Type: pick a login
return

Watchdog:
	Trace("WATCHDOG: still running, exiting")
	FileAppend, FAIL watchdog timeout`n, %A_ScriptDir%\result.txt
	ExitApp
return

; The library ends with GUI labels, so it must come after the auto-execute section (as in bw-at.ahk).
#Include %A_ScriptDir%/../Lib/Theme.ahk
#Include %A_ScriptDir%/../Lib/Match_Search.ahk
