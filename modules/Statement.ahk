class Statement extends Line {

	static lineNumber := 0
	static lines := []
	static comment := ""

	addLine(sourceLine, lineNumber, comment) {
		if (Statement.lines.maxIndex() == "") {
			Statement.lineNumber := lineNumber
		}
		if (Statement.isContiousLine(sourceLine)) {
			Statement.lines.push(sourceLine)
		} else {
			Line.comment := Statement.comment
			Statement.check()
			Statement.lineNumber := lineNumber
			Statement.lines := [sourceLine]
			Statement.comment := comment
		}
	}

	isContiousLine(sourceLine) {
		if RegExMatch(sourceLine
				, "^\s*([-,.+*\/?:=!<>|&^~{])|^\s*(\b(and|or|not)\b)") {
			return true
		}
		return false
	}

	check() {
		Statement.checkIndentOfSplittedLines()
		Statement.checkOpeningTrueBrace()
	}

	checkIndentOfSplittedLines() {
		numberOfMisindentedLines := 0
		if (Statement.lines.maxIndex() > 1) {
			RegExMatch(Statement.lines[1], "^(?P<FirstLine>\s*?)\S.*"
					, indentationOf)
			loop % Statement.lines.maxIndex() - 1 {
				furtherIndent := " ".repeat(Options.tabSize * 2)
				RegExMatch(Statement.lines[A_Index + 1]
						, "^(?P<FurtherLine>\s*?\{?)(\S.*|$)", indentationOf)
				expectedIndentOrCurlyBrace := "^" indentationOfFirstLine
						. "(\{|" furtherIndent ")(\S|$)"
				if (!RegExMatch(indentationOfFurtherLine
						, expectedIndentOrCurlyBrace)) {
					writeWarning(Statement.lineNumber + A_Index
							, StrLen(indentationOfFurtherLine), "W003")
					numberOfMisindentedLines++
				}
			}
		}
		return numberOfMisindentedLines == 0
	}

	checkOpeningTrueBrace() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine
				, "i)\s*(\}\s*)?\b(if|while|loop|for|else|try|catch|finally)\b"
				, $)) {
			if (!RegExMatch(sourceLine, "\{\s*?$")) {
				writeWarning(Statement.lineNumber, StrLen(sourceLine)
						, "W004")
				return false
			}
		}
		return true
	}

	toString() {
		statementAsString := ""
		loop % Statement.lines.maxIndex() {
			statementAsString .= Statement.lines[A_Index]
		}
		return statementAsString
	}
}
