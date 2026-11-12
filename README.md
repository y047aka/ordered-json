# ordered-json

A JSON value that writes an object's properties in the order they were authored.

    { "carNumber": "007", "lapNumber": 1, "driverName": "Tom GAMBLE" }

The Flix standard `Util.Json` cannot write that. It holds an object as `JObject(Map[String, Json])`, and its own docstring says the map "gives canonical (sorted) key order on output". Its `JArray` is `Vector[Json]` and closed, so an ordered object cannot sit inside an array either — and real documents put ordered objects inside arrays: `drivers`, `entries`, `rounds`.

## The surface a caller needs

    use OrderedJson.Json.{JNull, JBool, JInt, JFloat, JString, JArray, JObject}

    OrderedJson.toPrettyString(2, value)                          -- every value on a line of its own, as the standard module writes it
    OrderedJson.toCompactString(value)                            -- no extraneous whitespace, as the standard module writes it
    OrderedJson.renderWith(Style.Inlined(Inline.AtMost(2), 2), value) -- an object small enough to fit joins its key's line
    OrderedJson.renderWith(Style.OneLine, value)                  -- one line, however many properties it holds

## Where the standard module's names are reused

The module is `Util/Json.flix` cut down to its encoder and re-shaped around an ordered object, so the names, the argument order, and the docstrings are that file's. `toPrettyString` and `toCompactString` are its names and its argument order, and `Style` carries the indent where the standard module carries it.

| `Util.Json`                 | `OrderedJson`                     | bytes |
| --- | --- | --- |
| `toCompactString(j)`        | `toCompactString(j)`              | identical for a document the standard module spells the same way |
| `toPrettyString(indent, j)` | `toPrettyString(indent, j)`       | identical, same argument order |
| `Json`, `instance ToString` | `Json`, `instance ToString`       | the type is named `Json` here too, and `ToString` writes the compact rendering there as here |
| `JNull`, `JBool`, `JArray`, `JString` | the same  | the cases are the standard's, and `JArray` is a `Vector` here as there |
| `JNumber(BigDecimal)`       | `JInt(Int32)`, `JFloat(Float64)`  | apart on purpose: a `Float64` through `BigDecimal` spells 17 significant digits as 55 |
| `JObject(Map[String, Json])`| `JObject(List[(String, Json)])`   | the library |
| `Style`                     | `Style`                           | `Compact` and `Pretty(indent)` are the standard's; `Inlined(rule, indent)` and `OneLine` are added |
| `parse`, `decode`           | not here                          | the standard parser puts an object into a `Map`, so a parsed document's authored order is gone before any encoder could be asked for it |
| `toRichString`              | not here                          | needs `RichString` and the colours |

## What the library guarantees

- Pure: no effect annotation, and no dependency.
- A string is quoted and escaped per RFC 8259, by the standard module's own `writeEscapedChar`, so every character below 0x20 reaches the output escaped.
- Numbers keep the Flix spelling: `JInt(42)` writes `42` and `JFloat(x)` writes what `Double.toString` gives, so `0.20739060549440685` stays 17 digits rather than becoming the 55-digit `BigDecimal` expansion the standard module writes.
- The two standard-named renderings are compared against the standard module's own output in `TestStandard`, for a document whose keys happen to be in the order a `Map` would sort them. No claim of byte-identity survives a `Float64`.

## What is not the library's business

The rule "an object of at most two properties, each of whose values fits on a line, is written inline" is the consumer's output contract, frozen in its committed bytes and its test suite — so it arrives as an argument, and the `2` is written in `elm-motorsport-analysis` and not here.

Two things the frozen bytes pinned on the library instead. A collapsed object is `{ ... }`, a space inside each brace. And the rule governs objects only: an array of two short strings still takes one element per line.

## The layouts

`Inline` is `Never`, `AtMost(n)`, or `Always` — how many properties an object may have and still be written on the line its key stands on. A value that already spans lines never collapses.

| `Style`               | array             | object                                                                |
| --------------------- | ----------------- | --------------------------------------------------------------------- |
| `Compact`             | `[1,2]`           | `{"k":v}`, however many properties — the standard module's compact bytes |
| `Pretty(indent)`      | one line per item | one line per property — the standard module's `Pretty`, the indent being its own argument |
| `Inlined(rule, ind)`  | one line per item | per property, unless `rule` admits the count and every value fits → one line |
| `OneLine`             | `[1, 2]`          | `{ "k": v, … }`, however many properties                              |

## Consumed by

`elm-motorsport-analysis` writes its timing archive with it: a 25 MB round summary, and 24,146 one-line lap records. Its check is byte identity — the five exported files hash the same before and after any change here, which is the only specification that has ever held.

## License

Apache 2.0, the same license as the Flix standard library. The module is that library's `Util/Json.flix` re-shaped around an ordered object, and the docstrings that still describe it are that file's; `src/OrderedJson.flix` says so at its top, and `LICENSE.md` is the file the standard library's own header points to. The standard library's own `TestJson.flix` is kept in `test/OrderedJson/`, reduced to the encoder, and still passes.
