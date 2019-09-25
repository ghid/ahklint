; ahk: console
#NoEnv
SetBatchLines -1
ListLines Off

#Include <testcase-libs>
#Include <flimsydata>
#Include <random>

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
		Statement.lineNumber := 0
		Statement.lines := []
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
		this.assertFalse(Statement.isContiousLine("   ^a:: Send ^{Home}"))
	}

	@Test_expandTabs() {
		this.assertEquals(Line.expandTabs("`tx := 1"), "    x := 1")
		this.assertEquals(Line.expandTabs("`t`ty`t:= 2"), "        y    := 2")
	}

	@Test_isLegacyStatment() {
		; ahklint-ignore-begin: W002
		this.assertFalse(Statement.isLegacyStatement("    if (x == 1) {"))
		this.assertFalse(Statement.isLegacyStatement("    if (x == 1)"))
		this.assertFalse(Statement.isLegacyStatement("    loop x"))
		this.assertFalse(Statement.isLegacyStatement("    loop %x%"))
		this.assertTrue(Statement.isLegacyStatement("    If x = 1"))
		this.assertTrue(Statement.isLegacyStatement("    If x"))
		this.assertTrue(Statement.isLegacyStatement("    IfEqual x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    IfEqual, x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    IfNotEqual x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    IfLess x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    IfLessOrEqual, x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    IfGreater, x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    IfGreaterOrEqual x, 1"))
		this.assertTrue(Statement.isLegacyStatement("    If x between 1 and 5"))
		this.assertTrue(Statement.isLegacyStatement("    If x not between 1 and 5"))
		this.assertTrue(Statement.isLegacyStatement("    If x in 1,2,3,4,5"))
		this.assertTrue(Statement.isLegacyStatement("    If x not in 1,2,3,4,5"))
		this.assertTrue(Statement.isLegacyStatement("    If x contains 1,2"))
		this.assertTrue(Statement.isLegacyStatement("    If x not contains 1,2"))
		this.assertTrue(Statement.isLegacyStatement("    If x is integer"))
		this.assertTrue(Statement.isLegacyStatement("    If x is not integer"))
		this.assertTrue(Statement.isLegacyStatement("    loop Files, %mydir%"))
		this.assertTrue(Statement.isLegacyStatement("    loop, Files, %mydir%"))
		this.assertTrue(Statement.isLegacyStatement("    loop, Parse, content, A_Space"))
		this.assertTrue(Statement.isLegacyStatement("    Loop, read, C:\Docs\Address List.txt, C:\Docs\Family Addresses.txt"))
		this.assertTrue(Statement.isLegacyStatement("    Loop, Reg, HKEY_CURRENT_USER\Software\Microsoft\Windows, KVR"))
		; ahklint-ignore-end
	}

	@Test_isTheMessageToBeIgnored() {
		handleIgnoreDirectives("`; ahklint-ignore: W001,W002,E001", 1)
		handleIgnoreDirectives("`; ahklint-ignore: W005", 2)
		this.assertEquals(Options.rulesToIgnore[1], "W001,W002,E001")
		this.assertTrue(isTheMessageToBeIgnored("W001", 1))
		this.assertTrue(isTheMessageToBeIgnored("W002", 1))
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
		fd := new FlimsyData.simple(1300)
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

	@Test_checkLineTooLongWithTabs() {
		Line.addLine("				if (pTestName.MaxIndex() != "" && !SelectedTests.HasKey(_value)) {", 2) ; ahklint-ignore: W002
		Line.check()
		Ansi.flush()
		this.assertEquals("2.69: warning: " Message.text["W002"] "`n"
				, TestCase.fileContent(A_Temp "\ahklint-test.err"))
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
				, "1.14: info: " Message.text["I001"] "`n"
				. "2.4: warning: " Message.text["W003"] "`n"
				. "11.14: info: " Message.text["I001"] "`n"
				. "12.8: warning: " Message.text["W003"] "`n"
				. "21.14: info: " Message.text["I001"] "`n"
				. "31.14: info: " Message.text["I001"] "`n"
				. "32.16: warning: " Message.text["W003"] "`n"
				. "41.14: info: " Message.text["I001"] "`n"
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
		Line.addLine("    if (x == 0", 31)
		Line.addLine("            && y > 1)", 32)
		Line.addLine("        x++", 33)
		Line.addLine("    #If GetKeyState(""CapsLock"", ""P"") == 1", 34)
		Line.addLine("", 35)
		Statement.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "11.15: error: " Message.text["E001"] "`n"
				. "21.15: info: " Message.text["I001"] "`n"
				. "31.14: info: " Message.text["I001"] "`n"
				. "32.21: error: " Message.text["E001"] "`n")
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
		Line.addLine("  #If GetKeyState(""CapsLock"", ""P"") == 1", 25)
		Line.addLine("  {", 26)
		Statement.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "11.12: error: " Message.text["E001"] "`n"
				. "21.12: info: " Message.text["I001"] "`n")
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
				, "1.19: error: " Message.text["E001"] "`n")
	}

	@Test_ahklintIgnore() {
		Line.addLine("    if (extraOrdinaryFirstVariableName"
				. "WithALotOfCharacters <> extraOrdinarySecondVariableName"
				. "WithALotOfCharacters)", 1)
		handleIgnoreDirectives("`; ahklint-ignore: W002,W005,E001", 1)
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

	@Test_checkIndentationWithTabs() {
		Line.addLine("	if (RegExMatch(maskedSourceLine", 1)
		Line.addLine("			, ""\s*`;.*?ahklint-ignore:\s*(?P<ToIgnore>([IWE]\d{3}(,|\s|$))*)""", 2) ; ahklint-ignore: W002
		Line.addLine("			, rules)) {", 3)
		Line.addLine("		Options.rulesToIgnore[lineNumber] := rulesToIgnore", 4) ; ahklint-ignore: W002
		Line.addLine("	}", 5)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "")
	}

	@Test_ifFirstCharOfFunctionIsLowerCase() {
		Line.addLine("   ThisIsUpperCase() {", 1)
		Line.addLine("       return 0", 2)
		Line.addLine("   }", 3)
		Line.addLine("   thisIsLowerCase() {", 11)
		Line.addLine("       return 0", 12)
		Line.addLine("   }", 13)
		Line.addLine("   _ThisIsSpecial() {", 21)
		Line.addLine("       return 0", 22)
		Line.addLine("   }", 23)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "1.4: warning: " Message.text["W007"] "`n")
	}

	@Test_ifFirstCharOfClassIsUpperCase() {
		Line.addLine("   class Up {", 1)
		Line.addLine("       static x := 0", 2)
		Line.addLine("   }", 3)
		Line.addLine("   class down {", 11)
		Line.addLine("       static x := 0", 12)
		Line.addLine("   }", 13)
		Line.addLine("   class x extends y {", 21)
		Line.addLine("       static x := 0", 22)
		Line.addLine("   }", 23)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "11.10: warning: " Message.text["W008"] "`n"
				. "21.10: warning: " Message.text["W008"] "`n"
				. "21.20: warning: " Message.text["W008"] "`n")
	}

	@Test_ifFirstCharOfMethodIsLowerCase() {
		Line.addLine("    this.assertUquals(BitSet.WORD_MASK, 0xf)", 1)
		Line.addLine("    this.assertFrue(IsFunc(BitSet.WordIndex))", 2)
		Line.addLine("    this.assertFrue(IsFunc(BitSet.checkInvariants))", 3)
		Line.addLine("    this.assertFrue(IsFunc(BitSet.wordIndex))", 4)
		Line.addLine("    this.AssertFrue(IsFunc(BitSet.CheckInvariants))", 5)
		Line.addLine("    expr := ""\n(?P<number>\d+?):\s*""", 6)
		Line.addLine("    ComObjGet(""winmgmts:"").ExecQuery(""Select * from Win32_Service"")", 7) ; ahklint-ignore: W002
		Line.addLine("    op.add(new OptParser.Boolean())", 8)
		Line.addLine("    if (o.Test() == 0", 9)
		Line.addLine("            || (o.Test() > 10 && o.Test() < 50)", 10)
		Line.addLine("            || o.Test() < -10) {", 11)
		Line.addLine("    return Test.B1_INST_STME", 12)
		Line.addLine("    if (_rbhn & Console.Color.COLOR_HIGHLIGHT) {", 13)
		Line.addLine("", 14)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "2.35: warning: " Message.text["W009"] "`n"
				. "5.10: warning: " Message.text["W009"] "`n"
				. "5.35: warning: " Message.text["W009"] "`n"
				. "7.28: warning: " Message.text["W009"] "`n"
				. "9.11: warning: " Message.text["W009"] "`n"
				. "10.19: warning: " Message.text["W009"] "`n"
				. "10.36: warning: " Message.text["W009"] "`n"
				. "11.18: warning: " Message.text["W009"] "`n")
	}

	@Test_unnecessarySplit() {
		Line.addLine("    __new(x=1", 1)
		Line.addLine("            , y=0) {", 2)
		Line.addLine("        return x", 3)
		Line.addLine("    }", 4)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "1.13: info: " Message.text["I001"] "`n")
	}

	@Test_fixThis_20190829() {
		Line.addLine("FileAppend Test for %A_ScriptFullName%", 1)
		Line.addLine("		, %A_Temp%\SystemTest_File1.txt", 2)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err"), "")
	}

	@Test_fixThis_20190904() {
		Line.addLine("    and() {", 1)
		Line.addLine("        return 0", 2)
		Line.addLine("    }", 3)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err"), "")
	}

	@Test_fixThis_193CF11() {
		Line.addLine("						print(""#"" ++i "": "" cron_pattern "" "" cron_cmd "": """, 1) ; ahklint-ignore: W002
		Line.addLine("								. _ex.message)", 2)
		Line.addLine("						print("""")", 3)
		Line.check()
		Ansi.flush()
		this.assertEquals(TestCase.fileContent(A_Temp "\ahklint-test.err")
				, "")
	}
}

exitapp AHKLintTest.runTests()

#Include %A_ScriptDir%\..\ahklint.ahk
