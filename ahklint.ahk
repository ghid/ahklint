; ahk: console
#NoEnv
ListLines Off
SetBatchLines -1

#Include <ansi>
#Include <string>

#Include %A_LineFile%\..\modules\Line.ahk
#Include %A_LineFile%\..\modules\Statement.ahk
#Include %A_LineFile%\..\modules\Message.ahk

class Options {

	static tabSize := 4
	static rulesToIgnore := {}

}

Main:
	try {
		f := Ansi.stdIn
		while (!f.atEOF) {
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
	static rulesToIgnoreBlock := ""
	if (!InStr(sourceLine, "ahklint-") && rulesToIgnoreBlock == "") {
		return
	}
	maskedSourceLine := Line.maskQuotedText(sourceLine)
	if (RegExMatch(maskedSourceLine
			, "\s*`;.*?ahklint-ignore:\s*(?P<ToIgnore>([IWE]\d{3}(,|\s|$))*)"
			, rules)) {
		Options.rulesToIgnore[lineNumber] := rulesToIgnore
	}
	if (RegExMatch(maskedSourceLine
			, "\s*`;.*?ahklint-ignore-begin:\s*"
			. "(?P<ToIgnore>([IWE]\d{3}(,|\s|$))*)"
			, rules)) {
		rulesToIgnoreBlock := rulesToIgnore
	}
	if (RegExMatch(maskedSourceLine, "\s*`;.*?ahklint-ignore-end")) {
		rulesToIgnoreBlock := ""
	}
	if (rulesToIgnoreBlock != "") {
		Options.rulesToIgnore[lineNumber] := rulesToIgnoreBlock
	}
}

isTheMessageToBeIgnored(messageId, lineNumber) {
	return RegExMatch(Options.rulesToIgnore[lineNumber]
			, "(^|,)" messageId "(,|$)")
}

writeWarning(lineNumber, columnNumber, messageId) {
	severityLevel := SubStr(messageId, 1, 1) == "W"
			? "warning" : SubStr(messageId, 1, 1) == "I"
			? "info"
			: "error"
	if (!isTheMessageToBeIgnored(messageId, lineNumber)) {
		Ansi.stdErr.writeLine(lineNumber "." columnNumber ": "
				. severityLevel ": " Message.text[messageId])
	}
}
