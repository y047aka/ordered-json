# AGENTS.md

The JSON value that keeps an object's properties in the order they were authored, and the layouts it renders them in. Extracted from `elm-motorsport-analysis`, which writes its timing archive with it.

## Where the boundary is

- The library owns `OrderedJson.Value`, the traversal, the escaping, the number spelling, `Layout`, `Inline`, and the `{ ... }` padding a collapsed object gets.
- The consumer owns which layout its files use with which `Inline` rule — `Layout.Inlined(Inline.AtMost(2))` — and the fact that it appends a key (`index`, `position`) to a value another module wrote. Its `Extra` module does not come here; it only picks a layout now, which is what makes it the consumer's and not ours.
- Naming is decided: repo `ordered-json`, module `OrderedJson`, value type `OrderedJson.Value`. The case names stay `JsonNull` … `JsonObject`. Shortening them invites a case named `String` beside the type `String`, and matching the standard `JNull` … `JObject` would name two different things alike — the standard `JObject` holds a `Map`. Rename the path, not the cases. `Layout` stays `Layout`, since it says what the cases are.
- The inline rule governs objects and not arrays, which is a frozen byte-level fact and not an oversight.

## Facts about the standard library already paid for; do not re-derive them

- `Util.Json.Json.JObject` is `Map[String, Json]`, documented as canonical sorted key order. That is the reason this module exists.
- `Util.Json.Json.JArray` is `Vector[Json]` and closed, so it cannot hold an ordered object. The recursive type therefore stays here.
- `Util.Json.Json.JNumber` is `BigDecimal`. A `Float64` enters it through `new BigDecimal(x)`, so `0.20739060549440685` becomes `0.207390605494406854436562070986838079988956451416015625`, and `Int32` and `Float64` become the same case. Numbers stay home-grown.
- `Util.Json.toPrettyString(2, j)` gives 2-space indent, `": "` after the key, `{}` and `[]` when empty, one element per line — the same bytes as `Layout.Expanded` apart from key order, and from any `Float64` it widens to its exact decimal. No claim of byte-identity with the standard module survives a `Float64`.
- `Util.Json` is the standard library's own module: a project may nest under it, which is why the module could live at `Util.Json.Encode`, but Flix 0.79 refuses a second declaration of it.
- `Util.Json.parse` refuses a duplicate key with `DuplicateKey`, and accepts a raw control character inside a string. It is therefore a fence on key order and not on escaping.
- `Eq[BigDecimal]` is `compareTo == 0`, scale-insensitive, so `render → parse → == the expected Json` is sound for floats.
- Flix string literals have no `\b`, `\f` or `\uXXXX`. Char literals do, and `Char.toString('\u0008')` is how a test builds one.
- `flix install` resolves `owner/name[@ver]` from GitHub and `flix release` publishes there. There is no local-path dependency.

## Commands

| Command | Purpose |
| --- | --- |
| `flix build` | compile |
| `flix test` | 30 tests |
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
