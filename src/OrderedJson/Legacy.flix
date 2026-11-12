/*
 * Copyright 2026 Yoshitaka Totsuka
 *
 * The module is `Util/Json.flix` of the Flix standard library, copyright the Flix Authors, Apache 2.0,
 * re-shaped around an ordered object. Its docstrings are kept where they still describe this file.
 *
 * Use of this source code is governed by the Apache 2.0 license
 * that can be found in the LICENSE.md file.
 */

///
/// Type of JSON values, and its functions.
///
/// What differs from `Util.Json` is the key order, and the collapse.
/// An object here is a `List` of key and value pairs and not a `Map`, so the output order is the order the properties were authored in.
///
pub mod OrderedJson.Legacy {

    ///
    /// Type of JSON values.
    ///
    /// JSON numbers are kept as `Int32` and `Float64`, which spells a `Float64` the way `Double.toString` spells it
    /// and not as the exact decimal a `BigDecimal` widens it to;
    /// JSON objects are kept as `List[(String, Json)]`, which gives
    /// the authored key order on output.
    ///
    pub enum Json with Eq {
        case JsonArray(List[Json])
        case JsonBool(Bool)
        case JsonFloat(Float64)
        case JsonInt(Int32)
        case JsonNull
        case JsonObject(List[(String, Json)])
        case JsonString(String)
    }

    instance ToString[Json] {
        pub def toString(j: Json): String = toCompactString(j)
    }

    ///
    /// How many properties an object may have and still be written on the line its own key stands on.
    /// An object whose values already span lines never collapses, whatever the rule says.
    ///
    pub enum Inline with Eq {
        case Never
        case AtMost(Int32)
        case Always
    }

    ///
    /// Controls the layout used by `write`.
    ///
    /// The indentation per nesting level is not part of it. `toPrettyString` takes it as its own argument,
    /// as the standard module does, and two of the four layouts have no indentation to take.
    ///
    pub enum Layout with Eq {
        /// No extraneous whitespace, as the standard module's `Compact` writes it: `{"a":1,"b":[1,2]}`.
        case Compact
        /// Each element on its own line, as the standard module's `Pretty` writes it, the indent being elsewhere.
        case Pretty
        /// Objects the rule admits join their key's line; arrays still take one element per line.
        case Inlined(Inline)
        /// No line break at all, for JSON Lines output, where the line break separates records and so cannot
        /// appear inside one. Not `Compact`: this keeps a space after every colon, and the space inside a
        /// collapsed object.
        case OneLine
    }

    ///
    /// Returns the compact JSON rendering of `j`: a single line with no extraneous whitespace.
    ///
    pub def toCompactString(j: Json): String =
        renderWith(Layout.Compact, 0, j)

    ///
    /// Returns the pretty-printed JSON rendering of `j`, using `indent` spaces per nesting level.
    ///
    /// Empty arrays and objects are rendered on a single line as `[]` or `{}`.
    /// Non-empty containers place each element on its own line; object keys are followed by `": "`.
    ///
    /// `Layout.Inlined` is the exception this library exists to add: an object the rule admits is written on the line its own key stands on.
    ///
    pub def toPrettyString(indent: Int32, j: Json): String =
        renderWith(Layout.Pretty, indent, j)

    ///
    /// The pretty rendering at the standard module's own default of two spaces per nesting level.
    ///
    pub def render(j: Json): String =
        toPrettyString(2, j)

    ///
    /// Returns the JSON rendering of `j` under `layout`, indented `indent` spaces per nesting level.
    ///
    /// `Layout.Compact` and `Layout.OneLine` ignore `indent`: neither breaks a line.
    ///
    pub def renderWith(layout: Layout, indent: Int32, j: Json): String =
        write(j, 0, layout, indent)

    ///
    /// Returns the JSON rendering of `j` under `layout`.
    ///
    /// `d` is the current nesting level (0 at the root); it is ignored in `Compact` and `OneLine` styles.
    /// Empty arrays and objects always render as `[]` or `{}`.
    ///
    def write(j: Json, d: Int32, layout: Layout, indent: Int32): String =
        match j {
            case Json.JsonNull       => "null"
            case Json.JsonBool(b)    => if (b) "true" else "false"
            case Json.JsonInt(n)     => "${n}"
            case Json.JsonFloat(n)   => "${n}"
            case Json.JsonString(s)  => escapeString(s)
            case Json.JsonArray(xs)  =>
                array(layout, indent, d, xs |> List.map(x -> write(x, d + 1, layout, indent)))
            case Json.JsonObject(kvs) =>
                let sep = writeColon(layout);
                let entries = kvs |> List.map(match (k, v) ->
                    "${escapeString(k)}${sep}${write(v, d + 1, layout, indent)}"
                );
                object(layout, indent, d, entries)
        }

    ///
    /// The rendering of an array whose elements are rendered already: `items` holds one rendered element per
    /// element of the array.
    ///
    def array(layout: Layout, indent: Int32, d: Int32, items: List[String]): String =
        if (List.isEmpty(items))
            "[]"
        else if (layout == Layout.Compact)
            "[${List.join(",", items)}]"
        else if (layout == Layout.OneLine)
            "[${List.join(", ", items)}]"
        else
            onOwnLines(indent, d, "[", items, "]")

    ///
    /// The rendering of an object whose entries are rendered already.
    ///
    /// The space inside the braces of a collapsed object is a frozen byte: the consumer's committed archive
    /// carries it, and `Layout.OneLine` would restamp 24,146 lap lines without it.
    ///
    def object(layout: Layout, indent: Int32, d: Int32, entries: List[String]): String =
        if (List.isEmpty(entries))
            "{}"
        else if (layout == Layout.Compact)
            "{${List.join(",", entries)}}"
        else if (collapses(layout, entries))
            "{ ${List.join(", ", entries)} }"
        else
            onOwnLines(indent, d, "{", entries, "}")

    ///
    /// Whether an object whose entries are these goes on the line its key stands on: the rule admits the count,
    /// and no entry spans lines.
    ///
    def collapses(layout: Layout, entries: List[String]): Bool =
        let rule = match layout {
            case Layout.Compact     => Inline.Never
            case Layout.Pretty      => Inline.Never
            case Layout.OneLine     => Inline.Always
            case Layout.Inlined(r)  => r
        };
        let fits = List.forAll(fitsOnOneLine, entries);
        match rule {
            case Inline.Never     => false
            case Inline.Always    => fits
            case Inline.AtMost(n) => List.length(entries) <= n and fits
        }

    ///
    /// A newline followed by the indentation for nesting level `d`.
    ///
    def breakIndent(indent: Int32, d: Int32): String =
        "\n${writeIndent(indent * d)}"

    ///
    /// `n` spaces.
    /// Does nothing if `n <= 0`.
    ///
    def writeIndent(n: Int32): String =
        if (n > 0) String.repeat(n, " ") else ""

    ///
    /// The object key/value separator: `":"` in `Compact` style and `": "` in every other style.
    ///
    def writeColon(layout: Layout): String =
        if (layout == Layout.Compact) ":" else ": "

    ///
    /// The rendering of a container that breaks its lines: `open`, one item per line at nesting level `d + 1`,
    /// and `close` back at `d`.
    ///
    def onOwnLines(indent: Int32, d: Int32, open: String, items: List[String], close: String): String =
        let at = breakIndent(indent, d + 1);
        "${open}${at}${List.join(",${at}", items)}${breakIndent(indent, d)}${close}"

    ///
    /// Whether a rendered value can be reached without crossing a line break.
    ///
    def fitsOnOneLine(rendered: String): Bool =
        not String.contains({substr = "\n"}, rendered)

    ///
    /// Returns `s` as a JSON string literal: enclosed in double quotes, with backslash, double-quote, and control characters escaped per RFC 8259.
    ///
    /// The standard module's own `escapeString` is not `pub`, and this is its public route — the one thing
    /// here that the standard module is still asked to do.
    ///
    def escapeString(s: String): String =
        Util.Json.toCompactString(Util.Json.Json.JString(s))

}
