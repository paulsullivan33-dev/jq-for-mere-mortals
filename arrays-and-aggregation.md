# Arrays and Aggregation

Individual values are chapter 2's business. This
chapter is about arrays as a whole: transforming
every element at once, sorting, deduplicating,
totalling, and grouping. The stage is the
inventory — eight machines whose RAM, disks, and
roles are exactly the kind of thing these questions
are asked about.

## `map`: run a filter on every element

`map(f)` applies `f` to each element of an array
and collects the results into a new array:

```
$ jq 'map(.ram_gb)' inventory.json
[
  64,
  32,
  32,
  16,
  128,
  64,
  8,
  16
]
```

`map(.ram_gb)` is shorthand for `[.[] | .ram_gb]` —
the explode-and-rebuild of chapters 2 and 4,
packaged. Once the numbers are an array, the
aggregation builtins finish the job. `add` folds an
array of numbers (or strings) into one value:

```
$ jq 'map(.ram_gb) | add' inventory.json
360

$ jq 'map(.ram_gb) | add / length' inventory.json
45
```

360 GB of RAM across the fleet, 45 on average —
`add / length` is the average idiom; there is no
separate `avg` builtin. `min` and `max` work the
same way on a mapped array (`map(.ram_gb) | max`
is `128`), and `min_by`/`max_by` return the whole
*element* that holds the extreme, which is usually
the actual question:

```
$ jq 'min_by(.disk_free_gb) | .name' inventory.json
"garnet-07"
```

## Sorting and deduplicating

`sort` orders an array; `sort_by(f)` orders it by
what `f` produces for each element:

```
$ jq '[.[] | select(.role == "server")] | sort_by(.disk_free_gb) | map(.name)' inventory.json
[
  "garnet-07",
  "birch-02",
  "atlas-01",
  "elm-05"
]
```

Servers by free disk, emptiest first. `reverse`
turns any order around:

```
$ jq '[.models[].name] | reverse' models.json
[
  "harbor-4:70b",
  "kestrel-1:1.5b",
  "kestrel-1:8b",
  "ember-2:32b",
  "ember-2:7b"
]
```

`unique` sorts and removes duplicates — the
fleet's roles and operating systems in one line
each:

```
$ jq 'map(.role) | unique' inventory.json
[
  "laptop",
  "server",
  "workstation"
]

$ jq 'map(.os) | unique' inventory.json
[
  "linux",
  "macos",
  "windows"
]
```

`unique_by(f)` deduplicates by a computed key and
keeps the first element of each kind — here, one
representative machine per operating system:

```
$ jq 'unique_by(.os) | map(.name)' inventory.json
[
  "atlas-01",
  "dune-04",
  "copper-03"
]
```

Both `unique` forms sort as a side effect; if the
original order matters, that's a behaviour to know
about, not discover later.

## `group_by`: buckets with counts

Grouping is a three-step rhythm: sort by the key,
group into runs of equal keys, then summarise each
run. (Current jq actually sorts inside `group_by`
itself — feed it shuffled input and the groups
still come out whole — but the explicit `sort_by`
costs nothing, keeps the intent visible, and is
what you'll see in every example elsewhere, so
this guide keeps it.)

```
$ jq 'sort_by(.location) | group_by(.location) | map({location: .[0].location, machines: length})' inventory.json
[
  {
    "location": "lab",
    "machines": 2
  },
  {
    "location": "office",
    "machines": 4
  },
  {
    "location": "remote",
    "machines": 2
  }
]
```

Inside each group — itself an array — `.[0].location`
is the key every member shares, and `length` is the
count. The `{role: …, count: length}` version of
this pattern reappears in chapter 8's filter file.
This is also the honest place to say that
`group_by` is as far as this guide goes. jq has
more — `sort_by` with several keys, `to_entries`
acrobatics for pivot tables — but past grouping, a
real programming language starts earning its keep.
Chapter 11 returns to where that line sits.

## `flatten`: nested arrays, levelled — all the way

`flatten` takes nested arrays and brings every
element to the top level:

```
$ jq '.models | map(.details.families) | flatten | unique' models.json
[
  "ember",
  "harbor",
  "kestrel"
]
```

Each model's `families` is an array; `map` makes an
array of arrays; `flatten` levels it; `unique`
finishes. The honest note the name hides: bare
`flatten` recurses *all* the way down, through
every level of nesting —

```
$ jq -n '[[1, [2, 3]], 4] | flatten'
[
  1,
  2,
  3,
  4
]
```

— and it leaves non-array elements (including
objects) untouched, but an array buried inside an
object's value is not reached either; `flatten`
works on the array structure itself. When you want
exactly one level, that's `flatten(1)`, or the
explicit `[.[][]]` for the common two-level case.
Knowing which you asked for matters the day the
data nests deeper than you thought.
