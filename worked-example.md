# A Worked Example

One job, done the way jq jobs actually get done:
not by writing the final filter in one go, but by
growing it a pipe at a time, checking the output at
each step. The job: from `inventory.json` — eight
machines — produce a server disk report that
answers "which servers fill up first," in a form
you could paste into a message to another human.

Every intermediate output below is real, so if you
run the same steps in `examples/`, yours will match
at each stage.

## Step 1: look at the shape

Before filtering anything, know what you have:

```
$ jq 'length' inventory.json
8

$ jq '.[0]' inventory.json
{
  "cpus": 16,
  "disk_free_gb": 412,
  "disk_total_gb": 2000,
  "location": "office",
  "name": "atlas-01",
  "os": "linux",
  "ram_gb": 64,
  "role": "server",
  "services": [
    "ssh",
    "http",
    "backup"
  ]
}
```

Eight machines, objects with the facts we need:
`role` to select servers, `disk_free_gb` and
`disk_total_gb` to compute from.

## Step 2: names, then only servers' names

```
$ jq -r '.[] | .name' inventory.json
atlas-01
birch-02
copper-03
dune-04
elm-05
fjord-06
garnet-07
harbor-08

$ jq -r '.[] | select(.role == "server") | .name' inventory.json
atlas-01
birch-02
elm-05
garnet-07
```

The `-r` is already on: this report is headed for
people, not parsers. The `select` narrows eight
machines to the four servers.

## Step 3: reshape, with a computed field

Names alone don't answer the question. Build a
small object per server — name, location, and free
space as a rounded percentage, computed from the
two disk figures:

```
$ jq '.[] | select(.role == "server") | {name, location, free_pct: (.disk_free_gb / .disk_total_gb * 100 | round)}' inventory.json
{
  "name": "atlas-01",
  "location": "office",
  "free_pct": 21
}
{
  "name": "birch-02",
  "location": "office",
  "free_pct": 10
}
{
  "name": "elm-05",
  "location": "lab",
  "free_pct": 73
}
{
  "name": "garnet-07",
  "location": "remote",
  "free_pct": 9
}
```

(The `-r` comes off for a moment — jq ignores it
for objects, but leaving it off while the values
are still JSON makes the experimenting clearer.)
Sanity-check one by hand: atlas has 412 of 2000 GB
free, which is 20.6%, rounding to 21. The filter
is telling the truth.

## Step 4: collect and sort

The answer to "which fills up first" is an
ordering. Collect the stream into one array with
`[…]`, then `sort_by` the field that matters:

```
$ jq '[.[] | select(.role == "server") | {name, location, free_pct: (.disk_free_gb / .disk_total_gb * 100 | round)}] | sort_by(.free_pct)' inventory.json
[
  {
    "name": "garnet-07",
    "location": "remote",
    "free_pct": 9
  },
  {
    "name": "birch-02",
    "location": "office",
    "free_pct": 10
  },
  {
    "name": "atlas-01",
    "location": "office",
    "free_pct": 21
  },
  {
    "name": "elm-05",
    "location": "lab",
    "free_pct": 73
  }
]
```

## Step 5: the human-readable table

Back to text: explode the sorted array again, make
a row array per server, and let `@tsv` lay it out:

```
$ jq -r '[.[] | select(.role == "server") | {name, location, free_pct: (.disk_free_gb / .disk_total_gb * 100 | round)}] | sort_by(.free_pct) | .[] | [.name, .location, "\(.free_pct)% free"] | @tsv' inventory.json
garnet-07	remote	9% free
birch-02	office	10% free
atlas-01	office	21% free
elm-05	lab	73% free
```

That's the report. Four lines, worst first, ready
to paste anywhere. Notice the shape of the final
filter — it is every previous step in a trench
coat: explode, `select`, reshape, collect, sort,
explode, format. Nothing new appears at the end;
the pipeline was *assembled*.

## Step 6: the same machinery, two more questions

A watchlist is the same pipeline with the cut
drawn tighter — all machines this time, not just
servers, under 15% free:

```
$ jq -r '[.[] | {name, free_pct: (.disk_free_gb / .disk_total_gb * 100 | round)} | select(.free_pct < 15)] | .[] | [.name, "\(.free_pct)% free"] | @tsv' inventory.json
birch-02	10% free
garnet-07	9% free
```

And a one-object summary for the top of the
report, reusing chapter 5's `add`:

```
$ jq '{machines: length, servers: ([.[] | select(.role == "server")] | length), total_ram_gb: (map(.ram_gb) | add)}' inventory.json
{
  "machines": 8,
  "servers": 4,
  "total_ram_gb": 360
}
```

Check: the report numbers agree with each other —
8 machines, 4 of them servers, and the watchlist's
two names are the table's two emptiest servers.
When a pipeline's outputs cross-check like this,
you can stop growing it. Chapter 8 takes this
summary style one step further and moves the
filter into a file, where a filter this long
belongs.
