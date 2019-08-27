; ahk: console
#NoEnv

#Include <testcase\testcase>
#Include <flimsydata\flimsydata>

class AHKLintTest extends TestCase {

	/*
	@BeforeClass_redirectStdErr() {
		Ansi.stdErr := FileOpen(A_Temp "\ahklint-test.err", "w")
	}

	@AfterClass_removeErrFile() {
		Ansi.stdErr.close()
		FileDelete %A_Temp%\ahklint-test.err
	}
	*/

	@Test_saveQuotedText() {
		this.assertEquals(Statement
				.maskQuotedText("    xx (xx != ""xx xx"") {")
				, "    xx (xx != @@@@@@@) {")
		this.assertEquals(Statement
				.maskQuotedText("    xx (xx != ""xx xx"") || (x == ""xxx"") {")
				, "    xx (xx != @@@@@@@) || (x == @@@@@) {")
		this.assertEquals(Statement
				.maskQuotedText("    xx (xx >= 42) && (x != 0) {")
				, "    xx (xx >= 42) && (x != 0) {")
	}

	@Test_stripComment() {
		this.assertEquals(Statement
				.stripComment("    xx (xx != ""xx xx `; x xxxxxxxxx"") {")
				, "    xx (xx != @@@@@@@@@@@@@@@@@@@@@) {")
		this.assertEquals(Statement
				.stripComment("    xx (xx != ""xx xx"") { `; x xxxxxxxxx")
				, "    xx (xx != @@@@@@@) {")
	}

	@Test_isContinousLine() {
		this.assertTrue(Statement.isContiousLine("   , A_Index"))
		this.assertFalse(Statement.isContiousLine("   index := 42"))
	}

	@Test_longLineRule() {
		fd := new FlimsyData.Simple(1304)
		this.assertTrue(checkLineTooLong(fd.getMixedString(81), 42))
		this.assertFalse(checkLineTooLong(fd.getMixedString(80), 42))
		this.assertFalse(checkLineTooLong("", 42))
	}

	@Test_trailingSpacesRule() {
		this.assertTrue(checkLineForTrailingSpaces("   ", 42))
		this.assertFalse(checkLineForTrailingSpaces("  foo", 42))
		this.assertTrue(checkLineForTrailingSpaces("bar ", 42))
		this.assertFalse(checkLineForTrailingSpaces("", 42))
	}

	@Test_innerIndentationRule() {
		Statement.addLine("    i := 1", 1)
		this.assertEquals(Statement.lines.maxIndex(), 1)
		this.assertEquals(Statement.lineNumber, 1)
		this.assertEquals(Statement.lines[1], "    i := 1")
		Statement.addLine("    test := ""Start""", 2)
		Statement.addLine("            . ""Middle""", 3)
		Statement.addLine("            . ""End""", 4)
		this.assertEquals(Statement.lines.maxIndex(), 3)
		this.assertEquals(Statement.lineNumber, 2)
		this.assertEquals(Statement.lines[1], "    test := @@@@@@@")
		this.assertEquals(Statement.lines[2], "            . @@@@@@@@")
		this.assertEquals(Statement.lines[3], "            . @@@@@")
		Statement.addLine(A_Tab "x := y", 5)
	}
}

exitapp AHKLintTest.runTests()

#Include %A_ScriptDir%\..\ahklint.ahk
