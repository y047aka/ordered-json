# ordered-json

A JSON value that writes an object's properties in the order they were authored.

```json
{ "z": 1, "m": 2, "a": 3 }
```

The Flix standard `Util.Json` cannot. It holds an object as `JObject(Map[String, Json])`, whose docstring promises "canonical (sorted) key order on output", and its `JArray` is a closed `Vector[Json]`, so an ordered object cannot sit inside an array either. The module is that file's encoder re-shaped around an ordered object: pure, dependency-free, escaping per RFC 8259.

## Usage

There are three things to the interface:

1. `Json` — the value, with `JObject(List[(String, Json)])` where the standard module has a `Map`.
2. `toCompactString` and `toPrettyString(indent, ·)` — the standard module's names, argument order, and bytes.
3. `renderWith(style, ·)` — the same, under one of four layouts.

```scala
use OrderedJson::OrderedJson.Json
use OrderedJson::OrderedJson.Json.{JNumber, JObject}
use OrderedJson::OrderedJson.{toCompactString, toPrettyString, renderWith, Style, Inline}

let value = JObject(("z", JNumber(1ff)) :: ("m", JNumber(2ff)) :: ("a", JNumber(3ff)) :: Nil);

toCompactString(value)                              // {"z":1,"m":2,"a":3}
renderWith(Style.OneLine, value)                    // { "z": 1, "m": 2, "a": 3 }
toPrettyString(2, value)                            // one property per line, as the standard module writes it
renderWith(Style.Inlined(Inline.AtMost(2), 2), value)   // three properties exceed the rule, so: as above
```

`Style` is `Compact`, `Pretty(indent)`, `Inlined(rule, indent)`, and `OneLine`. `Inlined` writes an object of at most `rule` properties — `Inline` is `Never`, `AtMost(n)`, `Always` — on the line its key stands on, and `OneLine` breaks no line at all, for JSON Lines output. A value that already spans lines never collapses.

## Install

```toml
[dependencies]
"github:y047aka/ordered-json" = { version = "0.1.0", mount = "OrderedJson" }
```

A dependency is reached through a mount, and `ordered-json` cannot be one — a hyphen reads as a minus — so the mount is declared by hand. It is a `use`-line prefix only: a signature writes the type `Json`.

## Numbers

`JNumber(BigDecimal)`, spelled by `BigDecimal.toPlainString`, so a `1.50` keeps its trailing zero and nothing comes out in exponent form; `NaN` and `Infinity` cannot be written at all, a `BigDecimal` holding neither. The trap on the way in: `Float64.tryToBigDecimal` is `new BigDecimal(x)`, which spells `0.20739060549440685` to fifty digits, where `BigDecimal.fromString("${Float64.toString(x)}")` is exact.

## What is not here

`parse` and `decode`, because the standard parser puts an object into a `Map` and the authored order is gone before any encoder could be asked for it. `toRichString`, which needs `RichString` and the colours. Anything else the standard module has can be added; the escaping and the number spelling are already its own code.
