# ordered-json

A JSON value that writes an object's properties in the order they were authored.

    { "carNumber": "007", "lapNumber": 1, "driverName": "Tom GAMBLE" }

The Flix standard `Util.Json` cannot write that. It holds an object as `JObject(Map[String, Json])`, and its own docstring says the map "gives canonical (sorted) key order on output". Its `JArray` is `Vector[Json]`, closed over `Json`, so an ordered object cannot sit inside an array either — and real documents put ordered objects inside arrays: `drivers`, `entries`, `rounds`. Both halves of that sentence are why a separate value type exists.

## The surface a caller needs

    use OrderedJson.Value.{JsonNull, JsonBool, JsonInt, JsonFloat, JsonString, JsonArray, JsonObject}

    OrderedJson.render(value)                                   -- every value on a line of its own, 2-space indent
    OrderedJson.renderWith(Layout.Inlined(Inline.AtMost(2)), v) -- an object small enough to fit joins its key's line
    OrderedJson.renderWith(Layout.OneLine, v)                   -- one line, however many properties it holds

## What the library guarantees

- Pure: no effect annotation, no dependency, and no `region` reaching the caller.
- A string is quoted and escaped by the standard module — `Util.Json.toCompactString(Util.Json.Json.JString(s))` — so every character below 0x20 reaches the output escaped and a name holding one is still a file a browser parses.
- Numbers keep the Flix spelling: `JsonInt(42)` writes `42`, and `JsonFloat(x)` writes what `Double.toString` gives, so `0.20739060549440685` stays 17 digits rather than becoming the 55-digit `BigDecimal` expansion.
- `Layout.Expanded` is byte-identical to `Util.Json.toPrettyString(2, ·)` apart from key order, and 2 is the standard module's own default (`Formattable[Json]` is `toRichString(2, j)`).

## What is not the library's business

The rule "an object of at most two properties, each of whose values fits on a line, is written inline" is the consumer's output contract: it is frozen in committed bytes and in an application test suite. So the rule arrives as an argument. `elm-motorsport-analysis` passes `Layout.Inlined(Inline.AtMost(2))`, and the `2` is written in its own source and not here.

Two things the library keeps, because the frozen bytes pinned them regardless of who chose them. A collapsed object is `{ ... }`, a space inside each brace — `Layout.OneLine` cannot write the JSON Lines output the consumer needs without it. And the rule governs objects only: under `Layout.Inlined(Inline.AtMost(2))` an array of two short strings still takes one element per line, which is why `{ "drivers": [ "a", "b" ] }` never appears in the archive.

## The layouts

`Inline` is `Never`, `AtMost(n)`, or `Always` — how many properties an object may have and still be written on the line its key stands on. A value that already spans lines never collapses, whatever the rule says.

| `Layout`          | array               | object                                                       |
| ----------------- | ------------------- | ------------------------------------------------------------ |
| `Expanded`        | one line per item   | one line per property                                        |
| `Inlined(rule)`   | one line per item   | per property, unless `rule` admits the count and every value fits → one line |
| `OneLine`         | `[1, 2]`            | `{ "k": v, … }`, however many properties                     |

## Consumed by

`elm-motorsport-analysis` writes its timing archive with it: a 25 MB round summary, and 24,146 one-line lap records across the two rounds it keeps. The consumer's check is byte identity — the five exported files hash the same before and after any change here, which is the only specification that has ever held.
