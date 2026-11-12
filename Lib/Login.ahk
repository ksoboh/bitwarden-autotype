
Login()
{
	static Passwd
	tsl := INI.CREDENTIALS.tsl
	tsl := "None" (!tsl ? "||" : "|")
		. "Email Verification Codes" (tsl = 1 ? "||" : "|")
		. "Authenticator Application" (tsl = 2 ? "||" : "|")
		. "YubiKey OTP Security Key" (tsl = 3 ? "||" : "|")
	; v1.0b look (Lib\Theme.ahk). The creation order of the checkbox, the three labels, the edits and the
	; drop-down must stay as it is: the functions below address them as Button1, Static1-3, Edit1-4, ComboBox1.
	Gui Login:New, +LastFound -MinimizeBox +HwndhGui
	Gui Login:Color, % Theme("bg"), % Theme("panel")
	Theme_Font("Login", "label")
	c := INI.CREDENTIALS["api-key"] ? "Checked " : ""
	Gui Login:Add, Checkbox, % c "x24 y89 w16 h16 gLogin_Api_Toggle"
	Gui Login:Add, Link, gLogin_Link -TabStop x334 y87, <a>?</a>
	Gui Login:Add, Text, x24 y122 w320, &Email Address:
	Theme_Pad("Login", "x24 y142 w320 h38")
	Theme_Font("Login", "field")
	Gui Login:Add, Edit, x36 y150 w296 h22 -E0x200 gLogin_Check, % INI.CREDENTIALS.user
	Theme_Font("Login", "label")
	Gui Login:Add, Text, x24 y192 w320, Master &Password:
	Theme_Pad("Login", "x24 y212 w320 h38")
	Theme_Font("Login", "field")
	Gui Login:Add, Edit, x36 y220 w296 h22 -E0x200 gLogin_Check Password
	Theme_Font("Login", "label")
	Gui Login:Add, Text, x24 y262 w320, &Two-step Login:
	Theme_Pad("Login", "x24 y282 w320 h38")
	Theme_Font("Login", "field")
	Gui Login:Add, DropDownList, x24 y286 w320 gLogin_Check AltSubmit +HwndhDDL, % tsl
	Theme_Native(hDDL, "CFD")
	Gui Login:Add, Edit, x36 y290 w296 h22 -E0x200 gLogin_Check Password
	Gui Login:Font, s10 w400, Segoe UI
	Gui Login:Add, Button, x24 y346 w154 h36 gExitApp +HwndhExit, E&xit
	Gui Login:Add, Button, x190 y346 w154 h36 Default gLogin_Ok +HwndhOk, &Log in
	Theme_Native(hExit), Theme_Native(hOk)
	GuiControl Focus, % "Edit" !!INI.CREDENTIALS.user + 1

	Login_Api_Toggle()
	Gui Login:Add, Edit, Hidden vPasswd x0 y0
	Theme_Font("Login", "title")
	Gui Login:Add, Text, x24 y20 w320, Log in to Bitwarden
	Theme_Font("Login", "label")
	Gui Login:Add, Text, x24 y54 w320, Later starts only ask for the master password.
	Gui Login:Add, Text, x48 y88 w270 gLogin_ApiLabel, Use Personal API Key (recommended)
	Login_Check()
	Theme_Window(hGui)
	Gui Login:Show, w368 h406, Bitwarden Auto-Type

	WinWaitClose
	return Passwd
}

Login_Api(Passwd)
{
	out := Bitwarden("login --apikey")
	if (ErrorLevel)
	{
		ALert(0x10, out)
		Exit
	}
	return "unlock --passwordenv BW_PASSWORD"
}

Login_Api_Toggle()
{
	GuiControlGet apiEnabled,, Button1
	if (apiEnabled)
	{
		GuiControl Text, Static1, Client &ID:
		GuiControl ,, Edit1, % INI.CREDENTIALS["client-id"]
		GuiControl Text, Static2, Client &Secret:
		GuiControl ,, Edit2, % INI.CREDENTIALS["client-secret"]
		GuiControl Text, Static3, Master &Password:
		GuiControl Hide, ComboBox1
		GuiControl Show, Edit3
	}
	else
	{
		GuiControl Text, Static1, &Email Address:
		GuiControl ,, Edit1, % INI.CREDENTIALS.user
		GuiControl Text, Static2, Master &Password:
		GuiControl ,, Edit2
		GuiControl Text, Static3, &Two-step Login:
		GuiControl Show, ComboBox1
		GuiControl Hide, Edit3
	}
}

Login_Check()
{
	edits := []
	loop 3
	{
		GuiControlGet value,, % "Edit" A_Index
		if Trim(value)
			edits[A_Index] := true
	}
	valid := false
	GuiControlGet apiEnabled,, Button1
	if (apiEnabled && edits.Count() = 3)
		|| (!apiEnabled && edits[1] && edits[2])
	{
		valid := true
	}
	GuiControl % valid ? "Enable" : "Disable", &Log in
}

; v1.0b: the checkbox has no text of its own (so the label can be coloured); a click on the label toggles it
Login_ApiLabel()
{
	GuiControlGet apiEnabled,, Button1
	GuiControl ,, Button1, % !apiEnabled
	Login_Api_Toggle()
	Login_Check()
}

Login_Credentials(Passwd)
{
	code := ""
	commandLine := "login " Quote(INI.CREDENTIALS.user)
		. " --passwordenv BW_PASSWORD"

	tsl := INI.CREDENTIALS.tsl
	if (tsl = 1) ; Email, trigger password
	{
		Async("Bitwarden", commandLine " --method 1", Passwd)
		code := Pin("Email verification")
	}
	else if (tsl = 2) ; Authenticator app
		code := Pin("Authenticator code")
	else if (tsl = 3) ; Yubikey, text input
	{
		msg := "YubiKey OTP Security Key:"
		InputBox code, % AppTitle, % msg,, 190, 125,,, Locale
	}

	if StrLen(code)
	{
		methods := [1, 0, 3] ; Email, Authenticator, Yubikey
		commandLine .= " --method " methods[tsl] " --code " code
	}

	return commandLine
}

Login_Link()
{
	message := "As of August 2021, the security in Bitwarden was increased to reduce bot traffic. Logging with a Personal API Key helps avoid Bitwarden misidentify the application with a bot.`n`nDo you want further instructions from the official Bitwarden documentation on how to get a Personal API Key?"
	Alert(0x24,, message)
	IfMsgBox Yes
		Run % "https://bitwarden.com/help/article/personal-api-key/#get-your-personal-api-key"
}

Login_Ok()
{
	GuiControlGet apiEnabled,, Button1
	loop 3
	{
		GuiControlGet edit%A_Index%,, % "Edit" A_Index
		edit%A_Index% := Trim(edit%A_Index%)
	}
	INI.CREDENTIALS["api-key"] := apiEnabled
	if (apiEnabled)
	{
		INI.CREDENTIALS["client-id"] := edit1
		INI.CREDENTIALS["client-secret"] := edit2
		GuiControl ,, Edit4, % edit3
	}
	else
	{
		INI.CREDENTIALS.user := edit1
		GuiControlGet tsl,, ComboBox1
		tsl -= 1
		INI.CREDENTIALS.tsl := tsl
		GuiControl ,, Edit4, % edit2
	}
	Gui Login:Submit
	Gui Login:Destroy
}

Login_Toggle(ShowTip := true)
{
	if (IsLogged)
	{
		SESSION := ""
		IsLogged := false
		; Local patch 5: Logout drops the decrypted vault and the master password from memory
		BwFields := []
		MasterPw := ""
		Tip("Logged out")
		Async("Bitwarden", "logout")
		; Update Menu
		Menu Tray, Disable, 1&
		Menu Tray, Disable, 2&
		Menu Tray, Disable, 7&
		Menu Tray, Rename, 3&, Log&in
		Menu Tray, Icon, shell32.dll, 48
	}
	else
	{
		; Custom login server
		if (INI.ADVANCED.server)
			Async("Bitwarden", "config server " INI.ADVANCED.server)

		passwd := Login()

		if (INI.CREDENTIALS["api-key"]
			&& INI.CREDENTIALS["client-id"]
			&& INI.CREDENTIALS["client-secret"])
			commandLine := Login_Api(passwd)
		else
			commandLine := Login_Credentials(passwd)

		; Store session information
		out := Bitwarden(commandLine, passwd)
		if (ErrorLevel)
		{
			ALert(0x10, out)
			Exit
		}
		else if (FileOpen("data.json", 0).Length < 1024)
		{
			Alert(0x10, "The server is misidentifying the application with a bot.`n`nLogin via Personal API Key is required to circumvent the issue.")
			Reload
			ExitApp 1
		}
		SESSION := out
		IsLogged := true
		IsLocked := false
		; Local patch 5: load the vault items here (startup no longer does it)
		MasterPw := passwd
		Bitwarden_Data()

		; Update Menu
		Menu Tray, Enable, 1&
		Menu Tray, Enable, 2&
		Menu Tray, Enable, 7&
		Menu Tray, Rename, 2&, &Lock
		Menu Tray, Rename, 3&, Log&out
		Menu Tray, Icon, % A_IsCompiled ? A_ScriptFullPath : A_ScriptDir "\assets\bw-at.ico"
		if (ShowTip)
			Tip("Logged In")
		return passwd
	}
}

LoginGuiClose:
LoginGuiEscape:
	Gui Login:Destroy
	ExitApp
return
