
; Look of the tool's own windows (v1.0b): dark navy in the style of the Bitwarden app.
; Colours are matched by eye to the Bitwarden desktop app's dark theme, not taken from an official palette.
Theme(Key)
{
	static c := { bg: "121A27", panel: "1E293B", text: "EEF1F6", muted: "94A3B8", accent: "79A6FF", sel: "334155" }
	return c[Key]
}

Theme_BGR(Rgb)
{
	return DllCall("msvcrt\wcstoul", "Str",SubStr(Rgb, 5, 2) SubStr(Rgb, 3, 2) SubStr(Rgb, 1, 2), "Ptr",0, "Int",16, "CDecl UInt")
}

; Dark title bar in the window colour (Windows 11; older builds just ignore it)
Theme_Window(hWnd)
{
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr",hWnd, "Int",20, "Int*",1, "Int",4)
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr",hWnd, "Int",35, "Int*",Theme_BGR(Theme("bg")), "Int",4)
}

Theme_Font(GuiName, Kind)
{
	static f := { title: "s15 w600", label: "s9 w400", field: "s11 w400", button: "s10 w600" }
	color := { title: "text", label: "muted", field: "text", button: "bg" }[Kind]
	Gui %GuiName%:Font, % f[Kind] " c" Theme(color), Segoe UI
}

; Flat panel behind a borderless Edit, so the text sits centred in a taller field
Theme_Pad(GuiName, Options)
{
	Gui %GuiName%:Add, Progress, % Options " Background" Theme("panel") " Disabled +0x4000000", 0
}

; Flat accent button: a coloured block with a clickable label on top
Theme_Button(GuiName, Options, Label, GLabel)
{
	Gui %GuiName%:Add, Progress, % Options " Background" Theme("accent") " Disabled +0x4000000", 0
	Theme_Font(GuiName, "button")
	Gui %GuiName%:Add, Text, % "xp yp wp hp Center 0x200 BackgroundTrans g" GLabel, % Label
}

; Dark native push button / drop-down
Theme_Native(hCtrl, Kind := "Explorer")
{
	DllCall("uxtheme\SetWindowTheme", "Ptr",hCtrl, "WStr","DarkMode_" Kind, "Ptr",0)
}

; ListView: taller rows (call right after adding it) and a slate selection instead of the system colour
Theme_ListView(hLV, RowHeight := 34)
{
	global Theme_LVs
	if (RowHeight)
		LV_SetImageList(DllCall("ImageList_Create", "Int",1, "Int",RowHeight, "UInt",0, "Int",1, "Int",1, "Ptr"), 1)
	if !IsObject(Theme_LVs)
	{
		Theme_LVs := {}
		if (A_PtrSize = 8) ; the struct offsets below are the 64-bit ones
			OnMessage(0x4E, "Theme_Notify") ; WM_NOTIFY
	}
	DllCall("uxtheme\SetWindowTheme", "Ptr",hLV, "WStr","", "WStr","") ; unthemed, so our selection colours are honoured
	Theme_LVs[hLV + 0] := true
}

Theme_Notify(wParam, lParam)
{
	global Theme_LVs
	hFrom := NumGet(lParam + 0, 0, "Ptr")
	if !Theme_LVs.HasKey(hFrom)
		return
	if (NumGet(lParam + 0, 16, "Int") != -12) ; NM_CUSTOMDRAW
		return
	stage := NumGet(lParam + 0, 24, "UInt")
	if (stage = 0x1) ; CDDS_PREPAINT
		return 0x20 ; CDRF_NOTIFYITEMDRAW
	if (stage != 0x10001 && stage != 0x30001) ; CDDS_ITEMPREPAINT, and the same per column
		return
	item := NumGet(lParam + 0, 56, "UPtr")
	if !DllCall("SendMessage", "Ptr",hFrom, "UInt",0x102C, "Ptr",item, "Ptr",2, "Ptr") ; LVM_GETITEMSTATE, LVIS_SELECTED
		return 0
	if (stage = 0x10001)
	{
		; draw the selected row like a normal one, then colour each of its columns ourselves
		NumPut(NumGet(lParam + 0, 64, "UInt") & ~0x11, lParam + 0, 64, "UInt") ; not CDIS_SELECTED | CDIS_FOCUS
		return 0x20 ; CDRF_NOTIFYSUBITEMDRAW
	}
	NumPut(Theme_BGR(Theme("text")), lParam + 0, 80, "UInt") ; clrText
	NumPut(Theme_BGR(Theme("sel")), lParam + 0, 84, "UInt") ; clrTextBk
	return 0x2 ; CDRF_NEWFONT
}
