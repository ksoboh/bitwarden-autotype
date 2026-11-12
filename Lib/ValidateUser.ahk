
ValidateUser(Title, UsePin := true)
{
	if (UsePin && INI.GENERAL.pin && INI.DATA.pin)
	{
		hash := Crypt.Hash.String("SHA512", MasterPw)
		data := Crypt.Decrypt.String("AES", "CBC", INI.DATA.pin, hash)
		if (INI.GENERAL.pin = 1)
			valid := ValidateUser_Pin(Title, data)
		else
			valid := ValidateUser_Aac(Title, data)
		if (valid)
			return MasterPw
	}

	tries := 3
	while tries--
	{
		passwd := ValidateUser_Password()
		if (!passwd)
			continue
		out := Bitwarden("unlock --passwordenv BW_PASSWORD", passwd)
		if !ErrorLevel
		{
			SESSION := out
			return passwd
		}
		Alert(0x10, out)
	}
	return false
}

ValidateUser_Aac(Title, Secret)
{
	tries := 3
	while tries--
	{
		code := Pin(Title ": Authenticator code")
		if (code = Totp(Secret))
			return true
	}
	return false
}

ValidateUser_Password()
{
	evalExit := false
	passwd := ValidateUser_Prompt()
	if (!passwd)
	{
		Alert(0x34, "No password was entered, do you want to continue?")
		IfMsgBox No
			evalExit := true
	}
	if (evalExit && MasterPw)
		Exit
	else if (evalExit && !MasterPw)
		ExitApp
	return passwd
}

; v1.0b: the master password prompt as a styled window (was a plain InputBox). Returns "" when cancelled.
ValidateUser_Prompt()
{
	global UnlockPw, UnlockResult
	UnlockResult := ""
	Gui Unlock:New, +AlwaysOnTop -MinimizeBox +HwndhGui
	Gui Unlock:Color, % Theme("bg"), % Theme("panel")
	Theme_Font("Unlock", "title")
	Gui Unlock:Add, Text, x24 y20 w320, Unlock your vault
	Theme_Font("Unlock", "label")
	Gui Unlock:Add, Text, x24 y54 w320, % StrLen(INI.CREDENTIALS.user) ? INI.CREDENTIALS.user : "Bitwarden"
	Gui Unlock:Add, Text, x24 y90 w320, Master password
	Theme_Pad("Unlock", "x24 y112 w320 h38")
	Theme_Font("Unlock", "field")
	Gui Unlock:Add, Edit, x36 y120 w296 h22 -E0x200 Password vUnlockPw
	Gui Unlock:Add, Button, Default gValidateUser_PromptOk x-50 y-50 w1 h1
	Theme_Button("Unlock", "x24 y174 w320 h38", "Unlock", "ValidateUser_PromptOk")
	Theme_Font("Unlock", "label")
	Gui Unlock:Add, Text, x24 y226 w320 Center, Esc to cancel
	Theme_Window(hGui)
	Gui Unlock:Show, w368 h262, % AppTitle
	GuiControl Unlock:Focus, UnlockPw
	WinWaitClose ahk_id %hGui%
	passwd := UnlockResult, UnlockResult := ""
	return passwd
}

ValidateUser_PromptOk()
{
	global UnlockPw, UnlockResult
	Gui Unlock:Submit
	UnlockResult := UnlockPw, UnlockPw := ""
	Gui Unlock:Destroy
}

ValidateUser_Pin(Title, UnlockPin)
{
	tries := 3
	while tries--
	{
		pin := Pin(Title ": PIN", true, INI.ADVANCED["pin-length"])
		if (pin = UnlockPin)
			return true
	}
	return false
}


UnlockGuiClose:
UnlockGuiEscape:
	Gui Unlock:Destroy
return
