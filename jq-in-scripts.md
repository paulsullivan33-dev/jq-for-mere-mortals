# jq in Scripts and Pipelines

Everything so far has been interactive: type a
filter, read the answer. The same filters earn
their keep inside shell scripts and pipelines,
where jq plays three roles — extracting values
into shell variables, answering yes/no questions
for `if`, and translating between programs that
speak different shapes of JSON. Each role has one
habit that makes it safe.

## Values into the shell: `-r` and a loop

Chapter 4's raw output exists for this. Strings
without quotes can feed the shell's own machinery:

```
$ jq -r '.models[] | .name' models.json | while read -r m; do echo "checking $m"; done
checking ember-2:7b
checking ember-2:32b
checking kestrel-1:8b
checking kestrel-1:1.5b
checking harbor-4:70b
```

One value, capture it into a variable with the
usual `$(…)`:

```
$ count=$(jq '.models | length' models.json); echo "count=$count"
count=5
```

Two cautions belong with the pattern. A value with
spaces or newlines survives `read -r` only if the
JSON values are one-per-line and line-shaped — a
model *name* is; a free-text message may not be,
and chapter 7's stream discipline (one value per
line, `-c` when in doubt) is what makes the loop
honest. And never build a jq filter by gluing
shell variables into the filter text; chapter 8's
`--arg` passes values as data, where stray quotes
can't rewrite the filter.

## Questions for `if`: `jq -e`

Chapter 7's `-e` is the scripting form of a query
— the script doesn't read the answer, it reads the
exit status:

```
$ if jq -e '.models | length > 0' models.json > /dev/null; then echo "models present"; fi
models present
```

The `> /dev/null` discards the printed answer
(`true`) because the branch only needs the status.
This is the pattern for "is the backup's status
field `ok`," "did any event reach level error,"
and every other yes/no a JSON file can answer —
with chapter 7's caveat in force: `-e` judges the
*last* output, so the filter must end with the
verdict you mean.

## The pipeline trap: jq fails quietly in a pipe

Now the habit that matters most. jq's own exit
status is only visible at the end of a pipeline if
the shell is told to look. By default, a pipeline's
status is its *last* command's status:

```
$ jq '.models[] | .capabilities[]' models.json 2>/dev/null | wc -l; echo "pipeline exit: $?"
5
pipeline exit: 0
```

That filter **errors** — chapter 10's
iterate-over-null, on the fourth model. Five lines
still reached `wc`, `wc` succeeded, and the
pipeline reports exit 0. A script trusting `$?`
here believes everything is fine with a *partial*
result: five capability lines, silently missing
the rest. (`2>/dev/null` hides the error text in
this demo so the statuses stand out; in real life
that text was your only clue.)

The fix is one shell line, set before the pipes
that matter:

```
$ set -o pipefail; jq '.models[] | .capabilities[]' models.json 2>/dev/null | wc -l; echo "pipeline exit: $?"
5
pipeline exit: 5
```

With `pipefail`, the pipeline's status is the last
*non-zero* status in it — jq's 5 surfaces, and the
script can refuse the partial answer. Same five
lines, honest bookkeeping. Any script that pipes
jq into something else wants `pipefail` (and,
usually, the `[]?`/`// []` discipline of chapter 10
so the error never happens in the first place).

## jq after `curl`: the pipeline everyone meets

The most common jq pipeline in the world has an
HTTP client on the left:

```
curl -s https://api.example.com/v1/models | jq '.models[] | .name'
```

This guide doesn't run that command — there's no
API here to call — but nothing about it is new:
it is `jq '…' models.json` with a different left
side, because `models.json` *is* this shape of
response, saved to a file. Everything learned
against the file transfers untouched: selection,
reshaping, `-e` for "did the API return what we
hoped," `pipefail` for "or did it fail halfway."
When a pipeline misbehaves, save the response to a
file once (`curl -s … > response.json`) and debug
the filter against the file; a filter debugged
against fixed data stays debugged.

## When jq is the wrong tool

Honest limits, to close. jq loads each input value
whole before filtering it, so a single JSON value
of many gigabytes — or a `-s` slurp of a huge
stream — is a memory problem a streaming parser in
a real language handles better. JSON with one
object per line that *isn't* quite JSON (trailing
commas, comments, unquoted keys) isn't jq's input
at all until something forgiving has cleaned it.
Multi-file joins with real logic, persistent
state, date arithmetic beyond the basics (jq does
have date builtins — `strptime`/`strflocaltime`
and friends — but they are a garnish, not a
library), and anything that needs to *be* a
program rather than describe a transformation:
those belong to Python or your language of choice,
which will happily call the same shapes of
questions with a debugger attached.

The line this guide has been drawing all along:
jq is the best tool yet made for *asking questions
of JSON and reshaping it in flight*. Learn the
eleven chapters' worth, and you'll know both the
questions and the moment to stop asking jq.
