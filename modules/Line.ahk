class Line {

	static sourceLine := ""
	static lineNumber := 0
	static comment := ""

	addLine(sourceLine, lineNumber) {
		Line.check()
		lineWithExpandedTabs := Line.expandTabs(sourceLine)
		Line.sourceLine := Line.stripComment(lineWithExpandedTabs)
		Line.lineNumber := lineNumber
		Statement.addLine(Line.sourceLine, Line.lineNumber, Line.comment)
	}

	expandTabs(sourceLine) {
		return RegExReplace(sourceLine, "\t", " ".repeat(Options.tabSize))
	}

	stripComment(sourceLine) {
		stringWithMaskedQuotes := Line.maskQuotedText(sourceLine)
		commentAt := RegExMatch(stringWithMaskedQuotes, "\s+?`;.*$")
		if (commentAt > 0) {
			Line.comment := SubStr(stringWithMaskedQuotes, commentAt)
			sourceLineWithoutComment := SubStr(stringWithMaskedQuotes
					, 1, commentAt - 1)
		} else {
			Line.comment := ""
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
		at := RegExMatch(Line.sourceLine, "\s+$")
		if (at > 0) {
			writeWarning(Line.lineNumber, at, "W001")
		}
	}

	checkLineTooLong() {
		lineLength := StrLen(Line.sourceLine)
		if (lineLength > 80) {
			writeWarning(Line.lineNumber, lineLength, "W002")
		}
	}

	checkNotEqualSymbol() {
		loop {
			at := InStr(Line.sourceLine, "<>",,, A_Index)
			if (at > 0) {
				writeWarning(Line.lineNumber, at, "W005")
			}
		} until (at == 0)
	}
}
