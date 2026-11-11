# 引き継ぎ: 順序保存 JSON エンコーダを `ordered-json` として独立リポジトリにする

## 目的
Flix の JSON エンコーダ 1 組を、このリポジトリから独立リポジトリのライブラリ **`ordered-json`** へ移す。
存在理由はただ一つ、**オブジェクトのプロパティ順を著者が書いた順に保つ**こと。標準 `Util.Json` は `JObject(Map[String, Json])` を使い、docstring に "gives canonical (sorted) key order on output" と明記されている。

## 命名は確定している（再検討しない）
- リポジトリ / package id: `ordered-json`（`flix install` の `owner/name` 慣習に従う）
- モジュール: `OrderedJson`、値の型: `OrderedJson.Value`
- ケース名は `JsonNull` … `JsonObject` のまま。**パスだけ変えてケース名は据え置く**。短縮すると型 `String` と並ぶケース名 `String` を招き、標準の `JNull` … `JObject` に寄せると同名異物（あちらは `Map`）になる
- `Layout` は `Layout` のまま（標準の `Style` は非 `pub` なので独立後は衝突しないが、`Layout` の方がケースを説明する）
- `Extra` は ≤2 規則を持つ限りアプリ側に残す。ライブラリの公開表面は `Value` + `renderWith(Layout, value)`（＋ `render`）が正しい姿

## 現物の寸法と所在（アプリ側、Flix 0.79）
- `backend/src/Util/Json/Encode.flix`（69 行）: `pub enum JsonValue`（7 ケース）、`pub enum Layout with Eq`（`Expanded` / `Inlined` / `OneLine`）、`render`、`renderWith(layout, value)`、`renderAt(layout, spaces, value)`、`array` / `object` / `onOwnLines` / `fitsOnOneLine` / `escapeString`
- `backend/src/Util/Json/Encode/Extra.flix`（24 行）: `render` = `renderWith(Layout.Inlined, ·)`、`renderOnOneLine` = `renderWith(Layout.OneLine, ·)`
- 純粋（効果アノテーションなし）、依存ゼロ、標準から 1 点だけ借用中: `escapeString(s) = Util.Json.toCompactString(Util.Json.Json.JString(s))`（引用符込みの JSON 文字列リテラルを返す）
- 移るテスト: `backend/test/Util/TestJson.flix`（10 件）＋ `backend/test/Util/Json/TestEncodeExtra.flix`（18 件）＝ 28 件 191 行
- 残すもの: `Round/Render.flix` の `withIndex` / `withPosition`（他モジュールが書いたオブジェクトへアプリが `index` / `position` を**追記**する箇所。ライブラリに順序保持オブジェクトを壊される余地があってはいけない）

## 唯一の未決設計判断
「≤2 プロパティかつ全値が行に収まるなら inline」と `{ ... }` の内側パディングは**アプリの出力仕様**で、コミットされたバイトとアプリのテストで凍結されている。ライブラリがこれを知るままだと動機が反故になるので、**レイアウトが自分の inline 規則を持つ形**へ開く。案: (a) `Layout` が規則を持つ、(b) `renderWith(layout, policy, value)`、(c) inline 判定だけをアプリに公開し `Layout` は 2 値のまま。

## 凍結仕様の検証手順（移した後に必ず通す）
1. `cd backend && flix test` → **458 pass / 0 fail**（`TestEncodeExtra` の 18 完全一致が 3 レイアウトを固定）
2. `export DATABASE_URL="jdbc:sqlite:.db/motorsport.sqlite" && flix run -- --export --export-only 2025/le_mans_24h --export-only 2025/cota_6h --out ../app/static/wec` → 約 7.5 秒（flake 経由なら `nix run .#cli-export`）。`flix` は `/nix/store/fizhhcp9vqsizszzhwsn8lcrpz5n06yz-flix-0.79.0/bin/flix` で直接実行できた
3. 出力 5 ファイルが変更前後で md5 一致すること（**バイト不変が仕様**）:
   - `app/static/wec/index.json` — `f46841bbe1f2e93937ac38736dc87611`
   - `app/static/wec/2025/le_mans_24h.json` — `188122393fccfb1d67b4829440e312aa`
   - `app/static/wec/2025/le_mans_24h_laps.jsonl` — `2c1a8a10df1bfbbd1ef9314583f7c43f`
   - `app/static/wec/2025/cota_6h.json` — `4d03c6ef9ff75cb2dd42b78a6e3f5321`
   - `app/static/wec/2025/cota_6h_laps.jsonl` — `f7e1b10ee573609dc06f8b7859c4a4f1`

   laps JSONL は 24,146 行すべてが 1 行レンダラの出力
4. サーバとエクスポートの一致: `Server.TestApi` の `theTwoRootsNameTheSameRounds` と `aRoundIsTheRoundTheExportWouldHold`
5. 合成ドキュメントが標準パーサに通ること: `Round.TestRender` の 2 件（標準 `Util.Json.parse` は重複キーを `DuplicateKey` で拒否する。効くことは実測済み — `Metadata.toJson` に `index` を足すと該当テストだけが `duplicate key 'index' at offset 1204` で落ちる）

## Flix 0.79 のパッケージ機構で確認済みの事実（再調査不要）
- `flix install` / `remove` / `upgrade` の引数は `owner/name[@ver]` 形式のみ（GitHub 解決）。ローカルパス依存のオプションは `--help` に出ない
- `flix release` は GitHub へ公開、`flix build-pkg` は `.fpkg` を作る（アプリの `backend/.gitignore` に `*.fpkg` あり）
- `flix.toml` の `[jar-dependencies]` は存在する（jar 内に `jarDependencies` を確認）。`backend/flix.toml` は `[mvn-dependencies]` 使用中
- **同一リポジトリ内の別プロジェクトを依存に取る機構はない** → 独立リポジトリ化は正しい。アプリ側の取り込みは (a) GitHub + `flix release` + `flix install`、(b) `flix build-jar` → `[jar-dependencies]`、の 2 択。flake には stale 検出の定型がある: `if [ ! -f "$jar.ok" ] || [ -n "$(find src flix.toml -newer "$jar.ok")" ]; then flix build-jar; fi`

## 標準 `Util.Json` との境界で既に分かっていること（再調査不要）
- `JArray(Vector[Json])` は閉じており、順序保持オブジェクトを配列内に置けない（実データ: `drivers`、`entries`、`seasons`→`rounds`）。よって型を標準に寄せられない
- `JNumber(BigDecimal)` が Int32/Float64 を消す。`Float64` は `new BigDecimal(x)` で入るので `0.20739060549440685` が 55 桁の完全展開になる
- 標準 `toPrettyString(2, j)` のレイアウトは本ライブラリの `Expanded` と**バイト一致**（2 スペース、`": "`、空は `{}`/`[]`、各要素独行）。標準の既定 indent も 2（`Formattable[Json]` = `toRichString(2, j)`）
- 標準 `parse` は重複キーを拒否するが raw control char は通す（`scanString` が reject しない）ので、エスケープの回帰は標準 parse では捕まらない
- `Eq[BigDecimal]` は `compareTo == 0`（scale 非依存）なので `render → parse → == 期待 Json` は float でも sound
- Flix の**文字列**リテラルに `\b` `\f` `\uXXXX` は無い。`char` リテラル `'\u0008'` は有効（テストで使用済み）
- 標準 `Util.Json` の `Style`（`Compact`/`Pretty(Int32)`）は非 `pub`

## 改名の値段（測済み）
`Encode.render` 31 / `Extra.render` 23 / `JsonString` 83 / `JsonObject` 69 / `JsonInt` 35 / `JsonArray` 26 / `JsonValue`（型注釈）39。大半は `use` 行なので機械的だが広い。

## 第 2 の利用者候補（アプリ側に残っている手書き JSON）
- `circuits/src/Geometry/Write.flix` の `text` / `escaped` / `escape`（`"` `\` `\n` `\r` `\t` の 5 規則。`Encode` から削ったものと同一形。served geometry を通る 28 文字列は分岐なしと検証済み）
- `circuits/src/Midline.flix` が順序付き JSON を手組みし、値だけ標準 `toCompactString` に投げている

## 併せて渡す seed 一式
`ordered-json/README.md`（保証と公開表面とレイアウト表）、`ordered-json/AGENTS.md`（境界・標準で判明済みの事実・コマンド・検証手順・改名の値段・散文とコミットの作法）、`ordered-json/flix.toml`、`ordered-json/.gitignore`。これらが新リポジトリの仕様書を兼ねる。

## 引き継ぎ先の作法も元リポジトリに合わせる
- 散文の改行は**文末でのみ**（1 文 1 行）。コメントは「コードが言えないこと」だけ書く（外部制約・hazard・対等に見えた決定）。履歴はコミットメッセージへ
- コミットは `feat:` `refactor:` `chore:` `docs:` `build:` `env:` `data:` `fix:` を使用。主語は長く説明的に
