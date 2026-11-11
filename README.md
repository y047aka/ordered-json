# ordered-json

A JSON value that writes an object's properties in the order they were authored.

    { "carNumber": "007", "lapNumber": 1, "driverName": "Tom GAMBLE" }

The Flix standard `Util.Json` cannot write that. It holds an object as `JObject(Map[String, Json])`, and its own docstring says the map "gives canonical (sorted) key order on output". Its `JArray` is `Vector[Json]` and closed, so an ordered object cannot sit inside an array either — and real documents put ordered objects inside arrays: `drivers`, `entries`, `rounds`.

## The surface a caller needs

    use OrderedJson.Value.{JsonNull, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject}

    OrderedJson.render(value)                                   -- every value on a line of its own, 2-space indent
    OrderedJson.renderWith(Layout.Inlined(Inline.AtMost(2)), v) -- an object small enough to fit joins its key's line
    OrderedJson.renderWith(Layout.OneLine, v)                   -- one line, however many properties it holds

## What the library guarantees

- Pure: no effect annotation, and no dependency.
- A string is quoted and escaped by the standard module, so every character below 0x20 reaches the output escaped.
- Numbers keep the Flix spelling: `JsonInt(42)` writes `42` and `JsonFloat(x)` writes what `Double.toString` gives, so `0.20739060549440685` stays 17 digits rather than becoming the 55-digit `BigDecimal` expansion.
- `Layout.Expanded` is byte-identical to `Util.Json.toPrettyString(2, ·)` apart from key order, and from any `Float64` the standard module would widen to its exact decimal.

## What is not the library's business

The rule "an object of at most two properties, each of whose values fits on a line, is written inline" is the consumer's output contract, frozen in its committed bytes and its test suite — so it arrives as an argument, and the `2` is written in `elm-motorsport-analysis` and not here.

Two things the frozen bytes pinned on the library instead. A collapsed object is `{ ... }`, a space inside each brace. And the rule governs objects only: an array of two short strings still takes one element per line.

## The layouts

`Inline` is `Never`, `AtMost(n)`, or `Always` — how many properties an object may have and still be written on the line its key stands on. A value that already spans lines never collapses.

| `Layout`        | array             | object                                                                |
| --------------- | ----------------- | --------------------------------------------------------------------- |
| `Expanded`      | one line per item | one line per property                                                 |
| `Inlined(rule)` | one line per item | per property, unless `rule` admits the count and every value fits → one line |
| `OneLine`       | `[1, 2]`          | `{ "k": v, … }`, however many properties                              |

## Consumed by

`elm-motorsport-analysis` writes its timing archive with it: a 25 MB round summary, and 24,146 one-line lap records. Its check is byte identity — the five exported files hash the same before and after any change here, which is the only specification that has ever held.
