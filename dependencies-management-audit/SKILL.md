---
name: dependencies-management-audit
description: Audit dependency-management practices in repositories that use npm, pnpm, Yarn, Bun, uv, pip, or Poetry. Use when you need to review package installation hardening, lockfile integrity, deterministic installs, dependency update automation, `.env` secret handling, dev-container isolation, publishing controls, provenance or OIDC setup, or overall supply-chain hygiene.
---

# Dependencies Management Audit

Audit a repository's dependency-management posture. Each supported package manager has its own audit checklist in the `references/` folder.

Prefer repository evidence over assumptions. When a control can only be verified from a developer workstation, package registry, or npm account settings, mark it as `Needs confirmation` instead of failing it outright.

## Step 1: Detect Package Managers

Identify which package manager(s) the repository uses by checking the following signals in order:

1. **Lockfiles** in the repository root and workspace directories:
   - `package-lock.json` → **npm**
   - `pnpm-lock.yaml` → **pnpm**
   - `yarn.lock` → **yarn**
   - `bun.lock` or `bun.lockb` → **bun**
   - `uv.lock` → **uv**
   - `poetry.lock` → **poetry**
   - `requirements.txt` or `requirements/*.txt` → **pip**
2. **Config files** in the repository root:
   - `.npmrc` → **npm**
   - `pnpm-workspace.yaml` → **pnpm**
   - `.yarnrc.yml` → **yarn**
   - `bunfig.toml` → **bun**
   - `uv.toml` or `[tool.uv]` in `pyproject.toml` → **uv**
   - `poetry.toml` or `[tool.poetry]` in `pyproject.toml` → **poetry**
   - `setup.py`, `setup.cfg`, or `.pip.conf` → **pip**
3. **`packageManager` field** in the root `package.json` (e.g. `"pnpm@9.1.0"` → **pnpm**)

If multiple package managers coexist, call out the operational risk and audit each active one separately.

If no package manager is detected, report that the repository has no dependency-management posture to audit.

## Step 2: Read Audit Checklists

For each detected package manager, read its reference file:

- npm → `references/npm.md`
- pnpm → `references/pnpm.md`
- Yarn → `references/yarn.md`
- Bun → `references/bun.md`
- uv → `references/uv.md`
- pip → `references/pip.md`
- Poetry → `references/poetry.md`

## Step 3: Collect Evidence

Open the highest-signal files directly before writing findings:

- Root and workspace `package.json` files
- `requirements.txt`, `requirements/*.txt`, `setup.py`, `setup.cfg`
- Lockfiles
- Package manager config files (`.npmrc`, `pnpm-workspace.yaml`, `.yarnrc.yml`, `bunfig.toml`, `uv.toml`, `poetry.toml`, `.pip.conf`, `pyproject.toml`)
- CI workflows (`.github/workflows/*`, `.gitlab-ci.yml`, release pipelines)
- `.env*` files, `.devcontainer/*`, Dockerfiles
- Dependency bot configs (Dependabot, Renovate, Snyk)

## Step 4: Classify the Audit

Determine which scopes apply before scoring controls:

- `Application consumer`: installs dependencies but does not publish packages
- `Package maintainer`: publishes packages or appears intended to publish
- `Mixed monorepo`: contains both deployable apps and publishable packages

Scope-specific guidance is defined in each reference file. In general:

- Core checks (lockfiles, deterministic installs, build-script constraints, secrets) are relevant to any repository
- Publishing checks are maintainer-facing; mark `Not applicable` if the repo does not publish packages
- Process checks (package health review, artifact inspection) use repo evidence when available and otherwise mark `Needs confirmation`

## Step 5: Evaluate Each Checklist Item

Use the reference file for the detected package manager as the scoring guide.

For every applicable item, assign one status:

- `Pass`: evidence clearly satisfies the control
- `Fail`: evidence clearly shows the control is missing or contradicted
- `Needs confirmation`: the control is mainly workstation, registry, or account level and cannot be proven from repo contents
- `Not applicable`: the control does not fit the repository's role

When evidence is mixed, prefer the stricter interpretation and explain the gap.

## Severity Guidance

Use this default severity model unless repo context justifies a change:

- `High`: install-time code execution is not constrained; CI uses non-deterministic installs; lockfiles are not validated; plaintext secrets are stored in `.env`; publish pipelines lack trusted publishing controls for public packages
- `Medium`: no cooldown for fresh releases; blind upgrade automation exists; no dev-container isolation; package-health review process is absent; dependency tree is unnecessarily large for a library
- `Low`: optional hardening is absent but compensating controls exist

Keep findings actionable. Name the file, explain the risk in one or two sentences, and give the smallest plausible fix for the detected package manager.

## Reporting Format

Present the audit in this order:

1. Findings ordered by severity, with file references
2. Open questions or `Needs confirmation` items
3. Checklist matrix with item id, short title, status, and evidence
4. Recommended next changes, prioritised for the current repo

Keep the checklist concise. The findings section should carry the real analysis.

## Audit Rules

- Prefer exact file evidence over generic policy language.
- Distinguish root config from workspace-local overrides.
- If multiple package managers coexist, call out the operational risk and assess each active one.
- Do not print secret values from `.env` files; refer only to keys and file paths.
- If internet access is available and the repo is adding or evaluating a package, use the process checks in items `13` and `14` to review package health or inspect the published tarball.
