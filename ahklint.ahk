; ahk: console
#NoEnv

#Include <ansi\ansi>
#Include <string\string>

#Include %A_LineFile%\..\modules\Line.ahk
#Include %A_LineFile%\..\modules\Statement.ahk
#Include %A_LineFile%\..\modules\Message.ahk

class Options {

	static tabSize := 4
	static rulesToIgnore := {}
}

Main:
	Ansi.NO_BUFFER := true
	try {
		f := Ansi.stdIn
		while (!f.AtEOF) {
			sourceLine := RegExReplace(f.readLine(), "[`r`n]+$", "")
			if (!isWithinCommentBlock(sourceLine)) {
				Line.addLine(sourceLine, A_Index)
			}
			handleIgnoreDirectives(sourceLine, A_Index)
		}
	} catch ex {
		Ansi.stdErr.writeLine(ex.message)
	} finally {
		Line.check()
		Statement.check()
		Ansi.flush()
		f.close()
	}
exitapp

isWithinCommentBlock(sourceLine) {
	static commentBlock := false

	if (RegExMatch(sourceLine, "^\s*\*/")) {
		commentBlock := false
		return true
	} else if (RegExMatch(sourceLine, "^\s*/\*")) {
		commentBlock := true
	}
	return commentBlock
}

handleIgnoreDirectives(sourceLine, lineNumber) {
	if (RegExMatch(sourceLine
			, "\s*`;.*?ahklint-ignore:\s*(?P<ToIgnore>([IWE]\d{3}(,|\s|$))*)"
			, rules)) {
		Options.rulesToIgnore[lineNumber] := rulesToIgnore
	}
}

isTheMessageToBeIgnored(messageId, lineNumber) {
	return RegExMatch(Options.rulesToIgnore[lineNumber]
			, "(^|,)" messageId "(,|$)")
}

writeWarning(lineNumber, columnNumber, messageId) {
	if (isTheMessageToBeIgnored(messageId, lineNumber)) {
		OutputDebug % "Ignore: " Line.sourceLine
	} else {
		Ansi.stdErr.writeLine(lineNumber "." columnNumber
				. ": warning: " Message.text[messageId])
	}
}
