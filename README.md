# ordered-json

A JSON value that writes an object's properties in the order they were authored.

    { "carNumber": "007", "lapNumber": 1, "driverName": "Tom GAMBLE" }

The Flix standard `Util.Json` cannot write that. It holds an object as `JObject(Map[String, Json])`, and its own docstring says the map "gives canonical (sorted) key order on output". Its `JArray` is `Vector[Json]` and closed, so an ordered object cannot sit inside an array either — and real documents put ordered objects inside arrays: `drivers`, `entries`, `rounds`.

## Install

A Flix dependency is reached through a mount, and this repository's name cannot be one: a mount is a letter followed by letters, digits, or underscores, and the hyphen in `ordered-json` would read as a minus. So the mount is declared by hand, and the name to declare is `OrderedJson`. The module keeps its own name under the mount, which is why a caller writes it twice.

    [dependencies]
    "github:y047aka/ordered-json" = { version = "0.1.0", mount = "OrderedJson" }

The version is the GitHub release, so `0.1.0` is the tag `v0.1.0`.

## The surface a caller needs

    use OrderedJson::OrderedJson.Json
    use OrderedJson::OrderedJson.Json.{JNull, JBool, JNumber, JString, JArray, JObject}
    use OrderedJson::OrderedJson.{toCompactString, toPrettyString, renderWith}
    use OrderedJson::OrderedJson.{Inline, Style}

    toPrettyString(2, value)                            -- every value on a line of its own, as the standard module writes it
    toCompactString(value)                              -- no extraneous whitespace, as the standard module writes it
    renderWith(Style.Inlined(Inline.AtMost(2), 2), value) -- an object small enough to fit joins its key's line
    renderWith(Style.OneLine, value)                    -- one line, however many properties it holds

The mount is a `use`-line prefix and nothing else: a signature writes the type `Json`, because 0.79 does not parse `OrderedJson::OrderedJson.Json` in a type position.

## Where the standard module's names are reused

The module is `Util/Json.flix` cut down to its encoder and re-shaped around an ordered object, so the names, the argument order, and the docstrings are that file's.

| `Util.Json`                 | `OrderedJson`                     | bytes |
| --- | --- | --- |
| `toCompactString(j)`        | `toCompactString(j)`              | identical for a document the standard module spells the same way |
| `toPrettyString(indent, j)` | `toPrettyString(indent, j)`       | identical, same argument order |
| `Json`, `instance ToString` | `Json`, `instance ToString`       | the type is named `Json` here too, and `ToString` writes the compact rendering there as here |
| `JNull`, `JBool`, `JArray`, `JNumber`, `JString` | the same | the enum is the standard's, case for case and in its order, `JArray` being a `Vector` here as there |
| `JObject(Map[String, Json])`| `JObject(List[(String, Json)])`   | the library |
| `Style`                     | `Style`                           | `Compact` and `Pretty(indent)` are the standard's; `Inlined(rule, indent)` and `OneLine` are added |
| `parse`, `decode`, `FromJson` | not here                        | the standard parser puts an object into a `Map`, so a parsed document's authored order is gone before any encoder could be asked for it |
| `toRichString`              | not here                          | needs `RichString` and the colours |

## What the library guarantees

- Pure: no effect annotation, and no dependency.
- A string is quoted and escaped per RFC 8259, by the standard module's own `writeEscapedChar`, so every character below 0x20 reaches the output escaped.
- Numbers are the standard module's own: one case, `JNumber(BigDecimal)`, spelled by `BigDecimal.toPlainString`, so a `1.50` keeps its trailing zero and no magnitude reaches the output in exponent form. `NaN` and `Infinity` cannot be written at all, because a `BigDecimal` cannot hold them.
- The standard-named renderings are compared against the standard module's own output in `TestStandard`, on a document whose keys happen to be in the order a `Map` would sort them and whose numbers a `Float64` could not have carried.

## Getting a `Float64` into a `JNumber`

The one trap. `Float64.tryToBigDecimal` is `new BigDecimal(x)`, which spells `0.20739060549440685` as `0.207390605494406854436562070986838079988956451416015625` — valid JSON, parsing back to the same `Float64`, and silently tripling an archive. `BigDecimal.fromString("${Float64.toString(x)}")` is exact, and is the route `Util.Json.parse` itself takes. `Int32.toBigDecimal` is exact.

## What is not the library's business

The rule "an object of at most two properties, each of whose values fits on a line, is written inline" is the consumer's output contract, frozen in its committed bytes and its test suite — so it arrives as an argument, and the `2` is written in `elm-motorsport-analysis` and not here. Two things the frozen bytes pinned on the library instead, a collapsed object's `{ ... }` padding and the rule governing objects and not arrays, are at `writeInline` and `collapses`.

## The layouts

`Inline` is `Never`, `AtMost(n)`, or `Always` — how many properties an object may have and still be written on the line its key stands on. A value that already spans lines never collapses.

| `Style`               | array             | object                                                                |
| --------------------- | ----------------- | --------------------------------------------------------------------- |
| `Compact`             | `[1,2]`           | `{"k":v}`, however many properties — the standard module's compact bytes |
| `Pretty(indent)`      | one line per item | one line per property — the standard module's `Pretty`, the indent being its own argument |
| `Inlined(rule, ind)`  | one line per item | per property, unless `rule` admits the count and every value fits → one line |
| `OneLine`             | `[1, 2]`          | `{ "k": v, … }`, however many properties                              |

## Consumed by

`elm-motorsport-analysis` is where this came from, and it does not reference the library yet; the Install section is the coordinate and the mount it will reference. When it does the check is byte identity — the five exported files hash the same before and after any change here, which is the only specification that has ever held. AGENTS.md carries the commands and the five hashes.

## License

Apache 2.0, the same license as the Flix standard library; AGENTS.md carries what that implies for the docstrings.
