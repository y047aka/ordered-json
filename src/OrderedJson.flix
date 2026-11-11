/// A JSON value that writes an object's properties in the order they were authored.
///
/// The standard `Util.Json` sorts its keys, and its `JArray` is a closed `Vector[Json]`, so an ordered object cannot sit inside an array either.
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

    /// How far the layout breaks lines, and how much whitespace it keeps between the tokens.
    ///
    /// `indent` is not part of it: how deep a nesting level goes is the standard module's own argument, and stays one here.
    pub enum Layout with Eq {
        /// Byte-identical to `Util.Json.toPrettyString(2, ·)` apart from key order, and from any `Float64` the standard module would widen to its exact decimal.
        case Expanded
        /// Objects the rule admits join their key's line; arrays still take one element per line.
        case Inlined(Inline)
        /// For JSON Lines output, where the line break separates records and so cannot appear inside one.
        /// Not `Compact`: this keeps a space after every colon, and the space inside a collapsed object.
        case OneLine
        /// No whitespace anywhere, as `Util.Json.toCompactString` writes it: `{"a":1,"b":[1,2]}`.
        case Compact
    }

    /// The standard name, and its argument order: `indent` spaces per nesting level.
    pub def toPrettyString(indent: Int32, value: Value): String =
        renderWith(Layout.Expanded, indent, value)

    /// The standard name: no extraneous whitespace, byte-identical to `Util.Json.toCompactString` for a value the standard module spells the same way.
    pub def toCompactString(value: Value): String =
        renderWith(Layout.Compact, 0, value)

    /// Two-space `Expanded`, which is the standard module's own default.
    pub def render(value: Value): String =
        toPrettyString(2, value)

    pub def renderWith(layout: Layout, indent: Int32, value: Value): String =
        renderAt(layout, indent, 0, value)

    def renderAt(layout: Layout, indent: Int32, depth: Int32, value: Value): String =
        match value {
            case Value.JsonNull        => "null"
            case Value.JsonBool(b)     => if (b) "true" else "false"
            case Value.JsonInt(n)      => "${n}"
            case Value.JsonFloat(n)    => "${n}"
            case Value.JsonString(s)   => escapeString(s)
            case Value.JsonArray(xs)   =>
                array(layout, indent, depth, xs |> List.map(x -> renderAt(layout, indent, depth + 1, x)))
            case Value.JsonObject(kvs) =>
                let sep = if (layout == Layout.Compact) ":" else ": ";
                let entries = kvs |> List.map(match (k, v) ->
                    "${escapeString(k)}${sep}${renderAt(layout, indent, depth + 1, v)}"
                );
                object(layout, indent, depth, entries)
        }

    def array(layout: Layout, indent: Int32, depth: Int32, items: List[String]): String =
        if (List.isEmpty(items))
            "[]"
        else if (layout == Layout.Compact)
            "[${List.join(",", items)}]"
        else if (layout == Layout.OneLine)
            "[${List.join(", ", items)}]"
        else
            onOwnLines(indent, depth, "[", items, "]")

    /// The space inside the braces is a frozen byte: the consumer's committed archive carries it, and `Layout.OneLine` would restamp 24,146 lap lines without it.
    def object(layout: Layout, indent: Int32, depth: Int32, entries: List[String]): String =
        if (List.isEmpty(entries))
            "{}"
        else if (layout == Layout.Compact)
            "{${List.join(",", entries)}}"
        else if (collapses(layout, entries))
            "{ ${List.join(", ", entries)} }"
        else
            onOwnLines(indent, depth, "{", entries, "}")

    def collapses(layout: Layout, entries: List[String]): Bool =
        let rule = match layout {
            case Layout.Expanded    => Inline.Never
            case Layout.OneLine     => Inline.Always
            case Layout.Compact     => Inline.Never
            case Layout.Inlined(r)  => r
        };
        let fits = List.forAll(fitsOnOneLine, entries);
        match rule {
            case Inline.Never     => false
            case Inline.Always    => fits
            case Inline.AtMost(n) => List.length(entries) <= n and fits
        }

    def onOwnLines(indent: Int32, depth: Int32, open: String, items: List[String], close: String): String =
        let inner = String.repeat((depth + 1) * indent, " ");
        let outer = String.repeat(depth * indent, " ");
        "${open}\n${inner}${List.join(",\n${inner}", items)}\n${outer}${close}"

    def fitsOnOneLine(rendered: String): Bool =
        not String.contains({substr = "\n"}, rendered)

    /// The standard module quotes and escapes, so every character below 0x20 reaches the output escaped.
    def escapeString(s: String): String =
        Util.Json.toCompactString(Util.Json.Json.JString(s))

}
