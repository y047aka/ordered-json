/// The property-count limit is the caller's, so it arrives as an argument, and `AtMost(2)` is the one the consumer's committed bytes froze.
pub mod OrderedJson.TestLayout {

    use Assert.assertEq;
    use OrderedJson.toPrettyString
    use OrderedJson.renderWith
    use OrderedJson.Style
    use OrderedJson.Inline
    use OrderedJson.Json.{JNumber, JString, JArray, JObject}

    def num(n: Int32): OrderedJson.Json = JNumber(Int32.toBigDecimal(n))

    def inlined(value: OrderedJson.Json): String =
        renderWith(Style.Inlined(Inline.AtMost(2), 2), value)

    def onOneLine(value: OrderedJson.Json): String =
        renderWith(Style.OneLine, value)

    @Test
    def testSinglePropertyObjectIsInline(): Unit \ Assert =
        let obj = JObject(("name", JString("James CALADO")) :: Nil);
        assertEq(expected = "{ \"name\": \"James CALADO\" }", inlined(obj))

    @Test
    def testSinglePropertyObjectWithEmptyArrayIsInline(): Unit \ Assert =
        assertEq(expected = "{ \"drivers\": [] }", inlined(JObject(("drivers", JArray(Vector#{})) :: Nil)))

    @Test
    def testNestedSinglePropertyObjectsCollapseTogether(): Unit \ Assert =
        let obj = JObject(("car", JObject(("number", JString("7")) :: Nil)) :: Nil);
        assertEq(expected = "{ \"car\": { \"number\": \"7\" } }", inlined(obj))

    /// `Always` lifts the count limit and not the line rule: a value that spans lines still holds its object open.
    @Test
    def testAlwaysStillYieldsToAMultiLineValue(): Unit \ Assert =
        let obj = JObject(
            ("drivers", JArray(Vector#{JString("a"), JString("b")})) ::
            ("car", JObject(("number", JString("7")) :: Nil)) ::
            Nil
        );
        assertEq(
            expected = "{\n  \"drivers\": [\n    \"a\",\n    \"b\"\n  ],\n  \"car\": { \"number\": \"7\" }\n}",
            renderWith(Style.Inlined(Inline.Always, 2), obj)
        )

    @Test
    def testSinglePropertyObjectWithMultiLineValueIsNotInline(): Unit \ Assert =
        let obj = JObject(("drivers", JArray(Vector#{JString("a"), JString("b")})) :: Nil);
        assertEq(expected = "{\n  \"drivers\": [\n    \"a\",\n    \"b\"\n  ]\n}", inlined(obj))

    @Test
    def testTwoPropertyObjectIsInline(): Unit \ Assert =
        let obj = JObject(("time", JString("20.708")) :: ("elapsed", JString("20.708")) :: Nil);
        assertEq(expected = "{ \"time\": \"20.708\", \"elapsed\": \"20.708\" }", inlined(obj))

    @Test
    def testTwoPropertyObjectWithOneMultiLineValueIsNotInline(): Unit \ Assert =
        let obj = JObject(
            ("name", JString("test")) ::
            ("laps", JArray(Vector#{num(1), num(2)})) ::
            Nil
        );
        assertEq(expected = "{\n  \"name\": \"test\",\n  \"laps\": [\n    1,\n    2\n  ]\n}", inlined(obj))

    @Test
    def testThreePropertyObjectIsNotInline(): Unit \ Assert =
        let obj = JObject(
            ("s1", JString("51.908")) ::
            ("s2", JString("1:23.252")) ::
            ("s3", JString("1:39.395")) ::
            Nil
        );
        assertEq(
            expected = "{\n  \"s1\": \"51.908\",\n  \"s2\": \"1:23.252\",\n  \"s3\": \"1:39.395\"\n}",
            inlined(obj)
        )

    @Test
    def testInlineObjectKeepsItsIndentInsideAnArray(): Unit \ Assert =
        let arr = JArray(Vector#{JObject(("name", JString("Alex LYNN")) :: Nil)});
        assertEq(expected = "[\n  { \"name\": \"Alex LYNN\" }\n]", inlined(arr))

    @Test
    def testInlineObjectKeepsItsIndentAsAProperty(): Unit \ Assert =
        let obj = JObject(
            ("scl2", JObject(("time", JString("20.708")) :: ("elapsed", JString("20.708")) :: Nil)) ::
            ("z4",   JObject(("time", JString("13.826")) :: ("elapsed", JString("34.534")) :: Nil)) ::
            ("ip1",  JObject(("time", JString("17.374")) :: ("elapsed", JString("51.908")) :: Nil)) ::
            Nil
        );
        assertEq(expected = List.join("\n",
            "{" ::
            "  \"scl2\": { \"time\": \"20.708\", \"elapsed\": \"20.708\" }," ::
            "  \"z4\": { \"time\": \"13.826\", \"elapsed\": \"34.534\" }," ::
            "  \"ip1\": { \"time\": \"17.374\", \"elapsed\": \"51.908\" }" ::
            "}" :: Nil
        ), inlined(obj))

    @Test
    def testKeyIsEscaped(): Unit \ Assert =
        let obj = JObject(("say \"hi\"", num(1)) :: Nil);
        assertEq(expected = "{ \"say \\\"hi\\\"\": 1 }", inlined(obj))

    @Test
    def testOnOneLineKeepsAWideObjectOnOneLine(): Unit \ Assert =
        let obj = JObject(
            ("carNumber", JString("007")) ::
            ("driverName", JString("Harry TINCKNELL")) ::
            ("lapNumber", num(1)) ::
            ("elapsed", JString("1:42.619")) ::
            Nil
        );
        assertEq(
            expected = "{ \"carNumber\": \"007\", \"driverName\": \"Harry TINCKNELL\", \"lapNumber\": 1, \"elapsed\": \"1:42.619\" }",
            onOneLine(obj)
        )

    @Test
    def testOnOneLineFlattensNestedValues(): Unit \ Assert =
        let obj = JObject(
            ("miniSectors", JObject(
                ("scl2", JObject(("time", JString("20.708")) :: ("elapsed", JString("20.708")) :: Nil)) ::
                ("z4",   JObject(("time", JString("13.826")) :: ("elapsed", JString("34.534")) :: Nil)) ::
                Nil
            )) ::
            ("laps", JArray(Vector#{num(1), num(2)})) ::
            Nil
        );
        assertEq(
            expected = "{ \"miniSectors\": { \"scl2\": { \"time\": \"20.708\", \"elapsed\": \"20.708\" }, \"z4\": { \"time\": \"13.826\", \"elapsed\": \"34.534\" } }, \"laps\": [1, 2] }",
            onOneLine(obj)
        )

    @Test
    def testOnOneLineNeverEmitsANewline(): Unit \ Assert =
        let obj = JObject(
            ("a", JArray(Vector#{JObject(("b", num(1)) :: ("c", num(2)) :: ("d", num(3)) :: Nil)})) ::
            ("e", JObject(Nil)) ::
            ("f", JArray(Vector#{})) ::
            Nil
        );
        Assert.assertTrue(not String.contains({substr = "\n"}, onOneLine(obj)))

    @Test
    def testExpandedObjectMatchesPrettyString(): Unit \ Assert =
        let obj = JObject(
            ("name", JString("test")) ::
            ("season", num(2025)) ::
            ("laps", JArray(Vector#{num(1), num(2)})) ::
            Nil
        );
        assertEq(expected = toPrettyString(2, obj), inlined(obj))

}
