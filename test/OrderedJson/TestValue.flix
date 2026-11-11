pub mod OrderedJson.TestValue {

    use OrderedJson.render
    use OrderedJson.Value.{JsonNull, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject}

    @Test
    def testRenderNull(): Unit \ Assert =
        Assert.assertTrue(render(JsonNull) == "null")

    @Test
    def testRenderBoolTrue(): Unit \ Assert =
        Assert.assertTrue(render(JsonBool(true)) == "true")

    @Test
    def testRenderBoolFalse(): Unit \ Assert =
        Assert.assertTrue(render(JsonBool(false)) == "false")

    @Test
    def testRenderInt(): Unit \ Assert =
        Assert.assertTrue(render(JsonInt(42)) == "42")

    @Test
    def testRenderString(): Unit \ Assert =
        Assert.assertTrue(render(JsonString("hello")) == "\"hello\"")

    @Test
    def testRenderStringWithQuotes(): Unit \ Assert =
        let result = render(JsonString("say \"hi\""));
        Assert.assertTrue(String.contains({substr = "\\\""}, result))

    /// A raw control character is not a JSON string character, so a name holding one is a file no browser parses.
    @Test
    def testRenderStringEscapesControlCharacters(): Unit \ Assert =
        let backspace = Char.toString('\u0008');
        let formfeed  = Char.toString('\u000c');
        Assert.assertTrue(render(JsonString("a${backspace}b${formfeed}c")) == "\"a\\bb\\fc\"")

    @Test
    def testRenderEmptyArray(): Unit \ Assert =
        Assert.assertTrue(render(JsonArray(Nil)) == "[]")

    @Test
    def testRenderEmptyObject(): Unit \ Assert =
        Assert.assertTrue(render(JsonObject(Nil)) == "{}")

    @Test
    def testRenderObject(): Unit \ Assert =
        let obj = JsonObject(("name", JsonString("test")) :: ("value", JsonInt(1)) :: Nil);
        let result = render(obj);
        Assert.assertTrue(String.contains({substr = "\"name\": \"test\""}, result));
        Assert.assertTrue(String.contains({substr = "\"value\": 1"}, result))

    /// A sorted `JObject` would put `driverName` second, and no other test here says which of the two orders is owed to the caller.
    @Test
    def testPropertyOrderIsTheAuthoredOrder(): Unit \ Assert =
        let lap = JsonObject(
            ("carNumber", JsonString("007")) ::
            ("lapNumber", JsonInt(1)) ::
            ("driverName", JsonString("Tom GAMBLE")) ::
            Nil
        );
        Assert.assertTrue(render(JsonArray(lap :: Nil)) == List.join("\n",
            "[" ::
            "  {" ::
            "    \"carNumber\": \"007\"," ::
            "    \"lapNumber\": 1," ::
            "    \"driverName\": \"Tom GAMBLE\"" ::
            "  }" ::
            "]" :: Nil
        ))

    @Test
    def testRenderArray(): Unit \ Assert =
        let arr = JsonArray(JsonInt(1) :: JsonInt(2) :: Nil);
        let result = render(arr);
        Assert.assertTrue(String.contains({substr = "1"}, result));
        Assert.assertTrue(String.contains({substr = "2"}, result))

}
