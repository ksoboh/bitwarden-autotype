
Match(Mode)
{
	KeysWait() ; Until released

	; Unlock/Login if needed
	if (IsLocked && !Lock_Toggle())
		return
	if (!IsLogged && !Login_Toggle())
		return

	; Early fail if Clipboard unaccessible for TCATO
	hWnd := DllCall("User32\GetOpenClipboardWindow", "Ptr")
	if (INI.GENERAL.tcato && hWnd)
	{
		WinGet exe, ProcessName, % "ahk_id" hWnd
		Alert(0x10, "TCATO cannot access the Clipboard. "
			. (exe ? Quote(exe) " is currently blocking it." : ""))
		return
	}

	; Increase
	Process Priority,, High

	hWnd := WinExist("A")
	WinGetClass activeClass
	WinGetTitle activeTitle
	WinGet exe, ProcessName

	; Get Url and it parts if browser
	url := Match_ParseUrl(hWnd, exe, activeClass)

	matches := []
	; Loop through the JSON
	for _,entry in BwFields
	{
		if (Mode = "totp" && !entry.otpauth)
			continue

		isMatch := false
		if (url) ; by URL
			isMatch := Match_ByUrl(url, entry)
		; by .exe
		else if (SubStr(entry.uri, -3) = ".exe")
			isMatch := (exe = entry.uri)
		; by class
		else if RegExMatch(entry.uri, "class=(.+)", $)
			isMatch := ($1 = activeClass)
		; by window title, exact match
		else if RegExMatch(entry.uri, "title=(.+)", $)
			isMatch := ($1 == activeTitle)
		; by window title, partial match
		else if (!entry.schema && StrLen(entry.uri)) ; patch 6: URI-less logins never match by title
			isMatch := InStr(activeTitle, entry.uri)

		if (!isMatch)
			continue

		; Add a typing sequence
		if (entry.HasKey("field") && Mode = "default")
			entry.sequence := entry.field
		else
			entry.sequence := INI.SEQUENCES[Mode]
		matches.Push(entry)
	}

	; Back to normal
	Process Priority,, Normal

	matchId := matches.Count()
	if (!matchId)
	{
		; Local patch 6: nothing matched this window, offer every login (one row each) in a search picker
		seen := {}
		for _,entry in BwFields
		{
			if (Mode = "totp" && !entry.otpauth)
				continue
			key := entry.name "|" entry.username
			if seen.HasKey(key)
				continue
			seen[key] := true
			if (entry.HasKey("field") && Mode = "default")
				entry.sequence := entry.field
			else
				entry.sequence := INI.SEQUENCES[Mode]
			matches.Push(entry)
		}
		matchId := matches.Count() ? Match_Search(matches, Mode) : 0
	}
	else if (matchId > 1)
		matchId := Match_Select(matches, Mode)
	WinActivate % "ahk_id" hWnd
	; Local patch 7: a picker may have had the focus; let the target window take it back before typing
	WinWaitActive % "ahk_id" hWnd,, 1
	Sleep 150
	if (matchId)
		AutoType(matches[matchId], Mode)
}

Match_ByUrl(Url, Entry)
{
	switch Entry.match
	{
		; Never
		case 5: return
		; RegEx
		case 4: return RegExMatch(Url.Url, Entry.uri)
		; Exact
		case 3: return InStr(Url.Url, Entry.uri, true)
		; Start
		case 2: return InStr(Url.Url, Entry.uri) ; at 1,8,9
		; Host
		case 1: return (Url.Host = Entry.host)
		; Base Domain
		default:
			return (Url.Domain = Entry.domain)
	}
}

Match_ParseUrl(hWnd, Exe, WinClass)
{
	if !(Exe ~= "i)^(chrome|msedge|firefox|iexplore|opera|min)\.exe")
		return
	Url := Url_Get(hWnd, WinClass)
	if (url)
	{
		Url_Split(url, host, domain)
		return {Url:url, Host:host, Domain:domain}
	}
	Alert(0x134, "Couldn't get the URL from " Quote(Exe) ". Continue?")
	IfMsgBox No
		Exit
}

Match_Row(CtrlHwnd, GuiEvent, EventInfo)
{
	GuiControl ,, Edit1, % EventInfo
	if (GuiEvent = "DoubleClick")
		Match_Use()
}

Match_Select(Matches, Mode)
{
	static MatchId

	; v1.0b look (Lib\Theme.ahk)
	Gui Match:New, +AlwaysOnTop +LastFound -MinimizeBox +HwndhGui
	Gui Match:Color, % Theme("bg"), % Theme("panel")
	Gui Match:Margin, 24, 20
	Theme_Font("Match", "title")
	Gui Match:Add, Text,, Choose a login
	Theme_Font("Match", "label")
	Gui Match:Add, Text, y+4, Several logins match this window. Double-click one, or select it and press Enter.
	Theme_Font("Match", "field")
	Gui Match:Add, ListView, % "y+16 r" Min(Matches.Count() + 1, 12) " AltSubmit -Multi -Hdr -E0x200 +LV0x10020 gMatch_Row +HwndhLV"
		. " Background" Theme("panel") " c" Theme("text")
		, % "|#|Entry|User" (Mode = "totp" ? "" : "|TOTP")
	Theme_ListView(hLV, 0)
	Theme_Window(hGui)
	Gui Match:Add, Button, Default gMatch_Use x-50 y-50

	total := Matches.Count()
	iconList := IL_Create(total)
	LV_SetImageList(iconList)
	for i,match in Matches
	{
		; Row
		LV_Add("Icon" i,, i, match.name, match.username
			, Mode = "totp" ? "" : (match.otpauth ? "2FA code" : ""))
		; Icon
		if (SubStr(match.host, -3) = ".exe")
		{
			WinGet exe, ProcessPath, % "ahk_exe" match.host
			IL_Add(iconList, exe ? exe : "consent.exe")
			continue
		}
		img := ""
		loop files, % "icons\" match.domain ".*"
			img := A_LoopFileFullPath
		loop files, % "icons\" match.host ".*"
			img := A_LoopFileFullPath
		if (img)
			IL_Add(iconList, img, 0xFFFFFF, 1)
		else
			IL_Add(iconList, "imageres.dll", 300)
	}

	; Auto-size
	LV_ModifyCol()
	LV_ModifyCol(2, "Center")
	if (Mode != "totp")
		LV_ModifyCol(5, "AutoHdr Center")
	cols := LV_GetCount("Column")
	listViewWidth := cols * cols
	Loop % cols
	{
		; 0x101D = LVM_GETCOLUMNWIDTH
		SendMessage 0x101D, % A_Index - 1, 0, SysListView321
		listViewWidth += ErrorLevel
	}
	GuiControl Move, SysListView321, % "w" listViewWidth

	Mode := { "default": "Default"
		, "username": "Username-only"
		, "password": "Password-only"
		, "totp": "TOTP" }[Mode]
	Gui Match:Add, Edit, Hidden vMatchId x0 y0, % MatchId := ""
	Gui Match:Show, AutoSize, % " Select Entry (" Mode " sequence)"

	WinWaitClose
	return MatchId
}

Match_Use()
{
	Gui Match:Submit
	Gosub MatchGuiClose
}


MatchGuiClose:
MatchGuiEscape:
	Gui Match:Destroy
return
