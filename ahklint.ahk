; ahk: console
#NoEnv

#Include <ansi\ansi>
#Include <string\string>

#Include %A_LineFile%\..\modules\Line.ahk
#Include %A_LineFile%\..\modules\Statement.ahk
#Include %A_LineFile%\..\modules\Message.ahk

opts := { tabSize: 4 }

Main:
	Ansi.NO_BUFFER := true
	try {
		f := Ansi.stdIn
		while (!f.AtEOF) {
			Line.addLine(RegExReplace(f.readLine(), "[`r`n]+$", ""), A_Index)
			Line.check()
		}
	} catch ex {
		Ansi.stdErr.writeLine(ex.message)
	} finally {
		Ansi.flush()
		f.close()
	}
exitapp

writeWarning(lineNumber, messageText) {
	Ansi.stdErr.writeLine(lineNumber ": warning: " messageText)
}
