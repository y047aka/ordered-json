/// A JSON value that writes an object's properties in the order they were authored.
///
/// The standard `Util.Json` holds an object as `JObject(Map[String, Json])`, documented as giving canonical
/// sorted key order on output, and its `JArray` is a closed `Vector[Json]`, so an ordered object cannot sit inside an array either.
pub mod OrderedJson {

    pub enum Value {
        case JsonNull
        case JsonBool(Bool)
        case JsonInt(Int32)
        case JsonFloat(Float64)
        case JsonString(String)
        case JsonArray(List[Value])
        case JsonObject(List[(String, Value)])
    }

    /// How many properties an object may have and still be written on the line its own key stands on.
    /// An object whose values already span lines never collapses, whatever the rule says.
    pub enum Inline with Eq {
        case Never
        case AtMost(Int32)
        case Always
    }

    /// How far the layout breaks lines: every value on a line of its own, small objects pulled onto the line their own key stands on, or no break at all.
    pub enum Layout with Eq {
        /// Byte-identical to `Util.Json.toPrettyString(2, ·)` apart from key order, and 2 is that module's own default.
        case Expanded
        /// Objects the rule admits join their key's line; arrays still take one element per line.
        case Inlined(Inline)
        /// For JSON Lines output, where the line break separates records and so cannot appear inside one.
        case OneLine
    }

    pub def render(value: Value): String =
        renderWith(Layout.Expanded, value)

    pub def renderWith(layout: Layout, value: Value): String =
        renderAt(layout, 0, value)

    def renderAt(layout: Layout, spaces: Int32, value: Value): String =
        match value {
            case Value.JsonNull        => "null"
            case Value.JsonBool(b)     => if (b) "true" else "false"
            case Value.JsonInt(n)      => "${n}"
            case Value.JsonFloat(n)    => "${n}"
            case Value.JsonString(s)   => escapeString(s)
            case Value.JsonArray(xs)   =>
                array(layout, spaces, xs |> List.map(x -> renderAt(layout, spaces + 2, x)))
            case Value.JsonObject(kvs) =>
                let entries = kvs |> List.map(match (k, v) ->
                    "${escapeString(k)}: ${renderAt(layout, spaces + 2, v)}"
                );
                object(layout, spaces, entries)
        }

    def array(layout: Layout, spaces: Int32, items: List[String]): String =
        if (List.isEmpty(items))
            "[]"
        else if (layout == Layout.OneLine)
            "[${List.join(", ", items)}]"
        else
            onOwnLines(spaces, "[", items, "]")

    /// The space inside the braces is a frozen byte: the consumer's committed archive carries it, and `Layout.OneLine` would restamp 24,146 lap lines without it.
    def object(layout: Layout, spaces: Int32, entries: List[String]): String =
        if (List.isEmpty(entries))
            "{}"
        else if (collapses(layout, entries))
            "{ ${List.join(", ", entries)} }"
        else
            onOwnLines(spaces, "{", entries, "}")

    def collapses(layout: Layout, entries: List[String]): Bool =
        let rule = match layout {
            case Layout.Expanded    => Inline.Never
            case Layout.OneLine     => Inline.Always
            case Layout.Inlined(r)  => r
        };
        let fits = List.forAll(fitsOnOneLine, entries);
        match rule {
            case Inline.Never     => false
            case Inline.Always    => fits
            case Inline.AtMost(n) => List.length(entries) <= n and fits
        }

    def onOwnLines(spaces: Int32, open: String, items: List[String], close: String): String =
        let inner = String.repeat(spaces + 2, " ");
        let outer = String.repeat(spaces, " ");
        "${open}\n${inner}${List.join(",\n${inner}", items)}\n${outer}${close}"

    def fitsOnOneLine(rendered: String): Bool =
        not String.contains({substr = "\n"}, rendered)

    /// The standard module quotes and escapes, so every character below 0x20 reaches the output escaped.
    def escapeString(s: String): String =
        Util.Json.toCompactString(Util.Json.Json.JString(s))

}
