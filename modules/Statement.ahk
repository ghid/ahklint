class Statement extends Line {

	static lineNumber := 0
	static lines := []
	static tabSize := 4

	addLine(sourceLine, lineNumber) {
		lineWithOutComments := Statement.stripComment(sourceLine)
		if (this.lines.maxIndex() == "") {
			Statement.lineNumber := lineNumber
		}
		if (Statement.isContiousLine(lineWithOutComments)) {
			this.lines.push(lineWithOutComments)
		} else {
			Statement.check()
			Statement.lineNumber := lineNumber
			this.lines := [lineWithOutComments]
		}
	}

	isContiousLine(sourceLine) {
		if RegExMatch(sourceLine, "^\s*[-,.+*/?:=!<>|&^~{]|\b(and|or|not).+") {
			return true
		}
		return false
	}

	check() {
		Statement.checkInnerIndentation()
		Statement.checkTrueBrace()
	}

	checkInnerIndentation() {
		numberOfMisindentedLines := 0
		if (Statement.lines.maxIndex() > 1) {
			RegExMatch(Statement.lines[1], "^(?P<FirstLine>\s*?)\S.*"
					, indentationOf)
			loop % Statement.lines.maxIndex() - 1 {
				RegExMatch(Statement.lines[A_Index + 1]
						, "^(?P<FurtherLine>\s*?)(\S.*|$)", indentationOf)
				if (indentationOfFurtherLine != indentationOfFirstLine
						. " ".repeat(Statement.tabSize * 2)) {
					writeWarning(Statement.lineNumber + A_Index
							. "." StrLen(indentationOfFurtherLine)
							, Message.text["W003"])
					numberOfMisindentedLines++
				}
			}
		}
		return numberOfMisindentedLines == 0
	}

	checkTrueBrace() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine
				, "i)\s*(\}\s*)?\b(if|while|loop|for|else|try|catch|finally)"
				, $)) {
			if (!RegExMatch(sourceLine, "\{\s*?$")) {
				writeWarning(Statement.lineNumber ".0", Message.text["W004"])
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
