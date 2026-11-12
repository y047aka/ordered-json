mod OrderedJson.TestJson {

    use Assert.assertEq;

    use OrderedJson.Json.{JArray, JBool, JNull, JFloat, JInt, JObject, JString}

    def num(n: Int32): OrderedJson.Json = JInt(n)

    /////////////////////////////////////////////////////////////////////////////
    // toCompactString — primitives                                            //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toCompactString01(): Unit \ Assert =
        assertEq(expected = "null", OrderedJson.toCompactString(JNull))

    @Test
    def toCompactString02(): Unit \ Assert =
        assertEq(expected = "true", OrderedJson.toCompactString(JBool(true)))

    @Test
    def toCompactString03(): Unit \ Assert =
        assertEq(expected = "false", OrderedJson.toCompactString(JBool(false)))

    @Test
    def toCompactString04(): Unit \ Assert =
        assertEq(expected = "0", OrderedJson.toCompactString(num(0)))

    @Test
    def toCompactString05(): Unit \ Assert =
        assertEq(expected = "42", OrderedJson.toCompactString(num(42)))

    @Test
    def toCompactString06(): Unit \ Assert =
        assertEq(expected = "-7", OrderedJson.toCompactString(num(-7)))

    @Test
    def toCompactString07(): Unit \ Assert =
        assertEq(expected = "3.14", OrderedJson.toCompactString(JFloat(3.14)))

    /////////////////////////////////////////////////////////////////////////////
    // toCompactString — strings (no escape needed)                            //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toCompactString08(): Unit \ Assert =
        assertEq(expected = "\"\"", OrderedJson.toCompactString(JString("")))

    @Test
    def toCompactString09(): Unit \ Assert =
        assertEq(expected = "\"hello\"", OrderedJson.toCompactString(JString("hello")))

    @Test
    def toCompactString10(): Unit \ Assert =
        assertEq(expected = "\" \"", OrderedJson.toCompactString(JString(" ")))

    @Test
    def toCompactString11(): Unit \ Assert =
        assertEq(expected = "\"/\"", OrderedJson.toCompactString(JString("/")))

    @Test
    def toCompactString12(): Unit \ Assert =
        assertEq(
            expected = "\"http://example.com/path\"",
            OrderedJson.toCompactString(JString("http://example.com/path"))
        )

    @Test
    def toCompactString13(): Unit \ Assert =
        assertEq(expected = "\"café\"", OrderedJson.toCompactString(JString("café")))

    /////////////////////////////////////////////////////////////////////////////
    // toCompactString — strings with escapes                                  //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toCompactString14(): Unit \ Assert =
        assertEq(expected = "\"\\\\\"", OrderedJson.toCompactString(JString("\\")))

    @Test
    def toCompactString15(): Unit \ Assert =
        assertEq(expected = "\"\\\"\"", OrderedJson.toCompactString(JString("\"")))

    @Test
    def toCompactString16(): Unit \ Assert =
        assertEq(expected = "\"\\b\"", OrderedJson.toCompactString(JString("\u0008")))

    @Test
    def toCompactString17(): Unit \ Assert =
        assertEq(expected = "\"\\t\"", OrderedJson.toCompactString(JString("\t")))

    @Test
    def toCompactString18(): Unit \ Assert =
        assertEq(expected = "\"\\n\"", OrderedJson.toCompactString(JString("\n")))

    @Test
    def toCompactString19(): Unit \ Assert =
        assertEq(expected = "\"\\f\"", OrderedJson.toCompactString(JString("\u000C")))

    @Test
    def toCompactString20(): Unit \ Assert =
        assertEq(expected = "\"\\r\"", OrderedJson.toCompactString(JString("\r")))

    @Test
    def toCompactString21(): Unit \ Assert =
        assertEq(expected = "\"\\u0000\"", OrderedJson.toCompactString(JString("\u0000")))

    @Test
    def toCompactString22(): Unit \ Assert =
        assertEq(expected = "\"\\u0001\"", OrderedJson.toCompactString(JString("\u0001")))

    @Test
    def toCompactString23(): Unit \ Assert =
        assertEq(expected = "\"\\u000b\"", OrderedJson.toCompactString(JString("\u000B")))

    @Test
    def toCompactString24(): Unit \ Assert =
        assertEq(expected = "\"\\u001f\"", OrderedJson.toCompactString(JString("\u001F")))

    @Test
    def toCompactString25(): Unit \ Assert =
        assertEq(expected = "\"a\\nb\\tc\"", OrderedJson.toCompactString(JString("a\nb\tc")))

    // High-BMP and non-BMP characters (code point >= 0x20) must pass through
    // unescaped, per RFC 8259. These exercise the >= U+8000 range, where a
    // signed reinterpretation of the UTF-16 code unit would go negative.

    @Test
    def toCompactStringHigh1(): Unit \ Assert =
        assertEq(expected = "\"耀\"", OrderedJson.toCompactString(JString("耀")))

    @Test
    def toCompactStringHigh2(): Unit \ Assert =
        assertEq(expected = "\"한\"", OrderedJson.toCompactString(JString("한")))

    @Test
    def toCompactStringHigh3(): Unit \ Assert =
        assertEq(expected = "\"￿\"", OrderedJson.toCompactString(JString("￿")))

    // Non-BMP character (emoji U+1F600) encoded as a surrogate pair.
    @Test
    def toCompactStringHigh4(): Unit \ Assert =
        assertEq(expected = "\"😀\"", OrderedJson.toCompactString(JString("😀")))

    /////////////////////////////////////////////////////////////////////////////
    // toCompactString — arrays                                                //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toCompactString26(): Unit \ Assert =
        assertEq(expected = "[]", OrderedJson.toCompactString(JArray(Vector#{})))

    @Test
    def toCompactString27(): Unit \ Assert =
        assertEq(expected = "[1]", OrderedJson.toCompactString(JArray(Vector#{num(1)})))

    @Test
    def toCompactString28(): Unit \ Assert =
        assertEq(
            expected = "[1,2,3]",
            OrderedJson.toCompactString(JArray(Vector#{num(1), num(2), num(3)}))
        )

    @Test
    def toCompactString29(): Unit \ Assert =
        assertEq(
            expected = "[[1],[2]]",
            OrderedJson.toCompactString(JArray(Vector#{JArray(Vector#{num(1)}), JArray(Vector#{num(2)})}))
        )

    @Test
    def toCompactString30(): Unit \ Assert =
        assertEq(
            expected = "[null,true,1,\"x\"]",
            OrderedJson.toCompactString(JArray(Vector#{JNull, JBool(true), num(1), JString("x")}))
        )

    /////////////////////////////////////////////////////////////////////////////
    // toCompactString — objects                                               //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toCompactString31(): Unit \ Assert =
        assertEq(expected = "{}", OrderedJson.toCompactString(JObject(Nil)))

    @Test
    def toCompactString32(): Unit \ Assert =
        assertEq(
            expected = "{\"a\":1}",
            OrderedJson.toCompactString(JObject(("a", num(1)) :: Nil))
        )

    @Test
    def toCompactString33(): Unit \ Assert =
        assertEq(
            expected = "{\"a\":1,\"b\":2,\"c\":3}",
            OrderedJson.toCompactString(JObject(("a", num(1)) :: ("b", num(2)) :: ("c", num(3)) :: Nil))
        )

    /////////////////////////////////////////////////////////////////////////////
    // toPrettyString — primitives (no layout effect)                          //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toPrettyString01(): Unit \ Assert =
        assertEq(expected = "null", OrderedJson.toPrettyString(2, JNull))

    @Test
    def toPrettyString02(): Unit \ Assert =
        assertEq(expected = "true", OrderedJson.toPrettyString(2, JBool(true)))

    @Test
    def toPrettyString03(): Unit \ Assert =
        assertEq(expected = "42", OrderedJson.toPrettyString(2, num(42)))

    @Test
    def toPrettyString04(): Unit \ Assert =
        assertEq(expected = "\"hello\"", OrderedJson.toPrettyString(2, JString("hello")))

    /////////////////////////////////////////////////////////////////////////////
    // toPrettyString — empty containers stay on one line                      //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toPrettyString05(): Unit \ Assert =
        assertEq(expected = "[]", OrderedJson.toPrettyString(2, JArray(Vector#{})))

    @Test
    def toPrettyString06(): Unit \ Assert =
        assertEq(expected = "{}", OrderedJson.toPrettyString(2, JObject(Nil)))

    /////////////////////////////////////////////////////////////////////////////
    // toPrettyString — arrays                                                 //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toPrettyString07(): Unit \ Assert =
        assertEq(
            expected = "[\n  1\n]",
            OrderedJson.toPrettyString(2, JArray(Vector#{num(1)}))
        )

    @Test
    def toPrettyString08(): Unit \ Assert =
        assertEq(
            expected = "[\n  1,\n  2,\n  3\n]",
            OrderedJson.toPrettyString(2, JArray(Vector#{num(1), num(2), num(3)}))
        )

    /////////////////////////////////////////////////////////////////////////////
    // toPrettyString — objects                                                //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toPrettyString09(): Unit \ Assert =
        assertEq(
            expected = "{\n  \"a\": 1\n}",
            OrderedJson.toPrettyString(2, JObject(("a", num(1)) :: Nil))
        )

    @Test
    def toPrettyString10(): Unit \ Assert =
        assertEq(
            expected = "{\n  \"a\": 1,\n  \"b\": 2\n}",
            OrderedJson.toPrettyString(2, JObject(("a", num(1)) :: ("b", num(2)) :: Nil))
        )

    /////////////////////////////////////////////////////////////////////////////
    // toPrettyString — nesting                                                //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toPrettyString11(): Unit \ Assert =
        assertEq(
            expected = "[\n  [\n    1\n  ],\n  [\n    2\n  ]\n]",
            OrderedJson.toPrettyString(2, JArray(Vector#{JArray(Vector#{num(1)}), JArray(Vector#{num(2)})}))
        )

    @Test
    def toPrettyString12(): Unit \ Assert =
        assertEq(
            expected =
                "{\n" +
                "  \"users\": [\n" +
                "    {\n" +
                "      \"name\": \"alice\"\n" +
                "    },\n" +
                "    {\n" +
                "      \"name\": \"bob\"\n" +
                "    }\n" +
                "  ]\n" +
                "}",
            OrderedJson.toPrettyString(2, JObject(
                ("users", JArray(Vector#{
                    JObject(("name", JString("alice")) :: Nil),
                    JObject(("name", JString("bob")) :: Nil)
                })) :: Nil
            ))
        )

    /////////////////////////////////////////////////////////////////////////////
    // toPrettyString — different indent                                       //
    /////////////////////////////////////////////////////////////////////////////

    @Test
    def toPrettyString13(): Unit \ Assert =
        assertEq(
            expected = "[\n    1,\n    2\n]",
            OrderedJson.toPrettyString(4, JArray(Vector#{num(1), num(2)}))
        )

}
