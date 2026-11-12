/*
 * Copyright 2026 Flix Authors
 *
 * Use of this source code is governed by the Apache 2.0 license
 * that can be found in the LICENSE.md file.
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
    /// JSON objects are stored as `Map[String, Json]`, which gives
    /// canonical (sorted) key order on output.
    ///
    pub enum Json with Eq {
        case JArray(Vector[Json])
        case JBool(Bool)
        case JNull
        case JNumber(BigDecimal)
        case JObject(Map[String, Json])
        case JString(String)
    }

    instance ToString[Json] {
        pub def toString(j: Json): String = toCompactString(j)
    }

    ///
    /// Controls the layout used by `write`.
    ///
    /// `Compact` emits no extraneous whitespace; `Pretty(indent)` places each
    /// element on its own line using `indent` spaces per nesting level.
    ///
    enum Style {
        case Compact
        case Pretty(Int32)
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
    /// Appends the JSON rendering of `j` to `sb` using style `s`.
    ///
    /// `d` is the current nesting level (0 at the root); it is ignored in
    /// `Compact` style. Empty arrays and objects always render as `[]` or `{}`.
    ///
    def write(j: Json, d: Int32, s: Style, sb: StringBuilder[r]): Unit \ r = match j {
        case JArray(v) =>
            if (Vector.isEmpty(v))
                StringBuilder.appendString("[]", sb)
            else {
                StringBuilder.append('[', sb);
                foreach ((i, e) <- ForEach.withIndex(v)) {
                    if (i > 0) { StringBuilder.append(',', sb) };
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
        case JObject(m) =>
            if (Map.isEmpty(m))
                StringBuilder.appendString("{}", sb)
            else {
                StringBuilder.append('{', sb);
                foreach ((i, (k, x)) <- ForEach.withIndex(m)) {
                    if (i > 0) { StringBuilder.append(',', sb) };
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
    /// In `Pretty` style, appends a newline followed by the indentation for
    /// nesting level `d`. In `Compact` style, does nothing.
    ///
    def breakIndent(d: Int32, s: Style, sb: StringBuilder[r]): Unit \ r = match s {
        case Style.Compact     => ()
        case Style.Pretty(ind) => StringBuilder.append('\n', sb); writeIndent(ind * d, sb)
    }

    ///
    /// Appends the object key/value separator to `sb`: `":"` in `Compact`
    /// style and `": "` in `Pretty` style.
    ///
    def writeColon(s: Style, sb: StringBuilder[r]): Unit \ r = match s {
        case Style.Compact   => StringBuilder.append(':', sb)
        case Style.Pretty(_) => StringBuilder.appendString(": ", sb)
    }

    ///
    /// Appends `n` spaces to `sb`. Does nothing if `n <= 0`.
    ///
    def writeIndent(n: Int32, sb: StringBuilder[r]): Unit \ r =
        if (n > 0) { StringBuilder.appendString(String.repeat(n, " "), sb) }

    ///
    /// Returns `s` as a JSON string literal: enclosed in double quotes, with
    /// backslash, double-quote, and control characters escaped per RFC 8259.
    ///
    pub def escapeString(s: String): String = region rc {
        let sb = StringBuilder.empty(rc);
        writeEscaped(s, sb);
        StringBuilder.toString(sb)
    }

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
