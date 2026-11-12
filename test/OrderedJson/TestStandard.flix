/// The standard module's own names, and the bytes it writes under them.
///
/// A document whose keys happen to be in the order a `Map` would sort them is where the two modules have nothing left to disagree about, so that is what these tests compare.
pub mod OrderedJson.TestStandard {

    use Assert.assertEq;
    use OrderedJson.Style
    use OrderedJson.Json.{JNull, JBool, JNumber, JString, JArray, JObject}

    def num(n: Int32): OrderedJson.Json = JNumber(Int32.toBigDecimal(n))

    /// The same document as `standard`, authored in the order `standard` spells it in.
    ///
    /// A `BigDecimal` literal keeps the scale it was written with, which is how `1.50ff` is `1.50` and not `1.5`.
    def document(): OrderedJson.Json =
        JObject(
            ("a", JNull) ::
            ("b", JArray(Vector#{num(1), JBool(true)})) ::
            ("c", JObject(("d", JString("x")) :: Nil)) ::
            ("e", JNumber(0.20739060549440685ff)) ::
            ("f", JNumber(1.50ff)) ::
            Nil
        )

    def standard(): String =
        "{\"a\":null,\"b\":[1,true],\"c\":{\"d\":\"x\"},\"e\":0.20739060549440685,\"f\":1.50}"

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
        match Util.Json.parse(standard()) {
            case Result.Ok(j)  => assertEq(expected = Util.Json.toCompactString(j), ToString.toString(document()))
            case Result.Err(_) => Assert.assertTrue(false)
        }

    /// The one-line layout of this library is not the standard module's compact one: it keeps a space after every colon, and inside a collapsed object.
    @Test
    def testOneLineIsNotCompact(): Unit \ Assert =
        let obj = JObject(("a", num(1)) :: ("b", num(2)) :: Nil);
        Assert.assertTrue(
            OrderedJson.renderWith(Style.OneLine, obj) == "{ \"a\": 1, \"b\": 2 }" and
            OrderedJson.renderWith(Style.Compact, obj) == "{\"a\":1,\"b\":2}"
        )

}
