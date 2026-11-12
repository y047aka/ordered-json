# AGENTS.md

The JSON value that keeps an object's properties in the order they were authored, and the layouts it renders them in. Extracted from `elm-motorsport-analysis`, which writes its timing archive with it.

## Where the boundary is

- The library owns `OrderedJson.Json`, the traversal, the escaping, the number spelling, `Style`, `Inline`, and the `{ ... }` padding a collapsed object gets.
- The consumer owns which layout its files use with which `Inline` rule — `Style.Inlined(Inline.AtMost(2), 2)` — and the fact that it appends a key (`index`, `position`) to a value another module wrote. Its `Extra` module does not come here; it only picks a layout now, which is what makes it the consumer's and not ours.
- Where the standard module already named a function, a type, or a case, its name and argument order are reused: `toPrettyString(indent, j)` and `toCompactString(j)`, `Json`, `JNull` … `JString`, `Style`, `write`, `breakIndent`, `writeColon`, `writeIndent`, `writeEscaped`.
- Naming is decided: repo `ordered-json`, module `OrderedJson`, value type `OrderedJson.Json` (the standard's own type name, so the prefix swap is one word), cases `JNull` … `JString`. The cases used to be `JsonNull` … `JsonObject`, on the ground that `JObject` naming a `Map` there and a `List` here is a trap. That ground held a `Vector` too: `JArray` is one in both, and nobody was tripped. The two types are already apart in what their cases hold, and the prefix is what keeps them apart at a call site.
- The enum is the standard module's case for case and in its order, `JNumber(BigDecimal)` included. The only case that differs is `JObject`, which is the library.
- The inline rule governs objects and not arrays, which is a frozen byte-level fact and not an oversight.

## Facts about the standard library already paid for; do not re-derive them

- `Util.Json.Json.JObject` is `Map[String, Json]`, documented as canonical sorted key order. That is the reason this module exists.
- `Util.Json.Json.JArray` is `Vector[Json]` and closed, so it cannot hold an ordered object. The recursive type therefore stays here. This module's `JArray` is a `Vector` too, which is why the standard library's own tests cross the prefix swap unchanged.
- `Util.Json.Json.JNumber` is `BigDecimal`, documented as "lossless round-trip", and it is this module's number now too. The consequence is that getting a `Float64` into a `JNumber` is the caller's business, and it is the one trap here. `Float64.tryToBigDecimal` is `new BigDecimal(x)` — the call Effective Java Item 68 says never to use — and it spells `0.20739060549440685` as `0.207390605494406854436562070986838079988956451416015625`, which is valid JSON, parses back to the same `Float64`, and silently triples an archive. `BigDecimal.fromString("${Float64.toString(x)}")` is exact and is the route `Util.Json.parse` itself takes. `Int32.toBigDecimal` is exact. The library offers no helper for either, which is the consumer's side of the boundary.
- `Eq[BigDecimal]` is numeric, so `JNumber(1) == JNumber(1.0)` is `true` while the two still spell differently, and `BigDecimal.fromString("1.50")` renders `1.50`. Both are things `JInt`/`JFloat` could not say. And `BigDecimal` cannot hold `NaN` or `Infinity`, and `toPlainString` never uses an exponent, so the two limits the split carried went with it.
- The escaping is the standard module's own and unchanged: `writeEscaped`, `writeEscapedChar`, `writeControlEscape`, `hexDigit`. `escapeString` is gone — `richPretty` was its only caller, and making it `pub` to survive the unused-definition check only postponed the question.
- The repository is Apache 2.0, the same license as the Flix standard library, which is why the module's structure, its names, and the docstrings that still describe it are `Util/Json.flix`'s own rather than paraphrases of them. The standard library's own header points at a `LICENSE.md`; this repository's file is `LICENSE`, and the header at the top of `src/OrderedJson.flix` names that one rather than copying the standard's. The one consequence to remember: the license is no longer a reason to reword anything, so a docstring that drifts from the standard's is a decision, not a constraint.
- `Util.Json` has `instance ToString[Json] = toCompactString` and `instance Formattable[Json] = toRichString(2, ·)`. The `ToString` one is here; `Formattable` needs `RichString` and the colours, and is not.
- `Util.Json.toPrettyString(2, j)` gives 2-space indent, `": "` after the key, `{}` and `[]` when empty, one element per line — the same bytes as `Style.Pretty` at indent 2 apart from key order. The comparison is a test now (`TestStandard`), on a document whose keys happen to be in the order a `Map` would sort them, and whose two numbers — `0.20739060549440685` and `1.50` — are ones no `Float64` could have carried.
- The number is spelled the standard's line verbatim, `BigDecimal.toPlainString(n)`. Where `Int32.toString` and `Float64.toString` were, the module now writes what the standard writes, so the last place the two could disagree about a byte is closed.
- The standard module's own layout type, `Style` (`Compact` / `Pretty(Int32)`), is not `pub`. It is here, because a caller has to name the two layouts this library adds. Its `Pretty(Int32)` shape is kept, which is what puts the indent in the style rather than beside it; `Compact` and `OneLine` break no line and so have no indent to carry.
- A pure `let` in Flix is call-by-need: binding a computation above the branch that may discard it costs nothing, and only effects are ordered. `and`, `or`, and the branches of an `if` do short-circuit. Hoisting a walk out of a `match` is therefore not a performance bug — the two shapes of `collapses` measured the same across three paired runs on 4,096 nested objects.
- Flix brings an enum's tags into the enclosing scope only where the enum is its module's namesake. `Util.Json` declares `Json` and so writes `case JArray(v)` bare; `OrderedJson` declares `Json` but is not called `Json`, so the module opens with `use OrderedJson.Json.{JArray, …}`. The standard's own child modules hit the wall from the other side and write `use Util.Json`, which is an unqualified use here; the copies write `use OrderedJson.Json`.
- `Util.Json.parse` puts an object into a `Map`, so an order-preserving `parse` cannot be built on it — the order is gone before any encoder is asked for it. `parse`, `decode`, and `FromJson` are therefore not on the compatibility list, and neither is `toRichString`. All five of the standard's JSON files were pasted in whole and the four unneeded ones deleted again, which is why the module's structure is the standard's and not a paraphrase of it.
- The standard library's own `TestJson.flix` is vendored at `test/OrderedJson/TestJson.flix`, reduced to the 50 encoder tests, and passes unchanged but for `Map#{…}` becoming a `List`. The numbers cross the prefix swap verbatim now, `JNumber(3.14ff)` and `JNumber(Int32.toBigDecimal(n))` included.
- `Util.Json` is the standard library's own module: a project may nest under it, which is why the module could live at `Util.Json.Encode`, but Flix 0.79 refuses a second declaration of it.
- `Util.Json.parse` refuses a duplicate key with `DuplicateKey`, and accepts a raw control character inside a string. It is therefore a fence on key order and not on escaping. It is also the only thing left asked of the standard module, in `TestStandard`.
- A Flix file must be named for the module it declares: `pub mod OrderedJson.JsonPath` lives at `src/OrderedJson/JsonPath.flix`, and a child module cannot be declared until its parent is. Flix reports both as `Mismatched module and file` and `Orphaned module`, and the errors cascade into hundreds.
- Flix string literals have no `\b` or `\f`, but `\uXXXX` works, so a control character is written `"\u0008"` and not built with `Char.toString`. Char literals take both.
- `flix install` resolves `owner/name[@ver]` from GitHub and `flix release` publishes there. There is no local-path dependency.

## Commands

| Command | Purpose |
| --- | --- |
| `flix build` | compile |
| `flix test` | 69 tests |
| `flix build-pkg` | an `.fpkg`, at `artifact/package.fpkg` |
| `flix release` | publish a version to GitHub |

Flix is 0.79.0, the same as the consumer, and the toolchain is otherwise reached through the consumer's Nix flake (`nix develop`, or `nix develop --command flix …` from a checkout of it).

## Verification

The tests are the first half. The second half is the consumer, and it is the only specification that has ever held: its exported files are committed bytes, served over HTTP with a CRC32 `ETag`, and compared served-against-exported in `Server.TestApi`.

    cd <consumer>/backend
    export DATABASE_URL="jdbc:sqlite:.db/motorsport.sqlite"
    flix test                                              # 429 pass, 0 fail
    flix run -- --export --export-only 2025/le_mans_24h \
               --export-only 2025/cota_6h --out ../app/static/wec     # about 7.5s

Then all five written files must still hash to what the consumer has committed:

| File | md5 |
| --- | --- |
| `app/static/wec/index.json` | `f46841bbe1f2e93937ac38736dc87611` |
| `app/static/wec/2025/le_mans_24h.json` | `188122393fccfb1d67b4829440e312aa` |
| `app/static/wec/2025/le_mans_24h_laps.jsonl` | `2c1a8a10df1bfbbd1ef9314583f7c43f` |
| `app/static/wec/2025/cota_6h.json` | `4d03c6ef9ff75cb2dd42b78a6e3f5321` |
| `app/static/wec/2025/cota_6h_laps.jsonl` | `f7e1b10ee573609dc06f8b7859c4a4f1` |

## Comments and committing

Prose breaks its lines only at sentence ends. A comment says only what the code cannot — an outside constraint, a hazard, a decision whose alternatives looked equal — and the reasoning for a change belongs in its commit message. Commit prefixes in use: `feat:` `refactor:` `chore:` `docs:` `build:` `env:` `data:` `fix:`.
