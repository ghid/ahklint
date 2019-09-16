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
				, "^\s*([-,.+*\/?:=!<>|&^~{](?!\w+::))"
				. "|^\s*(\b(and|or|not)\b\s+)") {
			return true
		}
		return false
	}

	check() {
		Statement.checkUnnecessarySplitOfLine()
		Statement.checkIndentOfSplittedLines()
		Statement.checkOpeningTrueBrace()
		Statement.checkOptionalArguments()
		Statement.checkIfFirstCharOfFunctionIsLowerCase()
		Statement.checkIfFirstCharOfClassUpperCase()
		Statement.checkIfFirstCharOfMethodIsLowerCase()
	}

	checkIndentOfSplittedLines() {
		numberOfMisindentedLines := 0
		if (Statement.lines.maxIndex() > 1) {
			RegExMatch(Statement.lines[1], "^(?P<FirstLine>\s*?)\S.*"
					, indentationOf)
			loop % Statement.lines.maxIndex() - 1 {
				furtherIndent := "\t{2}|" " ".repeat(Options.tabSize * 2)
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

	checkUnnecessarySplitOfLine() {
		if (Statement.lines.maxIndex() > 1
				&& StrLen(Line.expandTabs(Statement.toString())) <= 80)	{
			if (!Statement.isLegacyStatement(Statement.lines[1])) {
				writeWarning(Statement.lineNumber
						, StrLen(Statement.lines[1])
						, "W010")
			}
		}
	}

	checkOpeningTrueBrace() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine
				, "i)\s*(\}\s*)?"
				. "[^#]\b(if|while|loop|for|else|try|catch|finally)\b"
				, $)) {
			if (!RegExMatch(sourceLine, "\{\s*?$")) {
				position := Statement.translatePosition(StrLen(sourceLine))
				writeWarning(position.lineNumber, position.columnNumber
						, "E001")
				return false
			}
		}
		return true
	}

	checkOptionalArguments() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine, "i)^\s*[a-z0-9_$#@]+\(.+?\)\s+\{")) {
			atColumn := 1
			loop {
				atColumn := RegExMatch(sourceLine, "(\s+=)|(=\s+)"
						, assignmentWithSpaces, atColumn)
				if (atColumn > 0) {
					position := Statement.translatePosition(atColumn)
					writeWarning(position.lineNumber, position.columnNumber
							, "W006")
					atColumn += StrLen(assignmentWithSpaces)
				}
			} until (atColumn == 0)
		}
	}

	checkIfFirstCharOfFunctionIsLowerCase() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine
				, "i)^(?P<Indent>\s*)(?P<FirstChar>[a-z0-9_$#@]).*?\(.*?\)\s+\{"
				, match)) {
			if (RegExMatch(matchFirstChar, "[A-Z]")) {
				position := Statement.translatePosition(StrLen(matchIndent) + 1)
				writeWarning(position.lineNumber, position.columnNumber, "W007")
			}
		}
	}

	checkIfFirstCharOfMethodIsLowerCase() {
		sourceLine := Statement.toString()
		lookAt := 1
		while (foundAt := RegExMatch(sourceLine
				, "(?P<Before>(?P<New>\b(new\s+).*?)?[\w\)]\.)[A-Z]"
				. "([a-z]+|[0-9_$#@]+[a-z]+)(?P<dot>\.?)"
				, match, lookAt)) {
			atColumn := foundAt + StrLen(matchBefore)
			lookAt := foundAt + StrLen(match)
			if (!matchNew && !matchDot) {
				position := Statement.translatePosition(atColumn)
				writeWarning(position.lineNumber, position.columnNumber, "W009")
			}
		}
	}

	checkIfFirstCharOfClassUpperCase() {
		sourceLine := Statement.toString()
		if (RegExMatch(sourceLine
				, "i)^(?P<Indent>\s*class\s+)"
				. "(?P<FirstChar>[a-z0-9_$#@]).*?\s+\{"
				, match)) {
			if (RegExMatch(matchFirstChar, "[a-z]")) {
				position := Statement.translatePosition(StrLen(matchIndent) + 1)
				writeWarning(position.lineNumber, position.columnNumber, "W008")
			}
		}
		if (RegExMatch(sourceLine
				, "i)^(?P<Indent>\s*class\s+.*?\s+extends\s+)"
				. "(?P<FirstChar>[a-z0-9_$#@]).*?\s+\{"
				, match)) {
			if (RegExMatch(matchFirstChar, "[a-z]")) {
				position := Statement.translatePosition(StrLen(matchIndent) + 1)
				writeWarning(position.lineNumber, position.columnNumber, "W008")
			}
		}
	}

	isLegacyStatement(sourceLine) {
		return RegExMatch(sourceLine
				, "i)^\s*"
				. "(If(Not)?(Equal)?"
				. "|IfLess(OrEqual)?"
				. "|IfGreater(OrEqual)?"
				. "|loop(\s+|,\s*)(files|parse|read|reg))"
				. "(\s+|,\s*)[^\(]")
	}

	toString() {
		statementAsString := ""
		loop % Statement.lines.maxIndex() {
			statementAsString .= Statement.lines[A_Index]
		}
		return statementAsString
	}

	translatePosition(columnNumber) {
		lineNumber := Statement.lineNumber
		while (columnNumber > StrLen(Statement.lines[A_Index])) {
			lineNumber++
			columnNumber -= StrLen(Statement.lines[A_Index])
		}
		return {lineNumber: lineNumber, columnNumber: columnNumber}
	}
}
