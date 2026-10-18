# Reshaping Output

So far the output has been pieces of the input,
lifted out whole. This chapter builds *new* values:
objects assembled from parts of several places,
computed fields, strings with values woven in, and
rows formatted for spreadsheets and shell scripts.
This is where jq stops being a fancy `grep` and
becomes the adapter between programs that disagree
about shape.

## Building objects

Curly braces construct an object. Each entry names
a key and a filter whose result becomes the value —
and inside the braces, `.` still means the current
input value, so several paths can feed one object:

```
$ jq '.models[] | {model: .name, params: .details.parameter_size, ctx_k: (.details.context_length / 1024)}' models.json
{
  "model": "ember-2:7b",
  "params": "7.2B",
  "ctx_k": 32
}
{
  "model": "ember-2:32b",
  "params": "32.8B",
  "ctx_k": 32
}
{
  "model": "kestrel-1:8b",
  "params": "8.1B",
  "ctx_k": 8
}
{
  "model": "kestrel-1:1.5b",
  "params": "1.5B",
  "ctx_k": 4
}
{
  "model": "harbor-4:70b",
  "params": "70.6B",
  "ctx_k": 16
}
```

The values are *computed*, not copied: `ctx_k` is
the context length divided by 1024, arithmetic done
inside the construction. When a value is just a
path with the same name as the key, the shorthand
`{id}` means `{id: .id}` — used here to give each
order its total, computed from its line items:

```
$ jq '.orders[] | {id, total: ([.items[] | .qty * .price] | add)}' orders.json
{
  "id": "ORD-2401",
  "total": 50
}
{
  "id": "ORD-2402",
  "total": 14.5
}
{
  "id": "ORD-2403",
  "total": 40
}
```

Square brackets do the same for arrays:
`[.models[].name]` collects the five-name stream of
chapter 2 into a single array value:

```
$ jq '[.models[].name]' models.json
[
  "ember-2:7b",
  "ember-2:32b",
  "kestrel-1:8b",
  "kestrel-1:1.5b",
  "harbor-4:70b"
]
```

Almost every serious jq filter is these two
brackets plus chapter 3's `select`: explode, test,
rebuild.

## Strings with values inside: interpolation

Inside a string, `\(…)` splices in a filter's
result. It's how JSON becomes sentences:

```
$ jq -r '.models[] | "\(.name) (\(.details.parameter_size), ctx \(.details.context_length))"' models.json
ember-2:7b (7.2B, ctx 32768)
ember-2:32b (32.8B, ctx 32768)
kestrel-1:8b (8.1B, ctx 8192)
kestrel-1:1.5b (1.5B, ctx 4096)
harbor-4:70b (70.6B, ctx 16384)
```

Numbers and booleans splice as their JSON text;
strings splice *without* their quotes. Which
brings up the flag doing quiet work in that
command:

## Raw output: `-r`

By default jq's output is JSON, so a string result
is quoted:

```
$ jq '.models[0] | "\(.name) (\(.details.parameter_size))"' models.json
"ember-2:7b (7.2B)"
```

With `-r` (raw output), string results print as
themselves — no quotes, and escape sequences like
`\t` become real tabs:

```
$ jq '.models[] | .name' models.json
"ember-2:7b"
"ember-2:32b"
"kestrel-1:8b"
"kestrel-1:1.5b"
"harbor-4:70b"

$ jq -r '.models[] | .name' models.json
ember-2:7b
ember-2:32b
kestrel-1:8b
kestrel-1:1.5b
harbor-4:70b
```

Anything destined for a human, a shell loop, or
another program that expects plain text wants
`-r`. Anything destined for another JSON tool does
not — the quotes are the format. Numbers, booleans,
objects, and arrays are unaffected by `-r`; only
strings change.

## Formatted rows: `@csv`, `@tsv`, and friends

The `@` operators format an array as one text line.
`@csv` quotes strings, doubles internal quotes, and
joins with commas — fed the order rows (with totals
computed on the way), it produces a file a
spreadsheet will open without complaint:

```
$ jq -r '.orders[] | [.id, .customer.name, ([.items[] | .qty * .price] | add), .status] | @csv' orders.json
"ORD-2401","Ada Byrne",50,"shipped"
"ORD-2402","Tomas Reyes",14.5,"pending"
"ORD-2403","Priya Nair",40,"shipped"
```

`@tsv` is the same idea with tabs and no quoting,
the natural fit for terminals and `column`-style
tools:

```
$ jq -r '.orders[] | [.id, .customer.city, .status] | @tsv' orders.json
ORD-2401	Limerick	shipped
ORD-2402	Galway	pending
ORD-2403	Cork	shipped
```

(Both need `-r`: without it you'd get each line
wrapped in JSON quotes, escapes and all.) The
family also includes `@text` (plain string form),
`@json` (the value as a JSON string), `@base64`,
`@uri`, and `@sh` (shell-quoted, for building
commands safely — chapter 11 territory). One taste
of `@base64`:

```
$ jq -r '.models[0].name | @base64' models.json
ZW1iZXItMjo3Yg==
```

A warning that belongs here: `@csv` and `@tsv`
refuse values that aren't strings, numbers,
booleans, or null — feed one an object or a nested
array and it errors rather than guessing. Build
flat rows of scalars, exactly as above, and they
behave.
