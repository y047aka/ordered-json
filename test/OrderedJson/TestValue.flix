pub mod OrderedJson.TestValue {

    use Assert.assertEq;
    use OrderedJson.render
    use OrderedJson.Json.{JNull, JBool, JInt, JFloat, JString, JArray, JObject}

    @Test
    def testRenderNull(): Unit \ Assert =
        assertEq(expected = "null", render(JNull))

    @Test
    def testRenderBoolTrue(): Unit \ Assert =
        assertEq(expected = "true", render(JBool(true)))

    @Test
    def testRenderBoolFalse(): Unit \ Assert =
        assertEq(expected = "false", render(JBool(false)))

    @Test
    def testRenderInt(): Unit \ Assert =
        assertEq(expected = "42", render(JInt(42)))

    /// A `Float64` stays the 17 digits `Double.toString` gives, and does not become the 55-digit decimal a `BigDecimal` widens it to.
    @Test
    def testRenderFloatKeepsTheFlixSpelling(): Unit \ Assert =
        assertEq(expected = "0.20739060549440685", render(JFloat(0.20739060549440685)))

    @Test
    def testRenderString(): Unit \ Assert =
        assertEq(expected = "\"hello\"", render(JString("hello")))

    @Test
    def testRenderStringWithQuotes(): Unit \ Assert =
        let result = render(JString("say \"hi\""));
        Assert.assertTrue(String.contains({substr = "\\\""}, result))

    /// A raw control character is not a JSON string character, so a name holding one is a file no browser parses.
    @Test
    def testRenderStringEscapesControlCharacters(): Unit \ Assert =
        let backspace = Char.toString('\u0008');
        let formfeed  = Char.toString('\u000c');
        assertEq(expected = "\"a\\bb\\fc\"", render(JString("a${backspace}b${formfeed}c")))

    @Test
    def testRenderEmptyArray(): Unit \ Assert =
        assertEq(expected = "[]", render(JArray(Vector#{})))

    @Test
    def testRenderEmptyObject(): Unit \ Assert =
        assertEq(expected = "{}", render(JObject(Nil)))

    @Test
    def testRenderObject(): Unit \ Assert =
        let obj = JObject(("name", JString("test")) :: ("value", JInt(1)) :: Nil);
        assertEq(expected = "{\n  \"name\": \"test\",\n  \"value\": 1\n}", render(obj))

    /// A sorted `JObject` would put `driverName` second, and no other test here says which of the two orders is owed to the caller.
    @Test
    def testPropertyOrderIsTheAuthoredOrder(): Unit \ Assert =
        let lap = JObject(
            ("carNumber", JString("007")) ::
            ("lapNumber", JInt(1)) ::
            ("driverName", JString("Tom GAMBLE")) ::
            Nil
        );
        assertEq(expected = List.join("\n",
            "[" ::
            "  {" ::
            "    \"carNumber\": \"007\"," ::
            "    \"lapNumber\": 1," ::
            "    \"driverName\": \"Tom GAMBLE\"" ::
            "  }" ::
            "]" :: Nil
        ), render(JArray(Vector#{lap})))

    @Test
    def testRenderArray(): Unit \ Assert =
        let arr = JArray(Vector#{JInt(1), JInt(2)});
        assertEq(expected = "[\n  1,\n  2\n]", render(arr))

}
