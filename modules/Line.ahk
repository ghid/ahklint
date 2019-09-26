class Line {

	static sourceLine := ""
	static lineNumber := 0

	addLine(sourceLine, lineNumber) {
		Line.check()
		Line.sourceLine := Line.stripComment(sourceLine)
		Line.lineNumber := lineNumber
		Statement.addLine(Line.sourceLine, Line.lineNumber)
	}

	expandTabs(sourceLine) {
		static tabs := ""
		if (tabs == "") {
			loop % Options.tabSize {
				tabs .= " "
			}
		}
		return StrReplace(sourceLine, A_Tab, tabs)
	}

	stripComment(sourceLine) {
		stringWithMaskedQuotes := Line.maskQuotedText(sourceLine)
		commentAt := RegExMatch(stringWithMaskedQuotes, "\s+?`;.*$")
		if (commentAt > 0) {
			sourceLineWithoutComment := SubStr(stringWithMaskedQuotes
					, 1, commentAt - 1)
		} else {
			sourceLineWithoutComment := stringWithMaskedQuotes
		}
		return sourceLineWithoutComment
	}

	maskQuotedText(sourceLine) {
		while (RegExMatch(sourceLine, "^(.*?)("".*?"")(.*)$", $)) {
			sourceLine := $1 "@".repeat(StrLen($2)) $3
		}
		return sourceLine
	}

	check() {
		Line.checkLineForTrailingSpaces()
		Line.checkLineTooLong()
		Line.checkNotEqualSymbol()
	}

	checkLineForTrailingSpaces() {
		if (SubStr(Line.sourceLine, 0) == " ") {
			at := RegExMatch(Line.sourceLine, "\s+$")
			writeMessage(Line.lineNumber, at, "W001")
		}
	}

	checkLineTooLong() {
		lineLength := StrLen(Line.sourceLine)
		if (StrLen(Line.sourceLine) > 80) {
			writeMessage(Line.lineNumber, lineLength, "W002")
			return
		}
		expandedLine := Line.expandTabs(Line.sourceLine)
		if (StrLen(expandedLine) > 80) {
			writeMessage(Line.lineNumber, lineLength, "W002")
		}
	}

	checkNotEqualSymbol() {
		loop {
			at := InStr(Line.sourceLine, "<>",,, A_Index)
			if (at > 0) {
				writeMessage(Line.lineNumber, at, "W005")
			}
		} until (at == 0)
	}
}
