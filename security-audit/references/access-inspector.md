# Access Inspector

## Overview

Reads the Committed Inventory that the all-access-inspector skill keeps in `tools/access-inspector/inventory.json`: every HTTP endpoint of an application with its authentication and authorization, on any stack. The audit starts from these committed facts. It never boots or runs the application, and never regenerates the inventory.

## Installation

The parse script needs `jq` (`brew install jq`, `apt-get install jq`). The staleness check runs with the project's own toolchain (e.g. `uv` and its installed dependencies); without it, staleness is reported as not checked.

A project without an inventory is fitted once with the all-access-inspector skill, which commits `tools/access-inspector/`.

## Verification

```bash
find <project-path> -path '*/tools/access-inspector/inventory.json' -not -path '*/node_modules/*' -not -path '*/.venv/*'
```

Only `tools/access-inspector/inventory.json` counts; another `inventory.json` (a test oracle, an export) is not a Committed Inventory.

No result: write "No Committed Inventory: fit the project with the all-access-inspector skill first" as this scanner's section of the report, name it under **Scanners used** as "Access Inspector (not run: no inventory)", and stop this scanner: the steps below need an inventory. Do not try to boot the application or run another access scanner instead.

Several results: each is one application. `<app>` is the directory holding `tools/`, i.e. the inventory path minus `tools/access-inspector/inventory.json` (`.` when that leaves nothing). Run the steps below once per inventory and report one section per application.

## Scan: staleness check only

The inventory is committed; the only thing to run is its check, to learn whether the code has moved since. From `<app>` (for Django, the directory with `manage.py`), run the check step of `tools/access-inspector/ci-snippet.*` with the project's own runner. Without a snippet, run `python tools/access-inspector/inspect.py --check` through the runner the project uses (`uv run`, `poetry run`, an activated venv), e.g.:

```bash
uv run python tools/access-inspector/inspect.py --check
```

- Exit 0: the inventory is current.
- Exit 1 with the per-endpoint diff and "differs from the endpoints this code serves": the inventory is **stale**. Keep its per-endpoint diff, and proceed on the committed facts.
- Exit 2, any other failure (a runner or import error also exits non-zero), or the project cannot run here (dependencies not installed, services missing): staleness is **not checked**. Proceed on the committed facts.

Never run `inspect.py` without `--check`, and never edit `inventory.json`.

## Output

- `<output-dir>/access-inspector.txt`, written by you after the scan - one line per inventory, `<current|stale|not checked><TAB><absolute path to inventory.json>`, then the `--check` output of any stale one; not written when Verification found no inventory

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

For each endpoint in every section, ACKNOWLEDGED UNKNOWN included, read the handler (`handler` is `path:line` in the project, or the dotted name of framework code) and what it touches: models, serializers, outgoing calls. When the check lives elsewhere, follow it: `authn_raw`/`authz_raw` name the decorator, permission class or project override (e.g. an `AdminSite` subclass), and `unknown_reason` may point at the URLconf. Group the rows of one path and handler (`GET`/`HEAD`/`OPTIONS`) into one endpoint.

### Interpret results

- List ANONYMOUS first: mutating methods (`POST`, `PUT`, `PATCH`, `DELETE`, `ANY`) and API paths before reads.
- Classify each endpoint's risk (critical, high, medium, low) from what the handler exposes or changes, not from the classification alone: a login page or a health check is anonymous by design.
- OPTIONAL WITHOUT RULE: unless the data is public, check that the handler filters what it returns by `request.user` when there is one.
- UNKNOWN (unexplained): a gap in the inventory, always reported. When the section is empty, write "No unexplained endpoints".
- ACKNOWLEDGED UNKNOWN: quote the reason. It is not a finding unless reading the handler contradicts the reason.
- Remember the layer: `framework-default` means no check was declared at all.

### Map to the report template

- Each endpoint you classify critical or high is a finding in the template's Critical or High section: **Source** Access Inspector, **File** the handler, **Rule/CVE** `access-inspector:<anonymous|optional-without-rule|unknown>`, the method and path in the title. An acknowledged unknown whose handler contradicts its reason takes `access-inspector:unknown`.
- Medium and low endpoints go in a table in the application's section (method, path, handler, risk, one-line reason), not in the severity sections.
- The Summary table's Access Inspector column counts the critical and high ones.

### Generate advice

- Recommend the fix in the project's own framework idiom (decorator, permission class, middleware rule, security config), with a minimal snippet.
- Recommend refitting the inventory (all-access-inspector skill, update mode) when it is stale or has unexplained unknowns.
