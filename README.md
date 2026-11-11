# ordered-json

A JSON value that writes an object's properties in the order they were authored.

    { "carNumber": "007", "lapNumber": 1, "driverName": "Tom GAMBLE" }

The Flix standard `Util.Json` cannot write that. It holds an object as `JObject(Map[String, Json])`, and its own docstring says the map "gives canonical (sorted) key order on output". Its `JArray` is `Vector[Json]` and closed, so an ordered object cannot sit inside an array either — and real documents put ordered objects inside arrays: `drivers`, `entries`, `rounds`.

## The surface a caller needs

    use OrderedJson.Json.{JsonNull, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject}

    OrderedJson.toPrettyString(2, value)                        -- every value on a line of its own, as the standard module writes it
    OrderedJson.toCompactString(value)                          -- no extraneous whitespace, as the standard module writes it
    OrderedJson.render(value)                                   -- toPrettyString(2, ·), the standard module's own default
    OrderedJson.renderWith(Layout.Inlined(Inline.AtMost(2)), 2, value) -- an object small enough to fit joins its key's line
    OrderedJson.renderWith(Layout.OneLine, 2, value)            -- one line, however many properties it holds

## Where the standard module's names are reused

`toPrettyString` and `toCompactString` are `Util.Json`'s names and its argument order, so switching a caller between the two modules is a change of prefix. `Layout` carries no indent: the standard module keeps the indent an argument, and so does this one.

| `Util.Json`                 | `OrderedJson`                     | bytes |
| --- | --- | --- |
| `toCompactString(j)`        | `toCompactString(j)`              | identical for a document the standard module spells the same way |
| `toPrettyString(indent, j)` | `toPrettyString(indent, j)`       | identical, same argument order |
| `Json`, `instance ToString` | `Json`, `instance ToString`       | the type is named `Json` here too, and `ToString` writes the compact rendering there as here |
| `parse`, `decode`           | not here                          | the standard parser puts an object into a `Map`, so a parsed document's authored order is gone before any encoder could be asked for it |
| `JNull` … `JObject`         | `JsonNull` … `JsonObject`         | deliberately apart: both modules are installed at once, and `JObject` naming a `Map` here as well as there is a trap |

## What the library guarantees

- Pure: no effect annotation, and no dependency.
- A string is quoted and escaped by the standard module, so every character below 0x20 reaches the output escaped.
- Numbers keep the Flix spelling: `JsonInt(42)` writes `42` and `JsonFloat(x)` writes what `Double.toString` gives, so `0.20739060549440685` stays 17 digits rather than becoming the 55-digit `BigDecimal` expansion the standard module writes.
- The two standard-named renderings are compared against the standard module's own output in `TestStandard`, for a document whose keys happen to be in the order a `Map` would sort them. No claim of byte-identity survives a `Float64`.

## What is not the library's business

The rule "an object of at most two properties, each of whose values fits on a line, is written inline" is the consumer's output contract, frozen in its committed bytes and its test suite — so it arrives as an argument, and the `2` is written in `elm-motorsport-analysis` and not here.

Two things the frozen bytes pinned on the library instead. A collapsed object is `{ ... }`, a space inside each brace. And the rule governs objects only: an array of two short strings still takes one element per line.

## The layouts

`Inline` is `Never`, `AtMost(n)`, or `Always` — how many properties an object may have and still be written on the line its key stands on. A value that already spans lines never collapses.

| `Layout`        | array             | object                                                                |
| --------------- | ----------------- | --------------------------------------------------------------------- |
| `Compact`       | `[1,2]`           | `{"k":v}`, however many properties — the standard module's compact bytes |
| `Pretty`        | one line per item | one line per property — the standard module's `Pretty`, the indent being an argument |
| `Inlined(rule)` | one line per item | per property, unless `rule` admits the count and every value fits → one line |
| `OneLine`       | `[1, 2]`          | `{ "k": v, … }`, however many properties                              |

## Consumed by

`elm-motorsport-analysis` writes its timing archive with it: a 25 MB round summary, and 24,146 one-line lap records. Its check is byte identity — the five exported files hash the same before and after any change here, which is the only specification that has ever held.
