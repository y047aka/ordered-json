# AGENTS.md

The JSON value that keeps an object's properties in the order they were authored, and the layouts it renders them in. Extracted from `elm-motorsport-analysis`, which writes its timing archive with it.

## Where the boundary is

- The library owns `OrderedJson.Json`, the traversal, the escaping, the number spelling, `Style`, `Inline`, and the `{ ... }` padding a collapsed object gets.
- The consumer owns which layout its files use with which `Inline` rule — `Style.Inlined(Inline.AtMost(2), 2)` — and the fact that it appends a key (`index`, `position`) to a value another module wrote. Its `Extra` module does not come here; it only picks a layout now, which is what makes it the consumer's and not ours.
- Where the standard module already named a function, a type, or a case, its name and argument order are reused: `toPrettyString(indent, j)` and `toCompactString(j)`, `Json`, `JNull` … `JString`, `Style`, `write`, `breakIndent`, `writeColon`, `writeIndent`, `writeEscaped`.
- Naming is decided: repo `ordered-json`, module `OrderedJson`, value type `OrderedJson.Json` (the standard's own type name, so the prefix swap is one word), cases `JNull` … `JString`. The cases used to be `JsonNull` … `JsonObject`, on the ground that `JObject` naming a `Map` there and a `List` here is a trap. That ground held a `Vector` too: `JArray` is one in both, and nobody was tripped. The two types are already apart in what their cases hold, and the prefix is what keeps them apart at a call site.
- The one name the standard module's cannot be reused is the number: `JNumber` names a `BigDecimal` there, and this module has `JInt(Int32)` and `JFloat(Float64)`.
- The inline rule governs objects and not arrays, which is a frozen byte-level fact and not an oversight.

## Facts about the standard library already paid for; do not re-derive them

- `Util.Json.Json.JObject` is `Map[String, Json]`, documented as canonical sorted key order. That is the reason this module exists.
- `Util.Json.Json.JArray` is `Vector[Json]` and closed, so it cannot hold an ordered object. The recursive type therefore stays here. This module's `JArray` is a `Vector` too, which is why the standard library's own tests cross the prefix swap unchanged.
- `Util.Json.Json.JNumber` is `BigDecimal`. A `Float64` enters it through `new BigDecimal(x)`, so `0.20739060549440685` becomes `0.207390605494406854436562070986838079988956451416015625`, and `Int32` and `Float64` become the same case. Numbers stay home-grown.
- The escaping is the standard module's own and unchanged: `writeEscaped`, `writeEscapedChar`, `writeControlEscape`, `hexDigit`. `escapeString` is gone — `richPretty` was its only caller, and making it `pub` to survive the unused-definition check only postponed the question.
- The repository is Apache 2.0, the same license as the Flix standard library, which is why the module's structure, its names, and the docstrings that still describe it are `Util/Json.flix`'s own rather than paraphrases of them. `LICENSE.md` is the file name the standard library's own header points to. The one consequence to remember: the license is no longer a reason to reword anything, so a docstring that drifts from the standard's is a decision, not a constraint.
- `Util.Json` has `instance ToString[Json] = toCompactString` and `instance Formattable[Json] = toRichString(2, ·)`. The `ToString` one is here; `Formattable` needs `RichString` and the colours, and is not.
- `Util.Json.toPrettyString(2, j)` gives 2-space indent, `": "` after the key, `{}` and `[]` when empty, one element per line — the same bytes as `Style.Pretty` at indent 2 apart from key order, and from any `Float64` it widens to its exact decimal. No claim of byte-identity with the standard module survives a `Float64`. The comparison is a test now (`TestStandard`), on a document whose keys happen to be in the order a `Map` would sort them.
- The standard module spells a number `BigDecimal.toPlainString(n)` where this one writes `Int32.toString(n)` and `Float64.toString(n)`. Both give `1` for a parsed `1`; they part company at any `Float64`.
- The standard module's own layout type, `Style` (`Compact` / `Pretty(Int32)`), is not `pub`. It is here, because a caller has to name the two layouts this library adds. Its `Pretty(Int32)` shape is kept, which is what puts the indent in the style rather than beside it; `Compact` and `OneLine` break no line and so have no indent to carry.
- Flix brings an enum's tags into the enclosing scope only where the enum is its module's namesake. `Util.Json` declares `Json` and so writes `case JArray(v)` bare; `OrderedJson` declares `Json` but is not called `Json`, so the module opens with `use OrderedJson.Json.{JArray, …}`. The standard's own child modules hit the wall from the other side and write `use Util.Json`, which is an unqualified use here; the copies write `use OrderedJson.Json`.
- `Util.Json.parse` puts an object into a `Map`, so an order-preserving `parse` cannot be built on it — the order is gone before any encoder is asked for it. `parse`, `decode`, and `FromJson` are therefore not on the compatibility list, and neither is `toRichString`. All five of the standard's JSON files were pasted in whole and the four unneeded ones deleted again, which is why the module's structure is the standard's and not a paraphrase of it.
- The standard library's own `TestJson.flix` is vendored at `test/OrderedJson/TestJson.flix`, reduced to the 50 encoder tests, and passes unchanged but for `Map#{…}` becoming a `List` and `JNumber` becoming `JInt`/`JFloat`.
- `Util.Json` is the standard library's own module: a project may nest under it, which is why the module could live at `Util.Json.Encode`, but Flix 0.79 refuses a second declaration of it.
- `Util.Json.parse` refuses a duplicate key with `DuplicateKey`, and accepts a raw control character inside a string. It is therefore a fence on key order and not on escaping. It is also the only thing left asked of the standard module, in `TestStandard`.
- A Flix file must be named for the module it declares: `pub mod OrderedJson.JsonPath` lives at `src/OrderedJson/JsonPath.flix`, and a child module cannot be declared until its parent is. Flix reports both as `Mismatched module and file` and `Orphaned module`, and the errors cascade into hundreds.
- Flix string literals have no `\b` or `\f`, but `\uXXXX` works, so a control character is written `"\u0008"` and not built with `Char.toString`. Char literals take both.
- `flix install` resolves `owner/name[@ver]` from GitHub and `flix release` publishes there. There is no local-path dependency.

## Commands

| Command | Purpose |
| --- | --- |
| `flix build` | compile |
| `flix test` | 72 tests |
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
