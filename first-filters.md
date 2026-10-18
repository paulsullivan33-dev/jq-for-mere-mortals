# First Filters

A jq filter is a *path* through the data, more
often than not. You write where you want to go, and
jq walks there. This chapter is the walking: into
objects, into arrays, through every element at
once — plus the small inspection tools (`keys`,
`length`, `type`) that tell you what you're looking
at when the path isn't obvious.

## Into objects: `.name`

A dot followed by a key reads that key's value:

```
$ jq '.models[0].name' models.json
"ember-2:7b"
```

Read it left to right: the input document, its
`models` value, that array's element `0`, that
object's `name`. Paths chain as deep as the data
goes:

```
$ jq '.models[1].details.context_length' models.json
32768
```

Two things to notice about the output. Strings come
out **quoted** — `"ember-2:7b"` is JSON, and jq's
default output is JSON. (Chapter 4's `-r` flag
strips the quotes when a human or a shell script
wants the bare text.) And numbers come out bare.
The output is always valid JSON until you ask
otherwise.

## Missing keys are `null`, not errors

Ask for a key that isn't there and jq answers
`null`:

```
$ jq '.models[3].capabilities' models.json
null

$ jq '.models[0].favourite_colour' models.json
null

$ jq '.inventory' models.json
null
```

The first of those matters: `kestrel-1:1.5b`, the
fourth model, genuinely has no `capabilities` key
in the file. jq doesn't distinguish "absent" from
"present but null" here, and it doesn't stop the
run. That is mostly kindness — filters can probe
ragged data without dying — and it cuts the other
way too: a *typo'd* key also returns `null`, quite
happily, forever. Chapter 3 shows `has`, which
checks presence for real, and chapter 10 is about
the debugging this behaviour calls for.

Indexing into `null` is fine as well — `.inventory`
above was `null`, and `.inventory.name` would also
be `null`, not an error. jq only gets loud when you
try to *iterate* or do arithmetic on nothing, which
is chapter 10's material.

## Into arrays: `.[0]`, and every element at once

Arrays are indexed from zero, and negative indexes
count from the end:

```
$ jq '.models[-1].name' models.json
"harbor-4:70b"
```

A slice takes a range: `.models[0:2]` is the first
two models. But the workhorse is `.[]` — "every
element, one at a time." Piping the stream through
another path runs that path once per element:

```
$ jq '.models[] | .name' models.json
"ember-2:7b"
"ember-2:32b"
"kestrel-1:8b"
"kestrel-1:1.5b"
"harbor-4:70b"
```

That `|` is the same pipe idea as the shell's, one
level down: each value that comes out of the left
side flows into the right side. Five models in,
five names out. Much of jq is this one move —
explode an array with `.[]`, then handle the pieces
individually.

If a value *might* be missing or not an array,
`.[]?` iterates what's there and stays quiet about
what isn't:

```
$ jq '.models[3].capabilities[]?' models.json
```

No output at all — the missing `capabilities` of
`kestrel-1:1.5b` produced nothing, not even `null`.
Hold that thought; the un-`?` version of this
command is chapter 10's first error.

## Looking at what you have: keys, length, type

When the data is unfamiliar, three builtins answer
most questions. `keys` lists an object's keys
(sorted, whatever the file's order):

```
$ jq '.models[0] | keys' models.json
[
  "capabilities",
  "details",
  "digest",
  "model",
  "modified_at",
  "name",
  "size"
]
```

`length` counts — array elements, object keys, or
string characters, depending on what's on the left:

```
$ jq '.models | length' models.json
5

$ jq '.models[0].name | length' models.json
10

$ jq '.models[0].details | length' models.json
8
```

`type` names the kind of value, which matters when
a filter misbehaves and you want to know what it
was actually fed:

```
$ jq '.models | type' models.json
"array"

$ jq '.models[0].size | type' models.json
"number"
```

The full set of answers is `"object"`, `"array"`,
`"string"`, `"number"`, `"boolean"`, and `"null"` —
chapter 3 puts `type` to work inside selections.

## Taking objects apart: `to_entries`

One more path tool, worth meeting early because
later chapters lean on it. `to_entries` turns an
object into an array of `{"key": …, "value": …}`
pairs:

```
$ jq '.models[0].details | to_entries | .[3]' models.json
{
  "key": "family",
  "value": "ember"
}
```

Once an object is an array, everything jq does to
arrays — iterate, filter, count — works on it. Its
mirror, `from_entries`, rebuilds the object when
you're done.
