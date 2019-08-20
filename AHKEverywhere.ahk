#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent Starting directory.

class CodeRunner
{
    __New(prefix := ">>", endKey := "Enter")
    {
        this.isRun := False
        this.endKey := endKey
        this.prefix := prefix
        this.alias := {}
        if FileExist("config.ini")
            this.LoadCfg()
    }

    __Set(key, Value)
    {
        if (key == "prefix" && this.isRun == True)
        {
            this.Stop()
            ObjRawSet(this, key, Value)
            this.Start()
        }
        Else
            ObjRawSet(this, key, Value)
    }

    LoadCfg()
    {
        settings := {"endkey":"endKey","prefix":"prefix"}
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
                Loop, Parse, command, "", %A_Space%%A_Tab%
                    command := A_LoopField
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
                Loop, Parse, command, "", %A_Space%%A_Tab%
                    command := A_LoopField
                this.alias[alias] := command
            }
        }
    }

    Exec()
    {
        endKey := this.endKey
        Input, command, V, {%endKey%}
        len = StrLen(command) + StrLen(this.prefix) + 1
        SendInput, {backspace %len%}

        RegExMatch(command, "[_a-zA-Z][_a-zA-Z0-9]*", alias)
        if this.alias.HasKey(alias)
            command := StrReplace(command, alias, this.alias[alias])
        
        codeFile := FileOpen("tempCode.ahk", "w")
        codeFile.Write(command)
        codeFile.Close()
        Try
        {
            Run, tempcode.ahk,  , , cPID
        }
        Catch, exception
        {
            SendInput, % "Error on line " exception.Line ": " exception.Message
        }
        return cPID
    }

    Start()
    {
        prefix := ":XZb0:" this.prefix
        eFunc := ObjBindMethod(this, "Exec")
        Hotstring(prefix, eFunc)
        this.isRun := True
    }
}
