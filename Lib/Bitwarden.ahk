
Bitwarden(Parameters, Passwd := "")
{
	global bwCli

	env := {}
	env.BITWARDENCLI_APPDATA_DIR := A_WorkingDir
	if (INI.CREDENTIALS["api-key"] && INI.CREDENTIALS["client-id"]
		&& INI.CREDENTIALS["client-secret"])
	{
		env.BW_CLIENTID := INI.CREDENTIALS["client-id"]
		env.BW_CLIENTSECRET := INI.CREDENTIALS["client-secret"]
	}
	env.BW_NOINTERACTION := "true"
	env.BW_PASSWORD := Passwd
	env.BW_RAW := "true"
	env.SystemRoot := A_WinDir
	if StrLen(SESSION)
		env.BW_SESSION := SESSION
	if StrLen(INI.ADVANCED.NODE_EXTRA_CA_CERTS)
		env.NODE_EXTRA_CA_CERTS := INI.ADVANCED.NODE_EXTRA_CA_CERTS
	return GetStdStream(bwCli " " Parameters, env)
}

Bitwarden_Data()
{
	Menu Tray, Icon, shell32.dll, 239
	out := Bitwarden("list items")
	icon := A_IsCompiled ? A_ScriptFullPath : A_ScriptDir "\assets\bw-at.ico"
	; Local patch 4: on failure the CLI answers in plain text (e.g. "Vault is locked."), not JSON
	if (ErrorLevel || !RegExMatch(out, "^\s*[\[\{]"))
	{
		Menu Tray, Icon, % icon
		Alert(0x10, Trim(out))
		return false
	}
	out := StrReplace(out, ":null", ":""""")
	BwFields := Bitwarden_Parse(JSON.Load(out))
	Menu Tray, Icon, % icon
	return true
}

Bitwarden_Parse(Items)
{
	out := []
	for _,entry in Items
	{
		; Logins only
		if (entry.type != 1)
			continue

		; Item definition
		base := { "name": entry.name
			, "otpauth": entry.login.totp
			, "password": entry.login.password
			, "reprompt": entry.reprompt
			, "username": entry.login.username }

		; Custom fields parsing
		Bitwarden_ParseFields(base, entry)

		; Entry per URI
		for _,uri in entry.login.uris
		{
			; No reference
			item := base.Clone()
			item.match := uri.match
			Url_Split(uri.uri, host, domain, schema, resource)
			item.host := host
			item.schema := schema
			item.domain := domain
			; match 4 is a RegEx, don't modify it
			item.uri := uri.match = 4 ? uri.uri : host resource
			out.Push(item)
		}
		; Local patch 6: a login without URIs still shows in the search picker
		if (!IsObject(entry.login.uris) || !entry.login.uris.Count())
		{
			item := base.Clone()
			item.match := "", item.host := "", item.schema := "", item.domain := "", item.uri := ""
			out.Push(item)
		}
	}
	return out
}

Bitwarden_ParseFields(ByRef Base, ByRef Entry)
{
	for _,field in Entry.fields
	{
		if (field.name = INI.ADVANCED.field)
			Base.field := field.value
		else if (field.name = "tcato")
			Base.TCATO := field.value
	}
}

Bitwarden_Status()
{
	out := Bitwarden("status")
	if (ErrorLevel)
	{
		Alert(0x10, out)
		Exit
	}
	BwStatus := JSON.Load(out)
	lastSync := RegExReplace(BwStatus.lastSync, "\D|.{4}$")
	epoch := Epoch(lastSync) + Epoch(A_Now) - Epoch()
	if (A_IsCompiled)
		FileGetVersion version, % A_ScriptFullPath
	else
		FileRead version, % A_ScriptDir "\version"
	Menu Tray, Tip, % AppTitle " v" version "`n"
		. Epoch_Date(epoch, "'Last Sync:' MM/dd/yy h:mm tt")
}

Bitwarden_Sync(showTip := true)
{
	if (!IsLogged || IsLocked)
		return
	Menu Tray, Icon, shell32.dll, 239
	Bitwarden("sync")
	Bitwarden_Status()
	Bitwarden_Data()
	if (showTip)
		Tip("Sync complete")
}

Bitwarden_SyncAuto(Interval)
{
	static fObject := ""
	if IsObject(fObject)
	{
		SetTimer % fObject, Delete
		fObject := ""
	}
	milliseconds := 1000 * 60 * Interval
	if (!milliseconds)
		return
	fObject := Func("Bitwarden_Sync").Bind(false)
	SetTimer % fObject, % milliseconds
}
