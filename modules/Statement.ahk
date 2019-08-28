class Statement extends Line {

	static lineNumber := 0
	static lines := []

	addLine(sourceLine, lineNumber) {
		if (Statement.lines.maxIndex() == "") {
			Statement.lineNumber := lineNumber
		}
		if (Statement.isContiousLine(sourceLine)) {
			Statement.lines.push(sourceLine)
		} else {
			Statement.check()
			Statement.lineNumber := lineNumber
			Statement.lines := [sourceLine]
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
		Statement.checkOptionalArguments()
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

	checkOptionalArguments() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine, "i)^\s*[a-z0-9_$#@]+\(.+?\)\s+\{")) {
			at := 1
			loop {
				at := RegExMatch(sourceLine, "(\s+=)|(=\s+)"
						, assignmentWithSpaces, at)
				if (at > 0) {
					writeWarning(Statement.lineNumber, at, "W006")
					at += StrLen(assignmentWithSpaces)
				}
			} until (at == 0)
		}
	}

	toString() {
		statementAsString := ""
		loop % Statement.lines.maxIndex() {
			statementAsString .= Statement.lines[A_Index]
		}
		return statementAsString
	}
}
