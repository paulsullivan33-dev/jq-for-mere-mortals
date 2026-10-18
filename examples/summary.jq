# summary.jq -- a fleet summary from inventory.json
#
# Run it with:
#   jq -f summary.jq inventory.json
#
# The input is the inventory array. The output is one
# summary object. Filters this size are why -f exists:
# nobody should type this at a prompt twice.

{
  machines: length,
  total_ram_gb: (map(.ram_gb) | add),
  by_role: (
    sort_by(.role)
    | group_by(.role)
    | map({role: .[0].role, count: length})
  ),
  low_disk: [
    .[]
    | select(.disk_free_gb / .disk_total_gb < 0.15)
    | .name
  ]
}
