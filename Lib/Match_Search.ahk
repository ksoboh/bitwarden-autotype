
; Local patch 6 (2026-11-09): no window match -> pick any login by typing part of its name or user.
; Returns the index into Matches, or 0 when the window is closed without a pick.
Match_Search(Matches, Mode)
{
	global MatchSearch_List, MatchSearch_Rows, MatchSearch_Picked, MatchSearchText
	MatchSearch_List := Matches
	MatchSearch_Rows := []
	MatchSearch_Picked := 0

	Gui MatchSearch:New, +AlwaysOnTop +LastFound +ToolWindow
	hGui := WinExist()
	Gui MatchSearch:Font, s11
	Gui MatchSearch:Add, Edit, vMatchSearchText gMatch_SearchFilter w440
	Gui MatchSearch:Add, ListView, AltSubmit Grid -Multi gMatch_SearchRow r12 w440, Entry|User
	Gui MatchSearch:Add, Button, Default gMatch_SearchUse x-50 y-50
	Match_SearchFilter()
	Gui MatchSearch:Show,, % "Auto-Type: pick a login (" Mode ")"

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
		LV_Add("", entry.name, entry.username)
		MatchSearch_Rows.Push(i)
	}
	LV_ModifyCol(1, 260)
	LV_ModifyCol(2, 160)
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
