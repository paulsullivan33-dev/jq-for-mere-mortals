# Streams and Multiple Files

Every file so far held exactly one JSON value.
Real JSON often doesn't: log files, event feeds,
and export formats carry a *stream* — value after
value after value, sometimes separated by newlines,
sometimes just by the values' own boundaries.
`events.json` is a small one: eight log events, one
object per line, no enclosing array.

jq's rule is simple and worth learning early:
**the filter runs once per value in the stream.**
That is not a special mode; it's how jq has been
working all along — your earlier files just had one
value each.

## A stream, filtered

Each event flows through the filter on its own:

```
$ jq '.level' events.json
"info"
"info"
"warn"
"error"
"info"
"error"
"info"
"warn"

$ jq 'select(.level == "error")' events.json
{
  "ts": "2026-10-12T09:03:12Z",
  "level": "error",
  "service": "queue",
  "msg": "worker stalled, restarting"
}
{
  "ts": "2026-10-12T13:22:10Z",
  "level": "error",
  "service": "backup",
  "msg": "target unreachable"
}
```

Note there's no `.[]` anywhere: there is no array
to explode. Each event *is* the input, in turn.

This per-value rule has a consequence that catches
everyone once. Ask a stream for its `length`:

```
$ jq 'length' events.json
4
4
4
4
4
4
4
4
```

jq is not broken and neither is the file: it ran
`length` eight times, once per event, and each
event object has four keys. You asked eight
questions and got eight honest answers.

## Slurp: `-s` makes the stream one array

When the question is about the whole stream —
how many events, how many errors — slurp mode
reads every value first, wraps them in one array,
and runs the filter once on that:

```
$ jq -s 'length' events.json
8

$ jq -s 'map(select(.level == "error")) | length' events.json
2
```

Now the whole vocabulary of chapter 5 applies:
`map`, `sort_by`, `group_by`, all of it. The cost
is memory — slurping a multi-gigabyte stream holds
all of it at once. For big streams, prefer a filter
that processes values as they pass (like the
`select` above) rather than collecting them.

Multiple files are just a longer stream: jq reads
its file arguments in order, as if concatenated.
Slurping across two files proves it — the eight
events plus the one object that is `models.json`:

```
$ jq -s 'length' events.json models.json
9
```

Without `-s`, the same command runs the filter
nine times. Nothing about the files has to match:
not their shapes, not their sizes. The stream is
the stream.

## `inputs`: taking values one at a time

Slurp is all-or-nothing. `inputs` is the middle
way: with `-n` (null input — "don't read the first
value yourself"), the filter pulls values from the
stream itself:

```
$ jq -n '[inputs] | length' events.json
8

$ jq -n 'input' events.json
{
  "ts": "2026-10-12T08:15:01Z",
  "level": "info",
  "service": "backup",
  "msg": "snapshot started"
}
```

`input` takes the next value (just the first event,
here); `inputs` is the stream of all the rest.
Filters that summarise as they go — running totals,
"first N that match, then stop" — are built from
these. For most everyday work `-s` is enough; reach
for `inputs` when the stream is too big to hold or
the job is genuinely one-at-a-time.

## Exit status: `-e` turns answers into tests

Normally jq exits 0 if the run worked, whatever it
printed. With `-e`, the exit status describes the
*last output*: 0 if it was neither `false` nor
`null`, 1 if it was, and 4 if there was no output
at all. Three runs against the inventory, asking
after the `decommissioned` flag three ways:

```
$ jq -e '.[] | select(.name == "harbor-08") | .decommissioned' inventory.json; echo "exit: $?"
true
exit: 0

$ jq -e '.[] | select(.name == "garnet-07") | .decommissioned' inventory.json; echo "exit: $?"
false
exit: 1

$ jq -e '.[] | select(.name == "onyx-99") | .decommissioned' inventory.json; echo "exit: $?"
exit: 4
```

This is the bridge to shell scripts (chapter 11):
`jq -e '…'` in an `if` is how a script asks JSON a
yes/no question and trusts the answer. Two honest
notes: `-e` judges only the *last* output of a
stream, so design the filter to end with the answer
you mean; and errors (chapter 10) exit with their
own codes, never quietly.

One flag this chapter deliberately leaves named
only: `--seq`, which reads and writes the
application/json-seq framing (each value preceded
by a record-separator byte) used by a few logging
systems. If your data arrives in that framing,
you'll know; almost nobody's does.
