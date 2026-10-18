# Errors and Debugging

jq's errors are better than their reputation —
they name the operation, the values involved, and
where the input gave out. This chapter collects
the ones this guide has been walking toward, reads
them closely, and covers the defensive patterns
that prevent them. Every error below is real,
produced by the command shown.

First, the geography: jq reports on **stderr**,
results on **stdout**. In a terminal they
interleave; in a pipeline only the results flow
on. And each failure class has its own exit code
(all observed with jq 1.7):

| Failure | Exit |
|---|---|
| Parse error — the input isn't JSON | 5 |
| Compile error — the filter isn't jq | 3 |
| Runtime error — the filter met the wrong data | 5 |
| `-e` with a `false`/`null` last result | 1 |
| `-e` with no output at all | 4 |

## Parse errors: the input is broken

```
$ jq '.' broken.json; echo "exit: $?"
jq: parse error: Expected separator between values at line 4, column 37
exit: 5
```

Line 4, column 37 of `broken.json` is right after
`"nuts"` — where the missing comma should be.
Parse errors are *positional* because they can be:
the parser knows exactly where the JSON stopped
making sense. jq parses the whole value before
any filtering, so a broken input produces no
partial results — nothing came out of that command
but the error.

## Compile errors: the filter is broken

```
$ jq '.models[' models.json; echo "exit: $?"
jq: error: syntax error, unexpected end of file (Unix shell quoting issues?) at <top-level>, line 1:
.models[
jq: 1 compile error
exit: 3
```

A filter typo is caught before any data flows —
jq echoes the filter, points at where it stopped
making sense, and exits 3. (The parenthetical
about shell quoting is jq being worldly-wise: a
filter that arrives truncated by a quoting mishap
looks exactly like this.) Compile errors are the
friendly kind: no input was harmed, and the fix is
in the filter, not the data.

## Runtime errors: filter meets data

### Cannot iterate over null

Chapter 2 promised this one. Iterate every model's
capabilities — remembering that `kestrel-1:1.5b`
has none:

```
$ jq '.models[] | .capabilities[]' models.json; echo "exit: $?"
"completion"
"tools"
"completion"
"completion"
"vision"
jq: error (at models.json:114): Cannot iterate over null (null)
exit: 5
```

Three lessons in one failure. The five lines
before the error are *real output, already gone* —
jq streams, so models one through three were fully
processed before the fourth killed the run (the
error reached the terminal on stderr; here it's
shown after the output it interrupted). And the
position, `models.json:114`, is where the *input
value ended* — jq read the whole document before
the stream reached the bad element — not where
your filter went wrong. Runtime error positions
locate the data, not the mistake.

The fixes are chapter 2 and 3's tools, chosen by
intent. Skip what's absent, with `?`:

```
$ jq '.models[] | .capabilities[]?' models.json
"completion"
"tools"
"completion"
"completion"
"vision"
"completion"
"tools"
```

Supply an empty array so the iteration has
something legal to chew on:

```
$ jq '.models[] | (.capabilities // [])[]' models.json
"completion"
"tools"
"completion"
"completion"
"vision"
"completion"
"tools"
```

Or catch the failure and say so in the output,
with `try … catch`:

```
$ jq '.models[] | try (.capabilities[]) catch "none recorded"' models.json
"completion"
"tools"
"completion"
"completion"
"vision"
"none recorded"
"completion"
"tools"
```

Same seven lines, plus an honest marker where the
gap was. `[]?` when absence is normal, `// []` when
the code after it needs an array either way, `try`
when the failure itself is information.

### Wrong types in operations

Arithmetic and indexing check types and refuse
mismatches — naming both sides:

```
$ jq '.models[0].size + .models[0].name' models.json; echo "exit: $?"
jq: error (at models.json:114): number (4378221568) and string ("ember-2:7b") cannot be added
exit: 5

$ jq '.models.name' models.json; echo "exit: $?"
jq: error (at models.json:114): Cannot index array with string "name"
exit: 5
```

The second is the most common jq error in the
wild: a `.name` written where `.[]` needed to come
first. Notice what is *not* an error, because many
expect it to be: **sorting never refuses mixed
types.** jq defines a total order —
null < false < true < numbers < strings < arrays <
objects — and sorts anything:

```
$ jq -n '[3, "ten", 1] | sort'
[
  1,
  3,
  "ten"
]
```

The "cannot be sorted" error people remember
doesn't exist; its cousins are the `cannot be
added` family — arithmetic is where types are
actually enforced:

```
$ jq -n '{"a": 1} + [1]'; echo "exit: $?"
jq: error (at <unknown>): object ({"a":1}) and array ([1]) cannot be added
exit: 5
```

## Output worth diffing: `-S`, `--tab`, colour

Three presentation flags earn their place while
debugging. jq preserves input key order, which
makes two runs' outputs differ for no semantic
reason; `-S` sorts keys for output that diffs
cleanly:

```
$ echo '{"zeta": 1, "alpha": 2, "mid": 3}' | jq '.'
{
  "zeta": 1,
  "alpha": 2,
  "mid": 3
}

$ echo '{"zeta": 1, "alpha": 2, "mid": 3}' | jq -S '.'
{
  "alpha": 2,
  "mid": 3,
  "zeta": 1
}
```

Indentation is two spaces by default; `--tab`
uses tabs, and `--indent N` picks a width. (The
`schedule` object below really is indented with
tab characters — your editor will show them as
space, which is itself a small lesson in why diffs
need `-S` and byte-level honesty.)

```
$ jq --tab '.schedule' settings.json
{
	"hour": 2,
	"minute": 30
}
```

Colour: on a terminal, jq colourises output
(keys, strings, numbers, null each get a shade),
which genuinely helps the eye in a deep object.
`-C` forces colour on even into a pipe, `-M`
forces it off; this book is printed in one colour,
so take the claim on trust and try `jq -C '.'` on
your own terminal.

## Numbers: the honest fine print

jq's numbers are double-precision floats, and two
behaviours follow. First, an untouched number is
printed *as written* — jq keeps the original text
of numbers it doesn't compute with:

```
$ echo '9007199254740993' | jq '.'
9007199254740993
```

But arithmetic converts to a double, and doubles
cannot name every integer past 2⁵³:

```
$ echo '9007199254740993' | jq '. + 0'
9007199254740992
```

Adding zero lost one. For JSON carrying 64-bit
IDs, account numbers, or nanosecond timestamps as
*numbers*, that is a data-corruption class of
problem: keep such values as strings in the JSON
if they must survive arithmetic, or keep them away
from jq's arithmetic entirely. Second, key order:
as the `-S` example shows, jq preserves the
document's key order and never promised any
particular one — filters that depend on object
order (rather than on keys) are filters waiting to
surprise you.
