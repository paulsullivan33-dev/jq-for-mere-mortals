# What jq Is

JSON is how programs talk to each other now. APIs
return it, config files are written in it, logs are
full of it. And in its natural state — the state
programs actually send — it looks like this:

```
$ head -c 200 models-min.json
{"models":[{"capabilities":["completion","tools"],"details":{"context_length":32768,"embedding_length":4096,"families":["ember"],"family":"ember","format":"gguf","parameter_size":"7.2B","parent_model"
```

That is the first 200 characters of a 2,066-byte
file, and the whole file is one line. Somewhere in
there are five AI models with names, sizes, and
capabilities. You could read it with `grep`, but
grep doesn't know where one value ends and the next
begins; it matches characters, not structure. What
you want is a tool that understands the structure
and answers questions about it.

**jq** is that tool. It is a filter in the Unix
sense: JSON goes in one end, a *filter* — a small
expression written in jq's own language — says what
to do with it, and JSON comes out the other end.

```
JSON in  →  filter  →  JSON out
```

Everything in this guide is a variation on that
shape. The filters get longer, but the shape never
changes.

## The identity filter: pretty-printer and validator

The simplest filter is a single dot, `.`, which
means "the input, unchanged." That sounds useless
until you watch what jq does while passing it
through: it parses the JSON and prints it again,
properly indented. Feed jq the one-line file and
ask for just the first model:

```
$ jq '.models[0]' models-min.json
{
  "capabilities": [
    "completion",
    "tools"
  ],
  "details": {
    "context_length": 32768,
    "embedding_length": 4096,
    "families": [
      "ember"
    ],
    "family": "ember",
    "format": "gguf",
    "parameter_size": "7.2B",
    "parent_model": "",
    "quantization_level": "Q4_K_M"
  },
  "digest": "sha256:9f2c41aa07b3d5e89c1042f6a8b7d3e5c0918273645a4b3c2d1e0f9a8b7c6d5e",
  "model": "ember-2:7b",
  "modified_at": "2026-09-14T09:26:44.221Z",
  "name": "ember-2:7b",
  "size": 4378221568
}
```

Without the `[0]` the same command prints all five
models, each in this shape — 114 lines from a
one-line file. This is most people's first and most
frequent jq command, and it's worth being clear
about why it works: jq cannot print what it hasn't
parsed, so `.` doubles as a **validator**. If the
JSON is broken, you get no pretty output — you get
the error, with a position:

```
$ jq '.' broken.json
jq: parse error: Expected separator between values at line 4, column 37
```

(`broken.json` in `examples/` is a deliberately
damaged file — a missing comma — used again in the
Errors chapter.) Try that on any file ending in
`.json` before you trust it; it costs nothing.

Going the other way, `-c` prints each value
compactly, one per line — the format other programs
usually want:

```
$ jq -c '.models[0]' models.json
{"capabilities":["completion","tools"],"details":{"context_length":32768,"embedding_length":4096,"families":["ember"],"family":"ember","format":"gguf","parameter_size":"7.2B","parent_model":"","quantization_level":"Q4_K_M"},"digest":"sha256:9f2c41aa07b3d5e89c1042f6a8b7d3e5c0918273645a4b3c2d1e0f9a8b7c6d5e","model":"ember-2:7b","modified_at":"2026-09-14T09:26:44.221Z","name":"ember-2:7b","size":4378221568}
```

That's exactly how `models-min.json` was made: it
is `jq -c '.' models.json`, the same data wearing
the other outfit.

## Where jq sits

jq doesn't fetch, store, or edit anything on its
own. It lives in the middle of pipelines:

- a file on the left: `jq '…' data.json`
- a program's output on the left:
  `some-api-tool | jq '…'`
- nothing on the left at all, with `-n`, when the
  filter itself builds the value

and its output goes to a terminal, another program,
or a file. Chapter 11 is about that life in
scripts; the chapters before it are about the
filter language itself.

## Getting jq

Check first — it's packed with most systems:

```
$ jq --version
jq-1.7
```

Every command in this guide was run with jq 1.7
(the version in Debian's repositories) against the
sample files in `examples/`. If you don't have it:
`apt install jq` on Debian/Ubuntu, `brew install
jq` on a Mac, or a single self-contained binary
from the project's releases at jqlang.org. jq 1.6
is still common on older systems; everything here
works there too, except where a chapter says so.

## The sample files

The `examples/` directory ships the exact files the
chapters use, so every output can be reproduced
byte for byte:

- `models.json` — a model-server API response:
  five fictional AI models, with a minified twin,
  `models-min.json`
- `inventory.json` — eight fictional machines:
  names, roles, locations, disks, services
- `orders.json` — three orders with customers and
  priced line items
- `events.json` — eight log events, one JSON value
  per line
- `settings.json` — a small service config, used
  when the guide starts *changing* JSON
- `broken.json` — deliberately invalid, for the
  error chapters
- `summary.jq` — a filter in a file, and
  `filters.txt` — the cheat sheet

Run the commands from inside `examples/` and your
output should match this guide exactly.

Check: `jq '.models | length' models.json` prints
`5`, and `jq -e '.' broken.json` prints nothing but
the parse error. If both do that, your jq and the
samples agree, and everything from here on will
reproduce.
