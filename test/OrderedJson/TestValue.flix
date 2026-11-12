pub mod OrderedJson.TestValue {

    use Assert.assertEq;
    use OrderedJson.toPrettyString
    use OrderedJson.Json.{JInt, JFloat, JString, JArray, JObject}

    /// A `Float64` stays the 17 digits `Double.toString` gives, and does not become the 55-digit decimal a `BigDecimal` widens it to.
    @Test
    def testRenderFloatKeepsTheFlixSpelling(): Unit \ Assert =
        assertEq(expected = "0.20739060549440685", toPrettyString(2, JFloat(0.20739060549440685)))

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
        ), toPrettyString(2, JArray(Vector#{lap})))

}
