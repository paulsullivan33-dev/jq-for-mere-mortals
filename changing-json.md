# Changing JSON

Everything so far has read JSON. This chapter
writes it — or rather, it produces *changed* JSON,
because of the fact that shapes everything here:

**jq never edits a file in place.** It reads JSON
and prints JSON. Making the change stick is a
separate, deliberate step, and the step has a
right way and a catastrophic way, both shown
below.

The workbench is `settings.json`, a small service
config: retries 3, a maximum of 5, notifications
off, two targets.

## Assignment: `=`

The filter `.retries = 5` outputs the whole
document with that one value replaced:

```
$ jq '.retries = 5' settings.json
{
  "max_retries": 5,
  "notify": false,
  "retries": 5,
  "schedule": {
    "hour": 2,
    "minute": 30
  },
  "service": "backup",
  "targets": [
    "atlas-01",
    "birch-02"
  ]
}
```

Assignment always returns the **entire modified
document** — that's jq's only way to report a
change. And the file itself is untouched, which
the very next command proves:

```
$ jq '.retries' settings.json
3
```

Still 3 on disk. Nothing is written until you
redirect output somewhere (the ritual, below).

The right side of `=` is a filter evaluated against
the **document** — so it can pull a value from
elsewhere in the same data. "Set retries to the
configured maximum":

```
$ jq '.retries = .max_retries' settings.json
{
  "max_retries": 5,
  "notify": false,
  "retries": 5,
  "schedule": {
    "hour": 2,
    "minute": 30
  },
  "service": "backup",
  "targets": [
    "atlas-01",
    "birch-02"
  ]
}
```

Same shape as the literal `5`, arrived at by
reference. Assignment creates keys that don't exist
yet, too: `.owner = "ops"` would add the key.
Deeply nested targets work the same way; the
left side is just a path:

```
$ jq '.models[0].details.context_length = 65536 | .models[0].details.context_length' models.json
65536
```

(The trailing path selects the changed value back
out of the whole-document result, so the effect is
visible without printing five models.)

## Update-assignment: `|=`, and why it isn't `=`

`|=` looks similar and means something different:
"transform the value *at this path*, using a filter
that receives the old value as its input." The
everyday use is adjusting a value in terms of
itself:

```
$ jq '.retries |= . + 1' settings.json
{
  "max_retries": 5,
  "notify": false,
  "retries": 4,
  "schedule": {
    "hour": 2,
    "minute": 30
  },
  "service": "backup",
  "targets": [
    "atlas-01",
    "birch-02"
  ]
}
```

Inside `|=`, `.` is **the old value at the path** —
the number 3 — not the document. Which means the
`=` trick from the last section doesn't merely
behave differently under `|=`, it fails outright:

```
$ jq '.retries |= .max_retries' settings.json
jq: error (at settings.json:14): Cannot index number with string "max_retries"
```

Read the error with the rule in hand and it's
exact: the filter tried `.max_retries` on the
number 3. So the choice between them is a question
about where the new value comes from:

| New value comes from… | Use |
|---|---|
| anywhere in the document | `.path = …` |
| the old value at the path | `.path |= …` |

A memory hook: `=` *replaces*, `|=` *pipes the old
value through* — it's the assignment form of the
`|` you've been using all along.

## Deleting: `del`

`del(path)` removes a key, or an array element:

```
$ jq 'del(.notify)' settings.json
{
  "max_retries": 5,
  "retries": 3,
  "schedule": {
    "hour": 2,
    "minute": 30
  },
  "service": "backup",
  "targets": [
    "atlas-01",
    "birch-02"
  ]
}

$ jq 'del(.targets[0])' settings.json
{
  "max_retries": 5,
  "notify": false,
  "retries": 3,
  "schedule": {
    "hour": 2,
    "minute": 30
  },
  "service": "backup",
  "targets": [
    "birch-02"
  ]
}
```

Deleting an array element renumbers what follows —
`birch-02` was index 1, and is the whole array now.
`del` composes like everything else: several paths,
a `select` before it, a reshape after it.

Paths also exist as data. The `paths` builtin
lists every path in a document — the map of what
assignment and `del` can address:

```
$ jq -r 'paths | join(".")' settings.json
max_retries
notify
retries
schedule
schedule.hour
schedule.minute
service
targets
targets.0
targets.1
```

## The ritual: how a change reaches the file

Now the step jq won't do for you. The wrong way
first, demonstrated on a throwaway copy:

```
$ cp settings.json scratch.json
$ jq '.retries = 9' scratch.json > scratch.json
$ wc -c scratch.json
0 scratch.json
```

The file is empty, the command "succeeded," and no
error was printed. The reason is the shell, not
jq: `> scratch.json` truncates the file *before*
jq starts, so jq reads an empty file, prints
nothing, and the redirect writes that nothing over
your data. This is the single most destructive
habit available with jq, and it is one redirect
away at all times.

The right way writes to a new name and renames
over the original, only if jq succeeded:

```
$ jq '.retries = 5' settings.json > settings.new.json && mv settings.new.json settings.json
$ jq '.retries' settings.json
5
```

(rename the file first, run the commands, and your
copy of `settings.json` now has retries 5 — every
later chapter assumes the original, so change it
back with the same ritual, `= 3`, if you follow
along from here.)

The `&&` matters: if jq fails — a typo'd filter, a
broken input file — the `mv` never runs and the
original survives. Two habits follow from all of
this: never redirect jq's output onto its input,
ever; and keep the original until the replacement
has been read back and believed, which the rename
ritual gives you for free.
