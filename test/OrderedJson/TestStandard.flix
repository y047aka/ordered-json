/// The standard module's own names, and the bytes it writes under them.
///
/// A document whose keys happen to be in the order a `Map` would sort them is where the two modules have nothing left to disagree about, so that is what these tests compare.
pub mod OrderedJson.TestStandard {

    use Assert.assertEq;
    use OrderedJson.Style
    use OrderedJson.Json.{JNull, JBool, JInt, JString, JArray, JObject}

    /// The same document as `standard`, authored in the order `standard` spells it in.
    def document(): OrderedJson.Json =
        JObject(
            ("a", JNull) ::
            ("b", JArray(Vector#{JInt(1), JBool(true)})) ::
            ("c", JObject(("d", JString("x")) :: Nil)) ::
            Nil
        )

    def standard(): String =
        "{\"a\":null,\"b\":[1,true],\"c\":{\"d\":\"x\"}}"

    @Test
    def testTheCompactBytesAreTheStandardModules(): Unit \ Assert =
        match Util.Json.parse(standard()) {
            case Result.Ok(j)  => assertEq(expected = Util.Json.toCompactString(j), OrderedJson.toCompactString(document()))
            case Result.Err(_) => Assert.assertTrue(false)
        }

    @Test
    def testThePrettyBytesAreTheStandardModules(): Unit \ Assert =
        match Util.Json.parse(standard()) {
            case Result.Ok(j)  => assertEq(expected = Util.Json.toPrettyString(2, j), OrderedJson.toPrettyString(2, document()))
            case Result.Err(_) => Assert.assertTrue(false)
        }

    /// The standard module's `instance ToString[Json]` writes the compact rendering, and this one does too.
    @Test
    def testToStringIsTheCompactRendering(): Unit \ Assert =
        assertEq(expected = OrderedJson.toCompactString(document()), ToString.toString(document()))

    /// The one-line layout of this library is not the standard module's compact one: it keeps a space after every colon, and inside a collapsed object.
    @Test
    def testOneLineIsNotCompact(): Unit \ Assert =
        let obj = JObject(("a", JInt(1)) :: ("b", JInt(2)) :: Nil);
        Assert.assertTrue(
            OrderedJson.renderWith(Style.OneLine, obj) == "{ \"a\": 1, \"b\": 2 }" and
            OrderedJson.renderWith(Style.Compact, obj) == "{\"a\":1,\"b\":2}"
        )

}
