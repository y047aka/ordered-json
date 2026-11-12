/// The standard module's own names, and the bytes it writes under them.
///
/// A document whose keys happen to be in the order a `Map` would sort them is where the two modules have nothing left to disagree about, so that is what these tests compare.
pub mod OrderedJson.Legacy.TestStandard {

    use OrderedJson.Legacy.Layout
    use OrderedJson.Legacy.Json.{JsonNull, JsonBool, JsonInt, JsonString, JsonArray, JsonObject}

    /// The same document as `standard`, authored in the order `standard` spells it in.
    def document(): OrderedJson.Legacy.Json =
        JsonObject(
            ("a", JsonNull) ::
            ("b", JsonArray(JsonInt(1) :: JsonBool(true) :: Nil)) ::
            ("c", JsonObject(("d", JsonString("x")) :: Nil)) ::
            Nil
        )

    def standard(): String =
        "{\"a\":null,\"b\":[1,true],\"c\":{\"d\":\"x\"}}"

    @Test
    def testTheCompactBytesAreTheStandardModules(): Unit \ Assert =
        match Util.Json.parse(standard()) {
            case Result.Ok(j)  => Assert.assertTrue(OrderedJson.Legacy.toCompactString(document()) == Util.Json.toCompactString(j))
            case Result.Err(_) => Assert.assertTrue(false)
        }

    @Test
    def testThePrettyBytesAreTheStandardModules(): Unit \ Assert =
        match Util.Json.parse(standard()) {
            case Result.Ok(j)  => Assert.assertTrue(OrderedJson.Legacy.toPrettyString(2, document()) == Util.Json.toPrettyString(2, j))
            case Result.Err(_) => Assert.assertTrue(false)
        }

    @Test
    def testTheIndentIsTheStandardModulesArgument(): Unit \ Assert =
        let four = OrderedJson.Legacy.toPrettyString(4, JsonArray(JsonInt(1) :: Nil));
        Assert.assertTrue(four == "[\n    1\n]")

    @Test
    def testRenderIsTheStandardDefaultOfTwoSpaces(): Unit \ Assert =
        Assert.assertTrue(OrderedJson.Legacy.render(document()) == OrderedJson.Legacy.toPrettyString(2, document()))

    /// The standard module's `instance ToString[Json]` writes the compact rendering, and this one does too.
    @Test
    def testToStringIsTheCompactRendering(): Unit \ Assert =
        Assert.assertTrue(ToString.toString(document()) == OrderedJson.Legacy.toCompactString(document()))

    /// The one-line layout of this library is not the standard module's compact one: it keeps a space after every colon, and inside a collapsed object.
    @Test
    def testOneLineIsNotCompact(): Unit \ Assert =
        let obj = JsonObject(("a", JsonInt(1)) :: ("b", JsonInt(2)) :: Nil);
        Assert.assertTrue(
            OrderedJson.Legacy.renderWith(Layout.OneLine, 0, obj) == "{ \"a\": 1, \"b\": 2 }" and
            OrderedJson.Legacy.renderWith(Layout.Compact, 0, obj) == "{\"a\":1,\"b\":2}"
        )

}
