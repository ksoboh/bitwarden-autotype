; Shows one of the tool's windows with fake data, for a visual check. No vault, no login, nothing is typed.
; Lives in the repo root so AutoHotkey finds the Lib folder. Run:  ahk\AutoHotkeyU64.exe uitest.ahk login|unlock|generator|select|search
; It writes the window rectangle to %TEMP%\bwat-uitest-rect.txt after a moment (used for screenshots).
#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
Menu Tray, Icon, %A_ScriptDir%/assets/bw-at.ico
global INI, AppTitle := "Bitwarden Auto-Type", AppVersion := "1.0b", MasterPw := "", GuiControls
which = %1%
; a blank throwaway settings file: never read the real bw-at.ini here, it holds the API key after login
FileDelete %A_Temp%\bwat-uitest.ini
FileAppend, [CREDENTIALS]`nuser=`ntsl=0`napi-key=0`nclient-id=`nclient-secret=`n[GENERAL]`npin=0`n[GENERATOR]`nlower=1`nupper=1`ndigits=1`nsymbols=1`nlength=39`nexclude=`n, %A_Temp%\bwat-uitest.ini
INI := Ini(A_Temp "\bwat-uitest.ini", false)
FileDelete %A_Temp%\bwat-uitest-rect.txt
SetTimer Rect, -900

fake := [ {name: "Gmail", username: "khalid@example.com", otpauth: "x", host: "", domain: ""}
	, {name: "Outlook", username: "k.soboh@example.com", otpauth: "", host: "", domain: ""}
	, {name: "Remote Desktop office", username: "admin", otpauth: "", host: "", domain: ""}
	, {name: "FileZilla hosting", username: "ftpuser", otpauth: "", host: "", domain: ""}
	, {name: "Ubisoft Connect", username: "khalid@example.com", otpauth: "x", host: "", domain: ""}
	, {name: "Router", username: "admin", otpauth: "", host: "", domain: ""}
	, {name: "Steam", username: "ks_gamer", otpauth: "x", host: "", domain: ""} ]

if (which = "login")
	Login()
else if (which = "unlock")
{
	INI.CREDENTIALS.user := "khalid@example.com"
	ValidateUser_Prompt()
}
else if (which = "generator")
{
	Generator()
	pw := Generator_Password(INI.GENERATOR, bits)
	GuiControl Generator:, Edit3, % pw
	GuiControl Generator:, Static4, % "Entropy: " bits " bits"
	FileDelete %A_Temp%\bwat-uitest-gen.txt
	FileAppend, % "len=" StrLen(pw) " want=" INI.GENERATOR.length " bits=" bits, %A_Temp%\bwat-uitest-gen.txt
	return
}
else if (which = "select")
	Match_Select([fake[1], fake[5], fake[2]], "default")
else
	Match_Search(fake, "default")
ExitApp

Rect:
	DetectHiddenWindows Off
	h := WinExist("ahk_class AutoHotkeyGUI ahk_pid " DllCall("GetCurrentProcessId"))
	VarSetCapacity(r, 16, 0)
	DllCall("dwmapi\DwmGetWindowAttribute", "Ptr",h, "Int",9, "Ptr",&r, "Int",16)
	FileAppend, % NumGet(r,0,"Int") "," NumGet(r,4,"Int") "," NumGet(r,8,"Int") "," NumGet(r,12,"Int"), %A_Temp%\bwat-uitest-rect.txt
return

#Include %A_ScriptDir%/Lib/Match.ahk
#Include %A_ScriptDir%/Lib/ExitApp.ahk
