pub mod OrderedJson.TestValue {

    use Assert.assertEq;
    use OrderedJson.toPrettyString
    use OrderedJson.Json.{JNumber, JString, JArray, JObject}

    /// A sorted `JObject` would put `driverName` second, and no other test here says which of the two orders is owed to the caller.
    @Test
    def testPropertyOrderIsTheAuthoredOrder(): Unit \ Assert =
        let lap = JObject(
            ("carNumber", JString("007")) ::
            ("lapNumber", JNumber(Int32.toBigDecimal(1))) ::
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
