#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
; #Warn  ; Enable warnings to assist with detecting common errors.
SetKeyDelay, -1 ; No key delay
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent Starting directory.

class CodeRunner
{
    __New(prefix := ">>", endKey := "Enter")
    {
        this.isRun := False
        this.endKey := endKey
        this.prefix := prefix
        this.enableGui := True
        this.alias := {}
        this.history := []
        this.historyIndex := 0
        if FileExist("config.ini")
            this.LoadCfg()
    }

    __Set(key, Value)
    {
        if (key == "prefix")
        {
            if this.isRun
            {
                this.Stop()
                ObjRawSet(this, key, Value)
                this.Start()
            }
            Else
                ObjRawSet(this, key, Value)
        }
        Else
            ObjRawSet(this, key, Value)
    }

    LoadCfg()
    {
        settings := {"endkey":"endKey","prefix":"prefix","enablegui":"enableGui"}
        Loop, Read, config.ini
        {
            StringLower, command, A_LoopReadLine
            ; delete comment
            if InStr(command, ";")
                command := SubStr(command, 1, InStr(command, ";") - 1)
            ; parse settings
            if (InStr(command, "set ") == 1)
            {
                command := SubStr(command, 5)
                ; parse name
                RegExMatch(command, "\s*[_a-zA-Z][_a-zA-Z0-9]*", alias)
                command := SubStr(command, StrLen(alias)+1)
                ; delete spaces
                alias := StrReplace(alias, A_Space)
                ; parse value
                RegExMatch(command, "\s*=\s*", assign)
                command := SubStr(command, StrLen(assign)+1)
                ; remove spaces from the beginning and end
                command := Trim(command)
                if (settings.HasKey(alias))
                    this[settings[alias]] := command
            }
            else if (InStr(command, "alias ") == 1)
            {
                command := SubStr(command, 7)
                RegExMatch(command, "\s*[_a-zA-Z][_a-zA-Z0-9]*", alias)
                command := SubStr(command, StrLen(alias)+1)
                alias := StrReplace(alias, A_Space)
                RegExMatch(command, "\s*=\s*", assign)
                command := SubStr(command, StrLen(assign)+1)
                command := Trim(command)
                this.alias[alias] := command
            }
        }
    }

    UpdateCmdHistory(command)
    {
        ; Max to 5 cmd history
        if (this.history.MaxIndex() > 5)
            this.history.RemoveAt(5)
        this.history.InsertAt(1, command)
        this.historyIndex := 1
    }

    GetInput()
    {
        ; get input and exec it
        endKey := this.endKey
        Input, command, V, {%endKey%}
        len = StrLen(command) + StrLen(this.prefix) + 1
        SendInput, {backspace %len%}
        this.Exec(command)
    }

    PreprocessCommand(command, isGui := False)
    {
        otc := ""

        ; replace alias to command
        RegExMatch(command, "[_a-zA-Z][_a-zA-Z0-9]*", alias)
        if this.alias.HasKey(alias)
            command := StrReplace(command, alias, this.alias[alias])

        ; replace %var to var
        ; and add outputcommand to the end of command
        ; to make a better output
        ; as "var: value"
        While (RegExMatch(command, "%\s*[_a-zA-Z][_a-zA-Z0-9]*", outputCommand))
        {
            otc .= Format("""{1:s}: "" {1:s} ", trim(SubStr(outputCommand,2)))
            command := StrReplace(command, outputCommand, trim(SubStr(outputCommand,2)))
        }
        
        ; use different command to fit different output enviorment
        if isGui
        {
            rc = 
            (LTrim
        
            VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)
            StringToSend := %otc%
            SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
            NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)
            NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)
            DetectHiddenWindows On
            SetTitleMatchMode 2
            )
            command .= rc
            command .= Format("`nSendMessage, 0x4a, 0, &CopyDataStruct,, ahk_id{1:s}", Inputbar.inputbarhwnd)
        }
        else if otc
            command .= Format("`nSendInput, {1:s}", otc)
        return command
    }

    Exec(command, isGui := False)
    {
        if (command == "")
            return "Empty Command"
        
        this.UpdateCmdHistory(command)
        command := this.PreprocessCommand(command, isGui)
        
        codeFile := FileOpen("tempCode.ahk", "w")
        codeFile.Write(command)
        codeFile.Close()

        Try
        {
            RunWait AutoHotkey.exe tempCode.ahk
        }
        Catch, exception
        {
            SendInput, % "Error on line " exception.Line ": " exception.Message
            return False
        }

        return True
    }

    Start()
    {
        this.__New()
        prefix := ":XZb0:" this.prefix
        eFunc := ObjBindMethod(this, "GetInput")
        Hotstring(prefix, eFunc)
        this.isRun := True
        if this.enableGui
            InputBar.InitInputBar()
    }

    Stop()
    {
        prefix := ":XZb0:"
        prefix .= this.prefix
        eFunc := ObjBindMethod(this, "GetInput")
        Hotstring(prefix, eFunc, off)
        this.isRun := False
    }
    
}
    
    /* 
    GUI Function
    From here
    */
class InputBar
{
	InitInputBar(Width := 800, editX := 4, editY := 4, trans := 200, mainColor := 808080, editBackgroundColor := 404040)
    {
		this.InitGui(Width, editX, editY, trans, mainColor, editBackgroundColor)
		this.HotKeyRegister()
        rm := ObjBindMethod(this, "ResultMonitor")
        this.name := OnMessage(0x4a, rm)
	}
	
	InitGui(Width, editX, editY, trans, mainColor, editBackgroundColor)
    {
		editW := Width - editX*2
		editH := 41 - editY*2 -2
		Gui, +LastFound +ToolWindow HwndInputBarhwnd
		WinSet, Transparent, %trans%
		Gui, Color, %mainColor%
		Gui, Margin, 0, 0
		Gui, Add, Progress, % "x-1 y-1 w" Width+10 " h41 Background" editBackgroundColor " Disabled hwndPROGhwnd"
		Control, ExStyle, -0x20000, , ahk_id %PROGhwnd% ; propably only needed on Win XP
		; Gui, Add, Text, % "x0 y0 w" Width " h30 BackgroundTrans Center 0x200 gGuiMove vCaption", Example
		Gui, Font, s20 c000000 Bold
		Gui, Font, Consolas
        Gui, Font, Fira Code 
		Gui, Add, Edit, x%editX% y%editY% w%editW% h%editH% BackgroundTrans -Multi -Border -WantReturn -WantTab HwndeditHwnd,
		Gui, Font, s11 cFFFFFF Bold
		Gui, Font, s12
		Gui, Add, Text, % "x7 y+10 w" (Width-14) "r1 +0x4000 HwndhTX1", ;> ; George Harrison
		; Gui, Add, Text, % "x7 y+10 w" (Width-14) "r1 +0x4000 vTX5 gClose", Close
		Gui, Add, Text, % "x7 y+10 w" (Width-14) "h5 hwndPhwnd"
		GuiControlGet, P, Pos,
		H1 := PY
		H := 88
		W := Width + 1000
		Gui, -Caption
		WinSet, Region, 0-0 w%W% h%H% r6-6
		Gui, Show, Hide Center w%Width%, InputBar
		WinSet AlwaysOnTop
		WinActivate
		this.inputBarHwnd := InputBarhwnd
		this.editHwnd := editHwnd
		this.rTextHwnd := hTX1
        ; Hint Word
        DllCall("SendMessage", "Ptr", editHwnd, "Uint", 0x1501, "Ptr", 1, "Str", "Hello, AHK")
	}
	
	HotKeyRegister()
    {
		inputBarHwnd := this.inputBarHwnd
		TS := ObjBindMethod(this, "ToggleShow")
		EE := ObjBindMethod(this, "EnterEvent")
        UE := ObjBindMethod(this, "UpkeyEvent")
        DE := ObjBindMethod(this, "DownkeyEvent")
		Hotkey, !w, %TS%
		
		Hotkey, IfWinActive, % "ahk_id" . inputBarHwnd
		Hotkey, Enter, %EE%
        ; up and down for cmd history
        Hotkey, Up, %UE%
        Hotkey, Down, %DE%
		Hotkey, If
		return
	}

    ResultMonitor(wParam, lParam)
    {
        rTextHwnd := this.rTextHwnd
		StringAddress := NumGet(lParam + 2*A_PtrSize)  ; 获取 CopyDataStruct 的 lpData 成员.
        CopyOfData := StrGet(StringAddress)  ; 从结构中复制字符串.
        ; 比起 MsgBox, 应该用 ToolTip 显示, 这样我们可以及时返回:
        ; ToolTip %A_ScriptName%`nReceived the following string:`n%CopyOfData%
        ControlSetText, ,% "> " CopyOfData, ahk_id %rTextHwnd% 
        return true  ; 返回 1 (true) 是回复此消息的传统方式.
    }
		
	ToggleShow()
    {
		inputBarHwnd := this.inputBarHwnd
        rTextHwnd := this.rTextHwnd
		editHwnd := this.editHwnd
		if WinActive("ahk_id" . inputBarHwnd)
			Gui, Cancel
		else
		{
            Gui, Show, Center, ahk_id %inputBarHwnd%
            ; clear all text in Gui
            ControlSetText, , , ahk_id %editHwnd%
            ControlSetText, , , ahk_id %rTextHwnd%
        }
	}
	
	EnterEvent()
    {
		rTextHwnd := this.rTextHwnd
		editHwnd := this.editHwnd
		;MsgBox, % "editHwnd: " editHwnd
		ControlGetText, eText, , ahk_id %editHwnd%
		;MsgBox, % eText
        result := CodeRunner.Exec(eText, True)
	}

    UpkeyEvent()
    {
        editHwnd := this.editHwnd
        ; MsgBox, % this.historyIndex
        if (CodeRunner.historyIndex >= CodeRunner.history.MaxIndex())
            return
        CodeRunner.historyIndex += 1
        ; MsgBox, % CodeRunner.history[CodeRunner.historyIndex]
        ControlSetText, ,% CodeRunner.history[CodeRunner.historyIndex], ahk_id %editHwnd%
    }

    DownkeyEvent()
    {
        editHwnd := this.editHwnd
        if (CodeRunner.historyIndex <= 1)
            return
        CodeRunner.historyIndex -= 1
        ControlSetText, ,% CodeRunner.history[CodeRunner.historyIndex], ahk_id %editHwnd%
    }
}

CodeRunner.Start()