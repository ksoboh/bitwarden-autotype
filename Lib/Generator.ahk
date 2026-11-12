
Generator()
{
	; v1.0b look (Lib\Theme.ahk). Creation order and the texts of the checkboxes and buttons are unchanged:
	; Generator_Monitor addresses them as Button1-4, Edit1-3, Static4 and by the texts Copy / Generate.
	Gui Generator:New, +AlwaysOnTop +LabelGenerator +LastFound -MinimizeBox +HwndhGui
	Gui Generator:Color, % Theme("bg"), % Theme("panel")
	Gui Generator:Font, % "s10 w400 c" Theme("text"), Segoe UI
	for i,key in ["Lower", "Upper", "Digits", "Symbols"]
	{
		Gui Generator:Add, CheckBox, % (INI.GENERATOR[key] ? "Checked" : "") " x" 24 + (i - 1) * 82 " y66 w78 h20 +HwndhChk", % key
		DllCall("uxtheme\SetWindowTheme", "Ptr",hChk, "WStr","", "WStr","") ; unthemed, so the text takes our colour
	}
	Theme_Font("Generator", "label")
	Gui Generator:Add, Text, x24 y104 w100, Length
	Theme_Pad("Generator", "x24 y124 w100 h38")
	Theme_Font("Generator", "field")
	Gui Generator:Add, Edit, x36 y132 w76 h22 -E0x200 Number
	Gui Generator:Add, UpDown, Range1-999, % INI.GENERATOR.length
	Theme_Font("Generator", "label")
	Gui Generator:Add, Text, x140 y104 w204, Exclude these characters
	Theme_Pad("Generator", "x140 y124 w204 h38")
	Theme_Font("Generator", "field")
	Gui Generator:Add, Edit, x152 y132 w180 h22 -E0x200 gGenerator_filter, % INI.GENERATOR.exclude
	Theme_Font("Generator", "label")
	Gui Generator:Add, Text, x24 y174 w320, Password
	Theme_Pad("Generator", "x24 y194 w320 h38")
	Gui Generator:Font, % "s11 w400 c" Theme("text"), Consolas
	Gui Generator:Add, Edit, x36 y202 w296 h22 -E0x200
	Theme_Font("Generator", "label")
	Gui Generator:Add, Text, x24 y248 w150 h36 0x200, Entropy: 0 bits
	Gui Generator:Font, s10 w400, Segoe UI
	Gui Generator:Add, Button, x176 y248 w80 h36 +HwndhCopy, Copy
	Gui Generator:Add, Button, x264 y248 w80 h36 Default +HwndhGen, Generate
	Theme_Native(hCopy), Theme_Native(hGen)
	Theme_Font("Generator", "title")
	Gui Generator:Add, Text, x24 y20 w320, Password generator
	Theme_Window(hGui)
	Gui Generator:Show, w368 h308, % AppTitle
	GuiControls()
	INI.GENERATOR.AtomicSet(0)
	OnMessage(0x0101, "Generator_Monitor") ; WM_KEYUP
	OnMessage(0x0202, "Generator_Monitor") ; WM_LBUTTONUP
	OnMessage(0x020A, "Generator_Monitor") ; WM_MOUSEWHEEL
}

Generator_Filter(ctrlHwnd)
{
	filtered := ""
	GuiControlGet value,, % ctrlHwnd
	loop parse, % StrReplace(value, " ")
		filtered .= InStr(filtered, A_LoopField) ? "" : A_LoopField
	GuiControl ,, % ctrlHwnd, % filtered
	Send {End}
}

Generator_Monitor(wParam, lParam, msg, hWnd)
{
	global GuiControls
	controlId := GuiControls[hWnd]
	; Scroll
	if (msg = 0x20A)
	{
		update := false
		if (controlId = "Edit1")
		{
			update := true
			GuiControlGet value,, Edit1
			value += wParam = 7864320 ? 1 : -1
			INI.GENERATOR.length := value ? value : 1
		}
	}
	else ; Click/Type
	{
		; Tab
		if (lParam = 3222208513)
			return

		; Up|Down
		GuiControlGet focused, Focus
		if (lParam ~= "(3242721281|3243245569)" && focused != "Edit1")
			return

		update := true

		; Checkboxes
		if (controlId ~= "Button[1-4]")
		{
			GuiControlGet isChecked,, % controlId
			INI.GENERATOR[A_GuiControl] := !isChecked
		}
		; Length
		else if (controlId ~= "Edit1|updown")
		{
			GuiControlGet value,, Edit1
			INI.GENERATOR.length := value
		}
		; Exclude
		else if (controlId = "Edit2")
		{
			GuiControlGet value,, Edit2
			INI.GENERATOR.exclude := value
		}
		else if (A_GuiControl = "Copy")
		{
			GuiControlGet Clipboard,, Edit3
			return
		}
		else if (A_GuiControl != "Generate")
			update := false
	}
	if (update)
	{
		GuiControl Text, Edit3, % Generator_Password(INI.GENERATOR, entropy)
		GuiControl Text, Static4, % "Entropy: " entropy " bits"
	}
}

Generator_Password(Options, ByRef Entropy)
{
	out := from := ""
	if (Options.lower)
		from .= "abcdefghijklmnopqrstuvwxyz"
	if (Options.upper)
		from .= "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	if (Options.digits)
		from .= "0123456789"
	if (Options.symbols)
		from .= "!""#$%&'()*+,-./:;<=>?@[\]^_``{|}~"
	StringCaseSense On
	loop parse, % Options.exclude
		from := StrReplace(from, A_LoopField)
	StringCaseSense Off
	dict := StrLen(from)
	from := StrSplit(from)
	loop % Options.length
	{
		rnd := Generator_Rand(dict)
		out .= from[rnd]
	}
	return out, Entropy := Entropy(dict, Options.length)
}


; v1.0b: random numbers from Windows' cryptographic generator (was AHK's Random seeded with the clock).
; Returns 1..Max without modulo bias.
Generator_Rand(Max)
{
	limit := 0x100000000 - Mod(0x100000000, Max)
	loop
	{
		n := 0
		if !DllCall("advapi32\SystemFunction036", "UInt*",n, "UInt",4) ; RtlGenRandom
			throw Exception("No secure random numbers available")
	} until (n < limit)
	return Mod(n, Max) + 1
}

GeneratorClose:
GeneratorEscape:
	Gui Generator:Destroy
	INI.GENERATOR.Commit()
return
