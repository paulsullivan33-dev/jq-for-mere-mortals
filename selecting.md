# Selecting

Chapter 2's filters took *everything* — every
model, every name. Real questions are narrower:
which models, which machines, which events.
`select` is the filter that narrows. It takes a
test, passes through the values that pass, and
drops the rest.

## `select` and comparisons

```
$ jq '.models[] | select(.details.context_length >= 16384) | .name' models.json
"ember-2:7b"
"ember-2:32b"
"harbor-4:70b"
```

Five models flow in. The test
`.details.context_length >= 16384` is true for
three of them, so three values reach the final
`.name`. The comparisons are the usual set —
`==`, `!=`, `<`, `<=`, `>`, `>=` — and tests
combine with `and`, `or`, and `not`:

```
$ jq '.models[] | select(.details.family == "kestrel" and .details.context_length > 4096) | .name' models.json
"kestrel-1:8b"

$ jq -r '.models[] | select(.details.family == "ember" or .details.family == "harbor") | .name' models.json
ember-2:7b
ember-2:32b
harbor-4:70b
```

The test can be any expression that ends in true
or false, including another filter's result.
String builtins make common tests short — this one
asks which models use a Q4 quant:

```
$ jq '.models[] | select(.details.quantization_level | startswith("Q4")) | .name' models.json
"ember-2:7b"
"ember-2:32b"
"kestrel-1:1.5b"
```

There are also `endswith`, `contains`, and `test`
for regular expressions; the cheat sheet in
`examples/filters.txt` can't list them all, and the
jq manual can.

## `//`: the answer when there isn't one

Chapter 2 ended on `null` — the absent
`capabilities` of `kestrel-1:1.5b`. The `//`
operator, read "or else", replaces a missing,
`null`, or `false` value with an alternative:

```
$ jq '.models[] | .capabilities // "none recorded"' models.json
[
  "completion",
  "tools"
]
[
  "completion"
]
[
  "completion",
  "vision"
]
"none recorded"
[
  "completion",
  "tools"
]
```

Four arrays and one plain string come out — `//`
doesn't care that the replacement has a different
type than the usual value; it cares that the stream
now has an answer for every model. Used inside a
reshaping (chapter 4), the same trick supplies a
default of matching shape:

```
$ jq '.models[] | select(.details.family == "kestrel") | {name, caps: (.capabilities // [])}' models.json
{
  "name": "kestrel-1:8b",
  "caps": [
    "completion",
    "vision"
  ]
}
{
  "name": "kestrel-1:1.5b",
  "caps": []
}
```

Note that `//` also swallows `false`. A key that is
present and deliberately `false` gets replaced
too — which is why `garnet-07`'s status in the
inventory needs the longer spelling below.

## Testing presence and type

`select` on a path tests the *value*; sometimes the
question is about the *key*. `has` answers it:

```
$ jq '[.models[] | select(has("capabilities"))] | length' models.json
4
```

Four of the five models carry the key. (The
`[…]` around the filter collects the stream back
into one array so `length` can count it — the
constructing brackets are chapter 4's subject.)
`has`'s mirror image is `in`, which asks the same
question from the key's side:

```
$ jq -n '"name" | in({"name": 1, "size": 2})'
true
```

And `type`, met in chapter 2, earns its keep when
data is ragged. In the inventory, `fjord-06` has no
`services` key at all; asking which machines have a
real services *list* is a type test:

```
$ jq '[.[] | select(.services | type == "array")] | length' inventory.json
7
```

Seven of eight — `fjord-06`'s missing key is
`null`, `null`'s type is `"null"`, and the test
honestly excludes it. Combining `has`, `type`, and
`//` covers most of what ragged real-world JSON
throws at a filter. One last combination, the
careful way to say "not decommissioned" when the
key is often absent and sometimes `false`:

```
$ jq '[.[] | select(.decommissioned // false | not)] | map(.name)' inventory.json
[
  "atlas-01",
  "birch-02",
  "copper-03",
  "dune-04",
  "elm-05",
  "fjord-06",
  "garnet-07"
]
```

`.decommissioned // false` turns "no key" into
`false`; `not` inverts; `harbor-08`, the one machine
marked `"decommissioned": true`, is the only one
missing from the list. Filters like this are where
jq starts repaying the learning curve: that
question, over a file of eight thousand machines
instead of eight, is the same one line.
