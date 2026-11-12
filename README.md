# ordered-json

A JSON value that writes an object's properties in the order they were authored.

    { "z": 1, "m": 2, "a": 3 }

`Util.Json` of the Flix standard library cannot write that. It holds an object as `JObject(Map[String, Json])`, and its own docstring says the map "gives canonical (sorted) key order on output". Its `JArray` is `Vector[Json]` and closed, so an ordered object cannot sit inside an array either, which is where ordered objects usually are.

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

    toPrettyString(2, value)                              -- every value on a line of its own
    toCompactString(value)                                -- no extraneous whitespace
    renderWith(Style.Inlined(Inline.AtMost(2), 2), value) -- an object small enough to fit joins its key's line
    renderWith(Style.OneLine, value)                      -- one line, however many properties it holds

The mount is a `use`-line prefix and nothing else: a signature writes the type `Json`, because 0.79 does not parse `OrderedJson::OrderedJson.Json` in a type position.

## The layouts

`Inline` is `Never`, `AtMost(n)`, or `Always` — how many properties an object may have and still be written on the line its key stands on. A value that already spans lines never collapses.

| `Style`               | array             | object                                                                |
| --------------------- | ----------------- | --------------------------------------------------------------------- |
| `Compact`             | `[1,2]`           | `{"k":v}`, however many properties                                     |
| `Pretty(indent)`      | one line per item | one line per property                                                  |
| `Inlined(rule, ind)`  | one line per item | per property, unless `rule` admits the count and every value fits → one line |
| `OneLine`             | `[1, 2]`          | `{ "k": v, … }`, however many properties                              |

`Compact` and `Pretty(indent)` are the standard module's two layouts, the argument order included. `Inlined` and `OneLine` are the two added here: the first for a document that reads better with its small objects on the key's line, the second for JSON Lines output, where the line break separates records and so cannot appear inside one.

## What the library guarantees

- Pure: no effect annotation, and no dependency.
- A string is quoted and escaped per RFC 8259, so every character below 0x20 reaches the output escaped.
- Numbers are one case, `JNumber(BigDecimal)`, spelled by `BigDecimal.toPlainString`, so a `1.50` keeps its trailing zero and no magnitude reaches the output in exponent form. `NaN` and `Infinity` cannot be written at all, because a `BigDecimal` cannot hold them.
- `toCompactString` and `toPrettyString` are compared against the standard module's own output, on a document whose keys happen to be in the order a `Map` would sort them.

## Getting a `Float64` into a `JNumber`

The one trap. `Float64.tryToBigDecimal` is `new BigDecimal(x)`, which spells `0.20739060549440685` as `0.207390605494406854436562070986838079988956451416015625` — valid JSON, parsing back to the same `Float64`, and silently tripling the file. `BigDecimal.fromString("${Float64.toString(x)}")` is exact, and is the route `Util.Json.parse` itself takes. `Int32.toBigDecimal` is exact.

## The standard module this comes from

The module is `Util/Json.flix` cut down to its encoder and re-shaped around an ordered object, so the names, the argument order, and the docstrings are that file's, and the escaping and the number spelling are its own code. `parse`, `decode`, and `FromJson` are not here — the standard parser puts an object into a `Map`, so a parsed document's authored order is gone before any encoder could be asked for it — and `toRichString` is not here either. Anything else the standard module has can be added; the parts it would need are already in place.

## License

Apache 2.0, the same license as the Flix standard library.
