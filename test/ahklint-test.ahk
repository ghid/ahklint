; ahk: console
#NoEnv

#Include <testcase\testcase>
#Include <flimsydata\flimsydata>

class AHKLintTest extends TestCase {

	@Before_redirectStdErr() {
		Ansi.stdErr := FileOpen(A_Temp "\ahklint-test.err", "w")
	}

	@After_removeErrFile() {
		Ansi.stdErr.close()
		FileDelete %A_Temp%\ahklint-test.err
	}

	@Before_resetData() {
		Line.sourceLine := ""
		Line.lineNumber := 0
		Line.comment := ""
		Options.rulesToIgnore := {}
	}

	@Test_saveQuotedText() {
		this.assertEquals(Line
				.maskQuotedText("    xx (xx != ""xx xx"") {")
				, "    xx (xx != @@@@@@@) {")
		this.assertEquals(Line
				.maskQuotedText("    xx (xx != ""xx xx"") || (x == ""xxx"") {")
				, "    xx (xx != @@@@@@@) || (x == @@@@@) {")
		this.assertEquals(Line
				.maskQuotedText("    xx (xx >= 42) && (x != 0) {")
				, "    xx (xx >= 42) && (x != 0) {")
	}

	@Test_stripComment() {
		this.assertEquals(Line
				.stripComment("    xx (xx != ""xx xx `; x xxxxxxxxx"") {")
				, "    xx (xx != @@@@@@@@@@@@@@@@@@@@@) {")
		this.assertEquals(Line
				.stripComment("    xx (xx != ""xx xx"") { `; x xxxxxxxxx")
				, "    xx (xx != @@@@@@@) {")
	}

	@Test_isContinousLine() {
		this.assertTrue(Statement.isContiousLine("   , A_Index"))
		this.assertFalse(Statement.isContiousLine("   index := 42"))
	}

	@Test_expandTabs() {
		this.assertEquals(Line.expandTabs("`tx := 1"), "    x := 1")
		this.assertEquals(Line.expandTabs("`t`ty`t:= 2"), "        y    := 2")
	}

	@Test_isTheMessageToBeIgnored() {
		handleIgnoreDirectives("`; ahklint-ignore: W001,W002,W004", 1)
		handleIgnoreDirectives("`; ahklint-ignore: W005", 2)
		this.assertEquals(Options.rulesToIgnore[1], "W001,W002,W004")
		this.assertTrue(isTheMessageToBeIgnored("W001", 1))
		this.assertTrue(isTheMessageToBeIgnored("W002", 1))
		this.assertFalse(isTheMessageToBeIgnored("W003", 1))
		this.assertTrue(isTheMessageToBeIgnored("W004", 1))
		this.assertFalse(isTheMessageToBeIgnored("W000", 2))
		this.assertTrue(isTheMessageToBeIgnored("W005", 2))
		this.assertFalse(isTheMessageToBeIgnored("W000", 3))
	}

	@Test_checkLineForTrailingSpaces() {
		Line.addLine("    x := 1 ", 1)
		Line.addLine(" ", 2)
		Line.addLine("", 3)
		Line.addLine("    y := ""Test""", 4)
		Line.check()
		Ansi.flush()
		this.assertEquals(this.fileContent(A_Temp "\ahklint-test.err")
				, "1.11: warning: " Message.text["W001"] "`n"
				. "2.1: warning: " Message.text["W001"] "`n")
	}

	@Test_checkNotEqualSymbol() {
		Line.addLine("    if (x != 0) {", 1)
		Line.addLine("    if (x != 0 && y <> 1) {", 11)
		Line.addLine("    if (x <> 0 && y != 1) {", 21)
		Line.addLine("    if (x <> 0 && y <> 1) {", 31)
		Line.check()
		Ansi.flush()
		this.assertEquals(this.fileContent(A_Temp "\ahklint-test.err")
				, "11.21: warning: " Message.text["W005"] "`n"
				. "21.11: warning: " Message.text["W005"] "`n"
				. "31.11: warning: " Message.text["W005"] "`n"
				. "31.21: warning: " Message.text["W005"] "`n")
	}

	@Test_checkLineTooLong() {
		fd := new FlimsyData.Simple(1300)
		Line.addLine("    x := 1", 1)
		Line.addLine(fd.getMixedString(80, 80), 2)
		Line.addLine(fd.getMixedString(81, 100), 3)
		Line.addLine(fd.getMixedString(80, 80) " `; foo bar", 4)
		Line.addLine("   x := 0")
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "3.97: warning: " Message.text["W002"] "`n")
	}

	@Test_checkIndentOfSplittedLines() {
		Line.addLine("    if (x == 0", 1)
		Line.addLine("    && y == 0) {", 2)
		Line.addLine("        x++", 3)
		Line.addLine("    }", 4)
		Line.addLine("    if (x == 0", 11)
		Line.addLine("        && y == 0) {", 12)
		Line.addLine("        x++", 13)
		Line.addLine("    }", 14)
		Line.addLine("    if (x == 0", 21)
		Line.addLine("            && y == 0) {", 22)
		Line.addLine("        x++", 23)
		Line.addLine("    }", 24)
		Line.addLine("    if (x == 0", 31)
		Line.addLine("                && y == 0) {", 32)
		Line.addLine("        x++", 33)
		Line.addLine("    }", 34)
		Line.addLine("    if (x == 0", 41)
		Line.addLine("           && y == 0) {", 42)
		Line.addLine("        x++", 43)
		Line.addLine("    }", 44)
		Statement.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "2.4: warning: " Message.text["W003"] "`n"
				. "12.8: warning: " Message.text["W003"] "`n"
				. "32.16: warning: " Message.text["W003"] "`n"
				. "42.11: warning: " Message.text["W003"] "`n")
	}

	@Test_checkOpeningTrueBrace() {
		Line.addLine("    if (x == 0) {", 1)
		Line.addLine("        x++", 2)
		Line.addLine("    }", 3)
		Line.addLine("    if (x == 0)", 11)
		Line.addLine("        x++", 12)
		Line.addLine("    if (x == 0)", 21)
		Line.addLine("    {", 22)
		Line.addLine("        x++", 23)
		Line.addLine("    }", 24)
		Statement.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "11.15: warning: " Message.text["W004"] "`n")
	}

	@Test_checkOpeningTrueBraceWithTabs() {
		Line.addLine("	if (x == 0) {", 1)
		Line.addLine("		x++", 2)
		Line.addLine("	}", 3)
		Line.addLine("	if (x == 0)", 11)
		Line.addLine("		x++", 12)
		Line.addLine("	if (x == 0)", 21)
		Line.addLine("	{", 22)
		Line.addLine("		x++", 23)
		Line.addLine("	}", 24)
		Statement.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "11.13: warning: " Message.text["W004"] "`n")
	}

	@Test_traditionalStatements() {
		Line.addLine("    if x is integer", 1)
		Line.addLine("        x++", 2)
		Line.addLine("    if x not between 1 and 10", 11)
		Line.addLine("    {", 12)
		Line.addLine("        x++", 13)
		Line.addLine("    }", 14)
		Statement.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "1.19: warning: " Message.text["W004"] "`n")
	}

	@Test_ahklintIgnore() {
		Line.addLine("    if (extraOrdinaryFirstVariableName"
				. "WithALotOfCharacters <> extraOrdinarySecondVariableName"
				. "WithALotOfCharacters)", 1)
		handleIgnoreDirectives("`; ahklint-ignore: W002,W005,W004", 1)
		Line.addLine("        x++", 2)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err"), "")
	}

	@Test_checkOptionalArguments() {
		Line.addLine("    test(a = 1, b= 2, c =3, d=4) {", 1)
		Line.addLine("        a++", 2)
		Line.addLine("    }")
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "1.11: warning: " Message.text["W006"] "`n"
				. "1.18: warning: " Message.text["W006"] "`n"
				. "1.24: warning: " Message.text["W006"] "`n")
	}
}

exitapp AHKLintTest.runTests()

#Include %A_ScriptDir%\..\ahklint.ahk
