class Line {

	static sourceLine := ""
	static lineNumber := 0
	static comment := ""
	static tabSize := 4

	addLine(sourceLine, lineNumber) {
		lineWithExpandedTabs := Line.expandTabs(sourceLine)
		Line.sourceLine := Line.stripComment(lineWithExpandedTabs)
		Line.lineNumber := lineNumber
		Statement.addLine(Line.sourceLine, Line.lineNumber)
	}

	expandTabs(sourceLine) {
		return RegExReplace(sourceLine, "\t", " ".repeat(Line.tabSize))
	}

	stripComment(sourceLine) {
		stringWithMaskedQuotes := Line.maskQuotedText(sourceLine)
		sourceLineWithoutComment := (stringWithMaskedQuotes
				, "\s*?`;(.*$)", "", $)
		Line.comment := $1
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
	}

	checkLineForTrailingSpaces() {
		if (pos := RegExMatch(Line.sourceLine, "\s+$") > 0) {
			writeWarning(Line.lineNumber "." pos, Message.text["W001"])
		}
	}

	checkLineTooLong() {
		lineLength := StrLen(Line.sourceLine)
		if (lineLength > 80) {
			writeWarning(Line.lineNumber "." lineLength, Message.text["W002"])
		}
	}
}
