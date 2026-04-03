# uv Audit Checklist

Audit reference for repositories using **uv** as their Python package manager.

uv is a fast Python package manager by Astral. It handles dependency resolution, lockfile management, virtual environments, and Python version management.

## Key Files to Inspect

- `pyproject.toml` (root and workspaces — especially `[tool.uv]` and `[tool.uv.sources]`)
- `uv.toml` (project-level config override)
- `uv.lock`
- `.python-version`
- `.github/workflows/*`, `.gitlab-ci.yml`
- `.env*`, `.devcontainer/*`, Dockerfiles

## Status Model

- `Pass`: repo evidence satisfies the control
- `Fail`: repo evidence shows the control is missing or contradicted
- `Needs confirmation`: the control cannot be proven from repository contents alone
- `Not applicable`: the repo's role makes the control irrelevant

## Checklist

### 1. Constrain build-time code execution

Scope: repo plus developer environment

Inspect: `pyproject.toml`, `uv.toml`

Pass when:
- Build isolation is kept enabled (default) — uv builds packages in isolated virtual environments with only declared build dependencies
- Build isolation is only disabled (`--no-build-isolation`) for explicitly justified packages

Fail signals:
- `--no-build-isolation` used broadly or without justification
- Packages with arbitrary build scripts are installed without review

Default severity: High

### 2. Delay adoption of newly published versions

Scope: repo plus developer environment

Inspect: `pyproject.toml`, `uv.toml`, dependency bot config

Pass when:
- `--exclude-newer` is configured (as a CLI flag, in `uv.toml`, or in `[tool.uv]`) to refuse packages published more recently than a given age or timestamp
- Or dependency bot config (Renovate/Dependabot) enforces a minimum stabilization window

Fail signals:
- No `exclude-newer` and no bot-level cooldown — freshly published versions are installed immediately

Default severity: High

### 3. Harden ad-hoc installs with package vetting

Scope: process

Inspect: contributor docs, CI wrappers, team process notes

Pass when:
- The team reviews new dependencies before adding them (e.g. checking PyPI metadata, source repo, maintainer history)
- `uv tool run` is used for one-off tool execution in temporary isolated environments rather than permanent installs

Fail signals:
- No evidence of vetting for one-off package additions

Default severity: Medium

### 4. Validate lockfile and dependency sources

Scope: repo

Inspect: `uv.lock`, `pyproject.toml` (`[tool.uv.sources]`)

Pass when:
- `uv.lock` is committed to version control
- Dependency sources in `[tool.uv.sources]` are reviewed — git, URL, and path sources are justified and point to trusted origins
- No unexpected alternative index configurations that could enable dependency confusion

Fail signals:
- Missing lockfile
- Git or URL sources pointing to unreviewed or untrusted origins
- Multiple index sources without explicit `--index-strategy` to prevent dependency confusion

Default severity: High

### 5. Use deterministic install commands

Scope: repo

Inspect: CI workflows, Dockerfiles, setup scripts

Pass when:
- CI and production builds use `uv sync --locked` (validates lockfile is up-to-date with `pyproject.toml` then installs deterministically)
- Or `uv sync --frozen` when lockfile correctness is already guaranteed upstream

Fail signals:
- `uv sync` or `uv pip install` without `--locked` or `--frozen` in CI or production builds
- Workflows that can mutate the lockfile during install

Default severity: High

### 6. Avoid blind upgrades

Scope: repo and automation

Inspect: CI workflows, release scripts, Dependabot/Renovate configs, `pyproject.toml` scripts

Pass when:
- Updates arrive through reviewed pull requests or interactive workflows
- `uv lock --upgrade` is not run unattended on default branches

Fail signals:
- `uv lock --upgrade` in CI without review gates
- Unattended mass upgrades on default branches

Default severity: Medium

### 7. Keep secrets out of plaintext `.env` files

Scope: repo and local development

Inspect: `.env*`, developer docs, dev-container setup

Pass when:
- `.env` files contain references, placeholders, or non-secret defaults rather than real secrets
- Secret managers inject values at runtime

Fail signals:
- Literal credentials in `.env` files
- Committed tokens, passwords, or API keys

Default severity: High

### 8. Isolate local development

Scope: repo and developer workflow

Inspect: `.devcontainer/devcontainer.json`, Dockerfiles, contributor docs

Pass when:
- The project supports isolated development through a dev container, Docker, or comparable sandboxed workflow
- uv's virtual environment isolation is used consistently (not `--system` installs)

Fail signals:
- `uv pip install --system` used broadly, bypassing venv isolation
- No isolation guidance for a repo with heavy dependency churn

Default severity: Medium

### 9. Protect PyPI publishing credentials

Scope: maintainer account and CI

Inspect: release workflows, publish scripts, user confirmation

Pass when:
- PyPI publishing uses trusted publishing (OIDC) via GitHub Actions or equivalent
- Or API tokens are scoped to specific projects (not global tokens)
- 2FA is enabled on PyPI accounts

Fail signals:
- Global PyPI tokens stored in CI secrets
- No 2FA on PyPI accounts
- Manual publishing without credential scoping

Default severity: High for public packages

### 10. Publish with provenance attestations

Scope: maintainer CI

Inspect: release workflows, publish scripts

Pass when:
- Public package releases use PyPI's trusted publishing with attestations
- The workflow uses `pypa/gh-action-pypi-publish` or equivalent with OIDC

Fail signals:
- Public package publishing without attestations or trusted publishing

Default severity: High for public packages

### 11. Minimise the dependency tree

Scope: repo design

Inspect: `pyproject.toml`, `uv.lock`, optional dependency groups

Pass when:
- The dependency footprint is justified
- Dev/test dependencies are properly separated in optional groups
- No unnecessary heavy dependencies when lighter alternatives exist

Fail signals:
- Bloated dependencies with obvious lighter alternatives
- Dev dependencies mixed into production requirements

Default severity: Medium

### 12. Review package health before adoption

Scope: dependency intake process

Inspect: contributor docs, issue or PR templates, team process notes

Pass when:
- The team checks package health signals before adopting new dependencies (maintenance status, download counts, known vulnerabilities)

Fail signals:
- No evidence that new packages are reviewed before adoption

Default severity: Medium

### 13. Inspect the published artifact

Scope: dependency intake process

Inspect: contributor docs, package review notes, user confirmation

Pass when:
- The team inspects the actual wheel or sdist for high-risk dependencies (e.g. checking for unexpected native extensions or post-install hooks)

Fail signals:
- Package review relies only on PyPI metadata or GitHub source view

Default severity: Low to Medium

## Evidence Tips

- uv builds packages in isolated environments by default — the main risk is when `--no-build-isolation` is used.
- `--exclude-newer` supports both absolute timestamps (`2026-01-01`) and relative durations (`3d`) for release-age gating.
- `uv sync --locked` is stricter than `--frozen`: it validates the lockfile matches `pyproject.toml` before installing. Prefer `--locked` in CI.
- Check `[tool.uv.sources]` for git/URL/path dependencies — these bypass the standard index and need manual trust assessment.
- Multiple index configurations without `--index-strategy explicit` can be vulnerable to dependency confusion attacks.
- uv.lock includes cryptographic hashes for all distributions — this provides integrity validation on install.
