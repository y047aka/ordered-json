/*
 * Copyright 2026 Yoshitaka Totsuka
 *
 * The module is `Util/Json.flix` of the Flix standard library, copyright the Flix Authors, Apache 2.0,
 * re-shaped around an ordered object. Its docstrings are kept where they still describe this file.
 *
 * Use of this source code is governed by the Apache 2.0 license
 * that can be found in the LICENSE file.
 */

///
/// Type of JSON values, and its functions.
///
pub mod OrderedJson {

    use OrderedJson.Json.{JArray, JBool, JNull, JNumber, JObject, JString}

    ///
    /// Type of JSON values.
    ///
    /// JSON numbers are stored as `BigDecimal` for lossless round-trip;
    /// JSON objects are stored as `List[(String, Json)]`, which gives
    /// the authored key order on output.
    ///
    pub enum Json with Eq {
        case JArray(Vector[Json])
        case JBool(Bool)
        case JNull
        case JNumber(BigDecimal)
        case JObject(List[(String, Json)])
        case JString(String)
    }

    instance ToString[Json] {
        pub def toString(j: Json): String = toCompactString(j)
    }

    ///
    /// How many properties an object may have and still be written on the line
    /// its own key stands on.
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
    /// `Compact` emits no extraneous whitespace; `Pretty(indent)` places each
    /// element on its own line using `indent` spaces per nesting level.
    /// `Inlined(rule, indent)` joins an object the rule admits onto the line its
    /// own key stands on, and `OneLine` breaks no line at all — for JSON Lines
    /// output, where the line break separates records and so cannot appear
    /// inside one.
    ///
    pub enum Style with Eq {
        case Compact
        case Pretty(Int32)
        case Inlined(Inline, Int32)
        case OneLine
    }

    ///
    /// Returns the compact JSON rendering of `j`: a single line with
    /// no extraneous whitespace.
    ///
    pub def toCompactString(j: Json): String = region rc {
        let sb = StringBuilder.empty(rc);
        write(j, 0, Style.Compact, sb);
        StringBuilder.toString(sb)
    }

    ///
    /// Returns the pretty-printed JSON rendering of `j`, using `indent` spaces
    /// per nesting level.
    ///
    /// Empty arrays and objects are rendered on a single line as `[]` or `{}`.
    /// Non-empty containers place each element on its own line; object keys
    /// are followed by `": "`.
    ///
    pub def toPrettyString(indent: Int32, j: Json): String = region rc {
        let sb = StringBuilder.empty(rc);
        write(j, 0, Style.Pretty(indent), sb);
        StringBuilder.toString(sb)
    }

    ///
    /// Returns the JSON rendering of `j` under the layout `s`.
    ///
    pub def renderWith(s: Style, j: Json): String = region rc {
        let sb = StringBuilder.empty(rc);
        write(j, 0, s, sb);
        StringBuilder.toString(sb)
    }

    ///
    /// Appends the JSON rendering of `j` to `sb` using style `s`.
    ///
    /// `d` is the current nesting level (0 at the root); it is ignored in
    /// `Compact` and `OneLine` styles. Empty arrays and objects always render as
    /// `[]` or `{}`.
    ///
    def write(j: Json, d: Int32, s: Style, sb: StringBuilder[r]): Unit \ r = match j {
        case JArray(v) =>
            if (Vector.isEmpty(v))
                StringBuilder.appendString("[]", sb)
            else {
                StringBuilder.append('[', sb);
                foreach ((i, e) <- ForEach.withIndex(v)) {
                    if (i > 0) { writeComma(s, sb) };
                    breakIndent(d + 1, s, sb);
                    write(e, d + 1, s, sb)
                };
                breakIndent(d, s, sb);
                StringBuilder.append(']', sb)
            }
        case JBool(b) =>
            StringBuilder.appendString(if (b) "true" else "false", sb)
        case JNull =>
            StringBuilder.appendString("null", sb)
        case JNumber(n) =>
            StringBuilder.appendString(BigDecimal.toPlainString(n), sb)
        case JObject(kvs) =>
            if (List.isEmpty(kvs))
                StringBuilder.appendString("{}", sb)
            else if (collapses(s, kvs))
                writeInline(kvs, sb)
            else {
                StringBuilder.append('{', sb);
                foreach ((i, (k, x)) <- ForEach.withIndex(kvs)) {
                    if (i > 0) { writeComma(s, sb) };
                    breakIndent(d + 1, s, sb);
                    writeEscaped(k, sb);
                    writeColon(s, sb);
                    write(x, d + 1, s, sb)
                };
                breakIndent(d, s, sb);
                StringBuilder.append('}', sb)
            }
        case JString(str) =>
            writeEscaped(str, sb)
    }

    ///
    /// Appends an object written on the line its key stands on: a space inside
    /// each brace, `", "` between the entries, no line break.
    ///
    /// The space inside the braces is a frozen byte: every line already written under `OneLine` carries it, and removing it restamps them all.
    /// The values are written under `OneLine`, which breaks no line and so cannot
    /// change their bytes — only a value that itself fits on the line reaches here.
    ///
    def writeInline(kvs: List[(String, Json)], sb: StringBuilder[r]): Unit \ r =
        StringBuilder.appendString("{ ", sb);
        foreach ((i, (k, x)) <- ForEach.withIndex(kvs)) {
            if (i > 0) { StringBuilder.appendString(", ", sb) };
            writeEscaped(k, sb);
            writeColon(Style.OneLine, sb);
            write(x, 0, Style.OneLine, sb)
        };
        StringBuilder.appendString(" }", sb)

    ///
    /// Whether an object whose properties are these goes on the line its key
    /// stands on: the rule admits the count, and no value spans lines.
    ///
    /// The rule governs objects and not arrays, which is a frozen byte-level fact
    /// and not an oversight.
    ///
    /// `fits` is bound above the match that may discard it and costs nothing: a pure
    /// `let` is call-by-need here, so under `Compact` and `Pretty` the walk is never
    /// forced.
    ///
    def collapses(s: Style, kvs: List[(String, Json)]): Bool =
        let rule = match s {
            case Style.Compact       => Inline.Never
            case Style.Pretty(_)     => Inline.Never
            case Style.Inlined(r, _) => r
            case Style.OneLine       => Inline.Always
        };
        let fits = List.forAll(match (_, x) -> fitsOnOneLine(x, s), kvs);
        match rule {
            case Inline.Never     => false
            case Inline.Always    => fits
            case Inline.AtMost(n) => List.length(kvs) <= n and fits
        }

    ///
    /// Whether `j` is written without a line break under `s`. The two styles that
    /// break no line answer `true` before `j` is even looked at, and a non-empty
    /// array answers `false` wherever a line is breakable at all, no rule having
    /// been asked about arrays.
    ///
    def fitsOnOneLine(j: Json, s: Style): Bool = match s {
        case Style.Compact => true
        case Style.OneLine => true
        case _ => match j {
            case JArray(v)    => Vector.isEmpty(v)
            case JObject(kvs) => List.isEmpty(kvs) or collapses(s, kvs)
            case _            => true
        }
    }

    ///
    /// In `Pretty` and `Inlined` styles, appends a newline followed by the
    /// indentation for nesting level `d`. In `Compact` and `OneLine` styles, does
    /// nothing.
    ///
    def breakIndent(d: Int32, s: Style, sb: StringBuilder[r]): Unit \ r = match s {
        case Style.Compact         => ()
        case Style.OneLine         => ()
        case Style.Pretty(ind)     => StringBuilder.append('\n', sb); writeIndent(ind * d, sb)
        case Style.Inlined(_, ind) => StringBuilder.append('\n', sb); writeIndent(ind * d, sb)
    }

    ///
    /// Appends the element separator to `sb`: `","` in every style but `OneLine`,
    /// which keeps a space after it.
    ///
    def writeComma(s: Style, sb: StringBuilder[r]): Unit \ r =
        if (s == Style.OneLine)
            StringBuilder.appendString(", ", sb)
        else
            StringBuilder.append(',', sb)

    ///
    /// Appends the object key/value separator to `sb`: `":"` in `Compact`
    /// style and `": "` in every other style.
    ///
    def writeColon(s: Style, sb: StringBuilder[r]): Unit \ r = match s {
        case Style.Compact => StringBuilder.append(':', sb)
        case _             => StringBuilder.appendString(": ", sb)
    }

    ///
    /// Appends `n` spaces to `sb`. Does nothing if `n <= 0`.
    ///
    def writeIndent(n: Int32, sb: StringBuilder[r]): Unit \ r =
        if (n > 0) { StringBuilder.appendString(String.repeat(n, " "), sb) }

    ///
    /// Appends `s` to `sb` as a JSON string literal: enclosed in double quotes,
    /// with backslash, double-quote, and control characters escaped per RFC 8259.
    ///
    def writeEscaped(s: String, sb: StringBuilder[r]): Unit \ r =
        StringBuilder.append('"', sb);
        foreach (c <- String.toList(s)) {
            writeEscapedChar(c, sb)
        };
        StringBuilder.append('"', sb)

    ///
    /// Appends `c` to `sb`, JSON-escaped if necessary.
    ///
    /// The two-character short escapes are emitted for backslash (0x5C),
    /// double-quote (0x22), backspace (0x08), tab (0x09), newline (0x0A),
    /// form-feed (0x0C), and carriage-return (0x0D). Other characters with
    /// code point below 0x20 are emitted as `\u00XX`. Everything else is
    /// passed through unchanged.
    ///
    def writeEscapedChar(c: Char, sb: StringBuilder[r]): Unit \ r =
        let cp = Char.toBmpCodePoint(c);
        match cp {
            case 0x5C => StringBuilder.appendString("\\\\", sb)
            case 0x22 => StringBuilder.appendString("\\\"", sb)
            case 0x08 => StringBuilder.appendString("\\b", sb)
            case 0x09 => StringBuilder.appendString("\\t", sb)
            case 0x0A => StringBuilder.appendString("\\n", sb)
            case 0x0C => StringBuilder.appendString("\\f", sb)
            case 0x0D => StringBuilder.appendString("\\r", sb)
            case _ if cp < 0x20 => writeControlEscape(cp, sb)
            case _ => StringBuilder.append(c, sb)
        }

    ///
    /// Appends the JSON `\u00XX` escape for the given code point `cp`.
    ///
    /// Precondition: `0 <= cp < 0x20`.
    ///
    def writeControlEscape(cp: Int32, sb: StringBuilder[r]): Unit \ r =
        StringBuilder.appendString("\\u00", sb);
        StringBuilder.append(hexDigit(cp / 16), sb);
        StringBuilder.append(hexDigit(Int32.bitwiseAnd(cp, 15)), sb)

    ///
    /// Returns the lowercase hex digit for `n`.
    ///
    /// Precondition: `0 <= n < 16`. Otherwise unreachable from the call site
    /// in `writeControlEscape`.
    ///
    def hexDigit(n: Int32): Char =
        match Char.forDigit(radix = 16, n) {
            case Some(c) => c
            case None    => unreachable!()
        }

}
