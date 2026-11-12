
Autorun()
{
	Autorun_Set(!Autorun_Get())
}

Autorun_Get()
{
	RegRead state, HKCU\Software\Microsoft\Windows\CurrentVersion\Run, % AppTitle
	return !!state
}

Autorun_Set(state)
{
	keyDir := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
	if (state)
		RegWrite REG_SZ, % keyDir, % AppTitle, % A_IsCompiled ? Quote(A_ScriptFullPath) : Quote(A_AhkPath) " " Quote(A_ScriptFullPath)
	else
		RegDelete % keyDir, % AppTitle
	Menu sub1, % state ? "Check" : "UnCheck", 3&
}
