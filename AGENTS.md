# AGENTS.md

The JSON value that keeps an object's properties in the order they were authored, and the layouts it renders them in. Extracted from `elm-motorsport-analysis`, which does not reference it yet — the verification below is the check it must pass when it does.

## Where the boundary is

- The library owns `OrderedJson.Json`, the traversal, the escaping, the number spelling, `Style`, `Inline`, and the `{ ... }` padding a collapsed object gets.
- The consumer owns which layout its files use with which `Inline` rule — `Style.Inlined(Inline.AtMost(2), 2)` — and the fact that it appends a key (`index`, `position`) to a value another module wrote. Its `Extra` module does not come here; it only picks a layout now, which is what makes it the consumer's and not ours.
- Where the standard module already named a function, a type, or a case, its name and argument order are reused. README's table is the inventory.
- Naming is decided: repo `ordered-json`, module `OrderedJson`, value type `OrderedJson.Json`, and the standard module's own case names. `JObject` naming a `Map` there and a `List` here is the trap to watch; the prefix is what keeps the two types apart at a call site.

## Facts about the standard library already paid for; do not re-derive them

- `Util.Json.Json.JObject` is `Map[String, Json]`, documented as canonical sorted key order. That is the reason this module exists.
- `Util.Json.Json.JArray` is `Vector[Json]` and closed, so it cannot hold an ordered object. The recursive type therefore stays here. This module's `JArray` is a `Vector` too, which is why the standard library's own tests cross the prefix swap unchanged.
- `Util.Json.Json.JNumber` is `BigDecimal`, documented as "lossless round-trip", and it is this module's number. `Eq[BigDecimal]` is numeric, so `JNumber(1) == JNumber(1.0)` is `true` while the two still spell differently, and `BigDecimal.fromString("1.50")` renders `1.50`. Getting a `Float64` into one is the caller's business and the one trap here; the section of that name in README owns the two routes, and there is no helper here.
- The escaping and the number are the standard module's own, unchanged: `writeEscaped`, `writeEscapedChar`, `writeControlEscape`, `hexDigit`, and `BigDecimal.toPlainString(n)`.
- The repository is Apache 2.0, the same license as the Flix standard library, which is why the module's structure, its names, and the docstrings that still describe it are `Util/Json.flix`'s own. The standard library's header points at a `LICENSE.md`; this repository's file is `LICENSE`. The one consequence to remember: the license is no longer a reason to reword anything, so a docstring that drifts from the standard's is a decision, not a constraint.
- `Util.Json` has `instance ToString[Json] = toCompactString` and `instance Formattable[Json] = toRichString(2, ·)`. The `ToString` one is here; `Formattable` needs `RichString` and the colours, and is not.
- `Util.Json.toPrettyString(2, j)` gives 2-space indent, `": "` after the key, `{}` and `[]` when empty, one element per line — the same bytes as `Style.Pretty` at indent 2 apart from key order. `TestStandard` compares them.
- The standard module's own layout type, `Style` (`Compact` / `Pretty(Int32)`), is not `pub`, so it is copied here rather than reused. Its `Pretty(Int32)` shape is kept, which is what puts the indent in the style rather than beside it.
- A pure `let` in Flix is call-by-need: binding a computation above the branch that may discard it costs nothing, and only effects are ordered. `and`, `or`, and the branches of an `if` do short-circuit. Hoisting a walk out of a `match` is therefore not a performance bug.
- Flix brings an enum's tags into the enclosing scope only where the enum is its module's namesake. `Util.Json` declares `Json` and so writes `case JArray(v)` bare; `OrderedJson` declares `Json` but is not called `Json`, so the module opens with `use OrderedJson.Json.{JArray, …}`.
- `Util.Json.parse` puts an object into a `Map`, so an order-preserving `parse` cannot be built on it — the order is gone before any encoder is asked for it. It refuses a duplicate key with `DuplicateKey`, and accepts a raw control character inside a string, so it is a fence on key order and not on escaping.
- The standard library's own `TestJson.flix` is vendored at `test/OrderedJson/TestJson.flix`, reduced to the 50 encoder tests, and passes unchanged but for `Map#{…}` becoming a `List`.
- `Util.Json` is the standard library's own module: a project may nest under it, which is why the module could live at `Util.Json.Encode`, but Flix 0.79 refuses a second declaration of it.
- A Flix file must be named for the module it declares: `pub mod OrderedJson.JsonPath` lives at `src/OrderedJson/JsonPath.flix`, and a child module cannot be declared until its parent is. Flix reports both as `Mismatched module and file` and `Orphaned module`, and the errors cascade into hundreds.
- Flix string literals have no `\b` or `\f`, but `\uXXXX` works, so a control character is written `"\u0008"` and not built with `Char.toString`. Char literals take both.
- `flix install` resolves `owner/name[@ver]` from GitHub, and a dependency is declared as `"github:owner/name" = { version, mount }`. There is no local-path dependency.
- A dependency is reached through a mount, and `ordered-json` cannot be one: a mount is a letter followed by letters, digits, or underscores, and a hyphen reads as a minus. The consumer declares `mount = "OrderedJson"` and writes `use OrderedJson::OrderedJson.{…}`. The mount is a `use`-line prefix only, and a type is still written `Json`.
- The `package` table of `flix.toml` accepts only `version`, `repository`, and `flix` in 0.79 — `name`, `description`, and `licenses` there fail the manifest, which is why the license is carried by `LICENSE` and the file headers and not by the metadata.
- `flix release` refuses without `repository`, takes its token from `--github-token`, a `.GITHUB_TOKEN` file at the root, or `GITHUB_TOKEN`, and publishes the tag `v<version>`. The `.fpkg` ships `README.md`, `flix.toml`, and `src/` and nothing else, so the README is the distributed documentation and `LICENSE` is not in the package.

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
    flix test
    flix run -- --export --export-only 2025/le_mans_24h \
               --export-only 2025/cota_6h --out ../app/static/wec

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
