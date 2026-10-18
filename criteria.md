# Writing Criteria

Every guide in this repo is written to the same
standard. If you're adding or editing a guide —
human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language,
   never dumbed-down concepts. Explain jargon on
   first use; collect terms in the glossary.
2. **No hype.** No marketing adjectives, no
   "revolutionary," no promises about what
   something will do for the reader.
3. **Honest about limits.** Say what the thing
   *can't* do. State uncertainty instead of
   smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults,
   and specs are either measured or qualified with
   "depends on your setup." If it wasn't tested,
   say so.
5. **Checkable.** Commands are meant to be run,
   with "Check:" blocks showing what success looks
   like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out
   Windows/Mac/Linux differences. Don't assume a
   GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get
   stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and
   points elsewhere for the rest. No guide
   pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after
   examples, symptom → fix. Scannable beats essay.

## Verification notes for this guide

Standard 3 and 4 applied to this guide,
specifically. This is the rare guide with nothing
in the "documented-only" column: jq's entire
everyday surface is one binary in a terminal, so
all of it ran.

**The tool:** `jq-1.7`, already installed on the
build machine at `/usr/bin/jq` (the distro
package; nothing was downloaded). Every command
in every chapter was captured from that binary.

**The data:** all sample files in `examples/` are
invented for this guide — five fictional models,
eight fictional machines, three orders, eight log
events, one service config. `models-min.json` was
produced from `models.json` by `jq -c '.'`, so the
two are the same JSON by construction. Because
the data is fictional, no capture needed
sanitising; commands were run from inside
`examples/` so file names appear exactly as a
reader would type them.

**Verified by running (every quoted output is a
capture, transcribed into the chapter):**

- Pretty-printing a minified file with `.`,
  compacting with `-c`, key order preserved on
  output, and `-S` sorting keys.
- Validation: `broken.json` (a missing comma)
  produced jq's real parse error — "Expected
  separator between values at line 4, column 37"
  — and exit code 5.
- Paths: nested keys, negative indexes, slices,
  `.[]` iteration, `.[]?`, `keys`, `length` on
  arrays/objects/strings, `type`, `to_entries`,
  and `null` for a missing key, a missing
  top-level key, and indexing into `null`.
- `select` with `>=`, `==`, `and`/`or`, and a
  `startswith` test; `//` replacing an absent key
  in a stream and as `// []` inside a reshaping;
  `has` counting 4 of 5; `in` on a literal object;
  `type == "array"` excluding the one machine
  whose key is absent.
- Reshaping: constructed objects with computed
  fields (context length ÷ 1024 → 32/32/8/4/16),
  order totals from line items (50, 14.5, 40 —
  chosen to be exact in decimal), the `{id}`
  shorthand, array construction, interpolation
  with and without `-r`, `@csv` and `@tsv` rows,
  and `@base64` of a model name.
- Aggregation over the inventory: `map(.ram_gb)`
  totalling 360 and averaging 45, `sort_by`,
  `unique` on roles and OSes, `unique_by(.os)`,
  `reverse`, `max`, `min_by` naming garnet-07,
  and `group_by(.location)` counting 2/4/2.
- `flatten`: families levelled and deduplicated,
  and the all-the-way-down behaviour on
  `[[1, [2, 3]], 4]`. Also verified: `group_by`
  in 1.7 sorts by its key itself (shuffled input
  still grouped whole), despite the traditional
  idiom sorting first — the chapter says so.
- The worked example end to end, step by step:
  free-percent roundings (21/10/73/9) hand-checked
  against the inventory (412/2000 = 20.6%), the
  sorted table, the under-15% watchlist (the same
  two names), and the summary object (8, 4, 360).
- Streams: per-value filtering of `events.json`,
  `length` answering 4 eight times (four keys per
  event), `-s` answering 8, the error count of 2,
  slurping across two files (8 + 1 = 9), and
  `input`/`[inputs]` under `-n`.
- `-e` exit statuses, shown with `$?`: `true` →
  0, `false` → 1, no output → 4.
- Feeding data: `--arg` (count 4), `--argjson`
  (five machines ≥ 32 GB), both together (three
  servers), the `--arg`-is-a-string /
  `--argjson`-is-a-number `type` pair, `$ENV`
  with a variable set for the command, `--slurpfile`
  counting 8 events, `--args`/`$ARGS`, and
  `jq -f summary.jq` producing the shipped
  summary — which cross-checks against chapters
  5 and 6 (360 GB, roles 2/4/2, same low-disk
  pair).
- Changing JSON, on `settings.json`: `=`
  assignment (literal and document-referenced),
  the file provably unchanged afterwards
  (`retries` still 3), `|=` incrementing to 4,
  `|=` with a document reference erroring for real
  ("Cannot index number with string") — which is
  the chapter's `=`/`|=` contrast, and a better
  one than a silent difference would have been.
  `del` on a key and on an array element, and
  `paths` listing all ten paths.
- The destructive redirect, run on a throwaway
  copy: `jq … scratch.json > scratch.json` left a
  0-byte file, exit code 0, no message. The safe
  ritual (`> settings.new.json && mv`) was then
  run for real and read back (`retries` → 5);
  the shipped `settings.json` was restored to its
  original bytes afterwards, so readers start
  from 3.
- Errors, all captured with exit codes: the
  compile error for an unfinished filter (exit
  3, with jq's filter echo), "Cannot iterate over
  null" ending a run after five real output lines
  (exit 5), the three fixes (`[]?`, `// []`,
  `try … catch`) each producing the full seven
  lines, "number … and string … cannot be added",
  "Cannot index array with string", and object +
  array addition refused. Also verified: mixed
  arrays sort without complaint (`[3, "ten", 1]`
  → `[1, 3, "ten"]`) under jq's total order — the
  expected "cannot be sorted" error does not
  exist, and the chapter says so rather than
  inventing one.
- Output options: `--tab` (the capture contains
  real tab characters), and number handling:
  `9007199254740993` printed as written, and
  `9007199254740992` after `+ 0` — the literal is
  preserved until arithmetic converts it to a
  double.
- Scripts: a `-r` stream feeding a `while read`
  loop (five lines), an `if jq -e …` branch
  taken, a value captured into a shell variable,
  and the `pipefail` pair — the same failing
  filter in a pipeline exits 0 without `pipefail`
  and 5 with it, with `wc -l` counting the same
  five partial lines both times.

**Documented-only (not run), and why:**

- The `curl | jq` pipeline in chapter 11 is
  shown as a pattern, not a capture: no external
  API was called. The chapter says so in place,
  and uses the shipped `models.json` — the same
  shape of response — for every actual output.
- Colour output (`-C`/`-M`): `-M` was run and
  matches plain output; colour itself can't be
  shown in print, and the chapter says to try it
  on the reader's own terminal rather than
  describing shades.
- Installation on the reader's machine
  (`apt`/`brew`/release binary) is described, not
  performed — the build machine already had jq.
- `--seq` framing, `--stream`, recursive
  definitions, modules, and the date builtins are
  named and scoped out in the text, not taught.

A note on versions: exit code 5 for parse errors
is jq 1.7's behaviour as captured; older 1.6
installs differ in a few message wordings and in
exit-code details. Where a claim in the chapters
depends on the version, the text says 1.7.
