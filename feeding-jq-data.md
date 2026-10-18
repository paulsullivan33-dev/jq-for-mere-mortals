# Feeding jq Data

Filters so far have been self-contained: every
value they used came from the input. Real filters
need outside values — a role to match, a threshold,
a whole second file. jq takes these as *variables*:
`--arg` for strings, `--argjson` for JSON values,
`--slurpfile` for files, and the environment itself.
And when a filter outgrows the command line, it
moves into a file of its own, run with `-f`.

## `--arg`: shell values in, as strings

```
$ jq --arg role server '[.[] | select(.role == $role)] | length' inventory.json
4
```

`--arg role server` binds `$role` to the string
`"server"`, and the filter uses it like any value.
This is the safe way to get shell variables into
jq: the value passes as data, never as filter
text, so a value containing quotes or jq syntax
can't break the filter or bend it. (The unsafe way
— interpolating `$ROLE` into the filter string in
double quotes — breaks on exactly those values.
Don't.)

The catch is in the name: `--arg` values are
*always strings*. A threshold passed that way
arrives as `"32"`, and comparing it against numbers
fails quietly or errors. The proof:

```
$ jq -n --arg min 32 '$min | type'
"string"

$ jq -n --argjson min 32 '$min | type'
"number"
```

## `--argjson`: values with their types on

`--argjson` parses its value as JSON — numbers,
booleans, arrays, whole objects — and binds that:

```
$ jq --argjson min 32 '[.[] | select(.ram_gb >= $min)] | map(.name)' inventory.json
[
  "atlas-01",
  "birch-02",
  "copper-03",
  "elm-05",
  "fjord-06"
]
```

They compose; a filter can take several of each:

```
$ jq --arg role server --argjson min 32 '[.[] | select(.role == $role and .ram_gb >= $min)] | map(.name)' inventory.json
[
  "atlas-01",
  "birch-02",
  "elm-05"
]
```

Servers with at least 32 GB. Rules of thumb: text
from the user or the shell — `--arg`. Anything with
a type that matters — `--argjson`, and be ready for
it to reject text that isn't valid JSON, loudly and
before the filter runs, which is what you want.

## The environment, and other files

jq exposes the process environment as `$ENV`:

```
$ GREETING=hello jq -n '$ENV.GREETING'
"hello"
```

Useful for the odd inherited setting; reaching for
it often is a smell — `--arg` at the call site says
what a filter needs, `$ENV` hides it.

`--slurpfile` binds a whole file, slurped exactly
as chapter 7's `-s` does — the file's values arrive
as one array under the variable:

```
$ jq -n --slurpfile ev events.json '{events_seen: ($ev | length)}'
{
  "events_seen": 8
}
```

That's the light way to combine two sources: the
main input stays the input, and a reference file
rides along as a variable. (Two equally-weighted
inputs are usually better handled as one stream,
chapter 7 style, or with `inputs`.) Its sibling
`--rawfile` binds a file's contents as one string,
for text that isn't JSON at all.

For completeness: `--args` stops jq's own option
parsing and hands the rest of the command line to
the filter as `$ARGS`:

```
$ jq -n --args '$ARGS' one two three
{
  "positional": [
    "one",
    "two",
    "three"
  ],
  "named": {}
}
```

## `-f`: filters that live in files

Past a few pipes, a filter deserves a file: it can
be read, commented, tested, and kept. The file
`examples/summary.jq` holds a fleet summary — the
worked example's summary object, grown into
chapter 5's grouping — run like this:

```
$ jq -f summary.jq inventory.json
{
  "machines": 8,
  "total_ram_gb": 360,
  "by_role": [
    {
      "role": "laptop",
      "count": 2
    },
    {
      "role": "server",
      "count": 4
    },
    {
      "role": "workstation",
      "count": 2
    }
  ],
  "low_disk": [
    "birch-02",
    "garnet-07"
  ]
}
```

The file itself (do read it — it's short) is plain
jq: the same constructs as the command-line
filters, plus `#` comments, which the command line
never has room for. Cross-check it against
chapters 5 and 6: 8 machines, 360 GB total, roles
2/4/2, and the same two low-disk names the worked
example's watchlist found. A filter file that
agrees with the interactive steps it grew from is
a filter you can trust at 2 a.m.

Variables and `-f` combine freely — a `.jq` file
can use `$role` and rely on `--arg` to supply it.
That pairing, a reviewed filter file plus values
passed at the call site, is where most production
jq actually lives.
