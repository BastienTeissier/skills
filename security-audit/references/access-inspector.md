# Access Inspector

## Overview

Reads the Committed Inventory that the all-access-inspector skill keeps in `tools/access-inspector/inventory.json`: every HTTP endpoint of an application with its authentication and authorization, on any stack. The audit starts from these committed facts. It never boots or runs the application, and never regenerates the inventory.

## Installation

Nothing to install for the audit itself; the parse script needs `jq` (`brew install jq`).

A project without an inventory is fitted once with the all-access-inspector skill, which commits `tools/access-inspector/`.

## Verification

```bash
find <project-path> -path '*/tools/access-inspector/inventory.json' -not -path '*/node_modules/*' -not -path '*/.venv/*'
```

No result: report "No Committed Inventory: fit the project with the all-access-inspector skill first" and stop this scanner. Do not try to boot the application or run another access scanner instead.

Several results: each is one application. Run the steps below once per inventory and report one section per application.

## Scan: staleness check only

The inventory is committed; the only thing to run is its check, to learn whether the code has moved since. From the directory that holds `tools/` (for Django, the one with `manage.py`), run the check step of `tools/access-inspector/ci-snippet.*` with the project's own runner, e.g.:

```bash
uv run python tools/access-inspector/inspect.py --check
```

- Exit 0: the inventory is current.
- Exit 1: the inventory is **stale**. Keep its per-endpoint diff, and proceed on the committed facts.
- Exit 2, or the project cannot run here (dependencies not installed, services missing): staleness is **not checked**. Proceed on the committed facts.

Never run `inspect.py` without `--check`, and never edit `inventory.json`.

## Output

- `<output-dir>/access-inspector.txt` - one line per inventory: `<path to inventory.json> <current|stale|not checked>`, then the `--check` diff of any stale one

## Parse Output

Run the bundled parse script on each inventory:

```bash
bash <skill-path>/scripts/parse_access_inspector.sh <app>/tools/access-inspector/inventory.json
```

Requires: `jq`

Output sections:
- `=== ACCESS INSPECTOR SUMMARY ===` — stack, discovery mode, coverage, endpoint counts by authentication, authorization, layer and Project Dimension
- `=== ANONYMOUS ===` — endpoints anyone can call, one JSON object per line
- `=== OPTIONAL WITHOUT RULE ===` — endpoints that read the user when present but check nothing
- `=== UNKNOWN (unexplained) ===` — endpoints whose access the inventory could not settle, with no reason
- `=== ACKNOWLEDGED UNKNOWN ===` — unknown endpoints the inventory explains, with `unknown_reason`

## Report Guidelines

### State what the inventory covers

Open each application's section with its inventory path, `discovery_mode` and `coverage`, so a `best-effort` inventory (static discovery, or an improvised stack) is never read as complete. On a stale inventory, put a warning banner first: "Inventory stale: the code changed since it was committed; findings below may miss or misplace endpoints", followed by the endpoints the `--check` diff names. On "not checked", say so in one line.

### Analyze the code

For each endpoint in ANONYMOUS, OPTIONAL WITHOUT RULE and UNKNOWN (unexplained), read the handler (`handler` is `path:line` in the project, or the dotted name of framework code) and what it touches: models, serializers, outgoing calls.

### Interpret results

- List ANONYMOUS first: mutating methods (`POST`, `PUT`, `PATCH`, `DELETE`, `ANY`) and API paths before reads.
- Classify each endpoint's risk (critical, high, medium, low) from what the handler exposes or changes, not from the classification alone: a login page or a health check is anonymous by design.
- OPTIONAL WITHOUT RULE: check that the handler filters what it returns by `request.user` when there is one.
- UNKNOWN (unexplained): a gap in the inventory, always reported. When the section is empty, write "No unexplained endpoints".
- ACKNOWLEDGED UNKNOWN: quote the reason. It is not a finding unless reading the handler contradicts the reason.
- Remember the layer: `framework-default` means no check was declared at all.

### Generate advice

- Recommend the fix in the project's own framework idiom (decorator, permission class, middleware rule, security config), with a minimal snippet.
- Recommend refitting the inventory (all-access-inspector skill, update mode) when it is stale or has unexplained unknowns.
