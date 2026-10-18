# jq for Mere Mortals

**jq** is the standard command-line tool for
asking questions of JSON — and JSON is what every
API returns, every modern config file is written
in, and every log seems to be full of. Raw, it
usually arrives as one unreadable line. jq reads
it structurally: you write a small *filter* naming
what you want, and jq walks the data and prints
exactly that — pretty-printed, selected, reshaped,
totalled, or rewritten.

This guide teaches the filter language the way it
is actually used: the identity filter that doubles
as a validator, paths and `select`, building new
objects, streams and slurping, changing JSON
without destroying the file it lives in, and the
error messages read closely enough to be useful.

Every command in this guide was run for real
(jq 1.7) against the sample files in `examples/` —
fictional models, machines, orders, and events,
invented for the purpose — so every output can be
reproduced byte for byte, including the failures:
the parse error, the iterate-over-null that dies
halfway through its own output, and the redirect
that empties a file. There are no documented-only
corners in this one; jq's whole everyday surface
runs in a terminal, so this guide ran it.

It assumes you use a terminal and have met JSON —
even if only as output something else printed. No
programming experience is required; where jq's
language grows past what a beginner needs, the
guide says so and points at the exit.

## What this guide covers

- [**What jq is**](what-jq-is.md) — the filter
  idea; `.` as pretty-printer and validator;
  getting jq; the sample files
- [**First filters**](first-filters.md) — paths
  into objects and arrays, `.[]`, and why a missing
  key is `null` rather than an error
- [**Selecting**](selecting.md) — `select` and
  comparisons, the `//` alternative operator,
  testing presence and type
- [**Reshaping output**](reshaping-output.md) —
  building objects and arrays, interpolation,
  `@csv`/`@tsv`, and raw output with `-r`
- [**Arrays and aggregation**](arrays-and-aggregation.md) —
  `map`, `sort_by`, `unique`, `add`, `group_by`,
  and an honest look at `flatten`
- [**A worked example**](worked-example.md) — a
  disk report grown one pipe at a time, every
  intermediate output real
- [**Streams and multiple files**](streams-and-multiple-files.md) —
  one JSON value after another, slurping with
  `-s`, `inputs`, and `-e` exit statuses
- [**Feeding jq data**](feeding-jq-data.md) —
  `--arg` and `--argjson`, `$ENV`, `--slurpfile`,
  and filters kept in files with `-f`
- [**Changing JSON**](changing-json.md) — `=`
  versus `|=`, `del`, and the temp-file ritual
  that replaces in-place editing
- [**Errors and debugging**](errors-and-debugging.md) —
  parse, compile, and runtime errors read closely;
  the defensive patterns; numbers told honestly
- [**jq in scripts and pipelines**](jq-in-scripts.md) —
  shell loops, `if` tests, `pipefail`, the `curl`
  pipeline, and when to reach for a real language
- [**Glossary**](glossary.md) — the terms,
  collected in one place

## What it doesn't cover

jq as a programming language in the large —
recursive definitions, modules, the streaming
parser (`--stream`), and the date/time builtins
beyond naming them; other JSON processors
(`yq`, `fq`, and friends); and JSON itself as a
format, which the guide assumes you've met. The
jq manual covers all of it and is genuinely good.

## How to use this guide

Copy `examples/` somewhere, read the first two
chapters with a terminal open, and type the
commands. By the worked example you have the
everyday tool; the later chapters are for the day
a filter meets data that fights back — which, with
JSON, is a day that comes for everyone.
