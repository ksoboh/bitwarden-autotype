
; Local patch 6 (2026-11-09): no window match -> pick any login by typing part of its name or user.
; Returns the index into Matches, or 0 when the window is closed without a pick. Restyled in v1.0b (Lib\Theme.ahk).
Match_Search(Matches, Mode)
{
	global MatchSearch_List, MatchSearch_Rows, MatchSearch_Picked, MatchSearchText
	MatchSearch_List := Matches
	MatchSearch_Rows := []
	MatchSearch_Picked := 0

	Gui MatchSearch:New, +AlwaysOnTop -MinimizeBox +HwndhGui
	Gui MatchSearch:Color, % Theme("bg"), % Theme("panel")
	Theme_Font("MatchSearch", "title")
	Gui MatchSearch:Add, Text, x24 y20 w460, Pick a login
	Theme_Font("MatchSearch", "label")
	Gui MatchSearch:Add, Text, x24 y54 w460, % "No saved match for this window. Type to search, Enter to fill"
		. (Mode = "default" ? "." : " (" Mode " only).")
	Theme_Pad("MatchSearch", "x24 y86 w460 h38")
	Theme_Font("MatchSearch", "field")
	Gui MatchSearch:Add, Edit, x36 y94 w436 h22 -E0x200 vMatchSearchText gMatch_SearchFilter +HwndhEdit
	DllCall("SendMessage", "Ptr",hEdit, "UInt",0x1501, "Ptr",1, "WStr","Search name or username") ; EM_SETCUEBANNER
	Gui MatchSearch:Add, ListView, % "x24 y144 w460 h246 -Hdr -E0x200 -Multi AltSubmit +LV0x10020 gMatch_SearchRow +HwndhLV"
		. " Background" Theme("panel") " c" Theme("text"), Entry|User
	Theme_ListView(hLV)
	Gui MatchSearch:Add, Button, Default gMatch_SearchUse x-50 y-50 w1 h1
	Theme_Font("MatchSearch", "label")
	Gui MatchSearch:Add, Text, x24 y410 w200 h20 0x200, Esc to cancel
	Theme_Button("MatchSearch", "x364 y402 w120 h36", "Fill login", "Match_SearchUse")
	Match_SearchFilter()
	Theme_Window(hGui)
	Gui MatchSearch:Show, w508 h458, Bitwarden Auto-Type: pick a login
	GuiControl MatchSearch:Focus, MatchSearchText

	WinWaitClose ahk_id %hGui%
	return MatchSearch_Picked
}

Match_SearchFilter()
{
	global MatchSearch_List, MatchSearch_Rows
	Gui MatchSearch:Default
	GuiControlGet text,, MatchSearchText
	LV_Delete()
	MatchSearch_Rows := []
	for i,entry in MatchSearch_List
	{
		if (text != "" && !InStr(entry.name, text) && !InStr(entry.username, text))
			continue
		LV_Add("", "  " entry.name, entry.username)
		MatchSearch_Rows.Push(i)
	}
	LV_ModifyCol(1, 250)
	LV_ModifyCol(2, MatchSearch_Rows.Count() > 7 ? 190 : 210)
	LV_Modify(1, "Select Focus")
}

Match_SearchRow(CtrlHwnd, GuiEvent, EventInfo)
{
	if (GuiEvent = "DoubleClick" && EventInfo)
		Match_SearchPick(EventInfo)
}

Match_SearchUse()
{
	Gui MatchSearch:Default
	row := LV_GetNext(0, "F")
	if (!row)
		row := LV_GetNext()
	if (row)
		Match_SearchPick(row)
}

Match_SearchPick(Row)
{
	global MatchSearch_Rows, MatchSearch_Picked
	MatchSearch_Picked := MatchSearch_Rows[Row]
	Gui MatchSearch:Destroy
}


MatchSearchGuiClose:
MatchSearchGuiEscape:
	Gui MatchSearch:Destroy
return
