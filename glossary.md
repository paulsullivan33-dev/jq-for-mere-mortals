# Glossary

**Alternative operator (`//`)** — "or else":
replaces a `null`, `false`, or missing result with
the value on its right. The standard way to give
ragged data a default.

**Assignment (`=`)** — outputs the whole document
with the path on the left set to the right side's
value, where the right side is a filter evaluated
against the document. Contrast **update-assignment**.

**Compile error** — the filter itself is invalid
jq; caught before any data flows. Exit code 3.

**Exit status (`-e`)** — the flag that makes jq's
exit code describe its last output: 0 for a result
that is neither `false` nor `null`, 1 for one that
is, 4 for no output at all. How scripts ask jq
yes/no questions.

**Filter** — a jq expression. Takes one JSON value
as input, produces zero or more JSON values as
output. The whole language is filters composed
with `|`.

**Filter file (`-f`)** — a file of jq (comments
allowed) run as the filter, for expressions too
long to live on a command line. See
`examples/summary.jq`.

**Flatten** — `flatten` recursively brings every
element of nested arrays to the top level.
`flatten(1)` stops one level down.

**Group by** — `group_by(f)` buckets an array into
runs of elements whose `f` values are equal
(sorting by `f` first, in current jq). Pair with
`map` to summarise each bucket.

**Identity filter (`.`)** — the filter that returns
its input unchanged. Because jq reprints what it
parsed, `.` is the pretty-printer and the quickest
JSON validator there is.

**Inputs** — with `-n`, `input` pulls the next
value from the input stream and `inputs` yields
all remaining ones, letting a filter consume a
stream one value at a time instead of slurping it.

**Interpolation** — `\(…)` inside a string:
splices a filter's result into the text.

**Map** — `map(f)` runs `f` on each element of an
array and collects the results into a new array;
shorthand for `[.[] | f]`.

**Null** — JSON's "no value," and jq's answer to a
missing key, an out-of-range probe, or arithmetic
on nothing. Not an error in itself; iterating or
indexing into it the wrong way is what errors.

**Parse error** — the input isn't valid JSON; jq
reports the line and column where it stopped
making sense and exits with code 5.

**Path** — a chain like `.models[0].name` naming a
place inside a value. Also a builtin: `paths`
lists every path a document contains.

**Pipe (`|`)** — composition: every output of the
left filter becomes an input of the right one.
jq's central move, borrowed from the shell.

**Raw output (`-r`)** — string results printed as
themselves, without JSON quoting or escapes. For
humans, shell loops, and `@csv`/`@tsv` rows.

**Runtime error** — the filter was legal but met
data it couldn't process ("Cannot iterate over
null"). Output already produced stays produced.
Exit code 5.

**Select** — `select(test)` passes through exactly
the inputs for which `test` is true, and drops the
rest. The narrowing filter.

**Slurp (`-s`)** — read the entire input stream
first, wrap the values in one array, then run the
filter once. Turns per-value questions into
whole-stream questions, at the cost of memory.

**Stream** — a sequence of JSON values in one
input, with no enclosing array — log files, event
feeds. jq runs its filter once per value.

**Total order** — jq's fixed ordering across all
types (null < boolean < number < string < array <
object), which is why `sort` never refuses mixed
input.

**Try/catch** — `try f catch g`: if `f` errors,
the result is `g` run on the error message instead
of the run dying.

**Update-assignment (`|=`)** — transforms the value
at a path with a filter that receives the *old
value* as its input: `.retries |= . + 1`. Inside
`|=` the dot is the old value, not the document —
the difference from `=` that matters.
