# poetry Audit Checklist

Audit reference for repositories using **Poetry** as their Python package manager.

Poetry is a Python dependency management and packaging tool. It uses `pyproject.toml` for project metadata and `poetry.lock` for deterministic dependency resolution.

## Key Files to Inspect

- `pyproject.toml` (especially `[tool.poetry]`, `[tool.poetry.dependencies]`, `[tool.poetry.group.*]`)
- `poetry.lock`
- `poetry.toml` (project-level config override)
- `.github/workflows/*`, `.gitlab-ci.yml`
- `.env*`, `.devcontainer/*`, Dockerfiles

## Status Model

- `Pass`: repo evidence satisfies the control
- `Fail`: repo evidence shows the control is missing or contradicted
- `Needs confirmation`: the control cannot be proven from repository contents alone
- `Not applicable`: the repo's role makes the control irrelevant

## Checklist

### 1. Prefer binary wheel installations

Scope: repo and CI

Inspect: CI workflows, Dockerfiles, `poetry.toml`, `pyproject.toml`

Pass when:
- `installer.no-binary` is not set to allow-all source builds, or source builds are limited to explicitly justified packages
- CI and production installs prefer pre-built wheels to avoid executing arbitrary `setup.py` code from source distributions

Fail signals:
- Source distributions are built without review in CI or production
- Packages with native extensions are compiled from sdist without justification

Default severity: High

### 2. Delay adoption of newly published versions

Scope: repo plus developer environment

Inspect: dependency bot config, team process docs

Pass when:
- Dependency bot config (Renovate/Dependabot) enforces a minimum stabilization window before merging version bumps
- Or the team documents a manual cooldown policy for new releases

Fail signals:
- No cooldown mechanism — freshly published versions are installed immediately
- Poetry has no built-in release-age gating, so this must be enforced through process or bot config

Default severity: Medium

### 3. Harden with package vetting tools

Scope: process and CI

Inspect: CI workflows, pre-commit config, contributor docs

Pass when:
- `pip-audit` or `uv-secure` runs in CI to detect known vulnerabilities (pip-audit can scan `poetry.lock` via `pip-audit --requirement <(poetry export -f requirements.txt)`)
- The team documents a vetting step before adding new packages

Fail signals:
- No automated vulnerability scanning in CI
- No evidence of vetting for one-off package additions

Default severity: Medium

### 4. Validate lockfile and dependency sources

Scope: repo

Inspect: `poetry.lock`, `pyproject.toml`

Pass when:
- `poetry.lock` is committed to version control
- Lockfile content hash matches `pyproject.toml` (Poetry stores a content-hash in the lockfile)
- No unexpected supplemental package sources that could enable dependency confusion
- Git, URL, or path dependencies in `[tool.poetry.dependencies]` are justified and point to trusted origins

Fail signals:
- Missing lockfile
- Stale lockfile (content-hash mismatch with `pyproject.toml`)
- Supplemental sources configured without `priority = "explicit"` — enabling dependency confusion
- Git or URL dependencies pointing to unreviewed origins

Default severity: High

### 5. Use deterministic install commands

Scope: repo

Inspect: CI workflows, Dockerfiles, setup scripts

Pass when:
- CI and production builds use `poetry install --no-update` (installs from the existing lockfile without resolving new versions)
- Or `poetry install --only main` for production to exclude dev dependencies
- `poetry lock` is not run as part of CI install steps

Fail signals:
- `poetry install` without `--no-update` in CI (may trigger resolution)
- `poetry update` in CI or production builds
- Workflows that can mutate the lockfile during install

Default severity: High

### 6. Avoid blind upgrades

Scope: repo and automation

Inspect: CI workflows, release scripts, Dependabot/Renovate configs

Pass when:
- Updates arrive through reviewed pull requests or interactive workflows
- `poetry update` is not run unattended on default branches

Fail signals:
- `poetry update` in CI without review gates
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

Inspect: `.devcontainer/devcontainer.json`, Dockerfiles, contributor docs, `poetry.toml`

Pass when:
- `virtualenvs.in-project = true` is set in `poetry.toml` (keeps venvs inside the project for reproducibility and container compatibility)
- Or development is isolated through dev containers or Docker
- `virtualenvs.create` is not set to `false` without a container-based workflow

Fail signals:
- `virtualenvs.create = false` without containerised development
- System-level installs recommended in contributor docs
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
- `poetry publish` with inline credentials or unscoped tokens

Default severity: High for public packages

### 10. Publish with provenance attestations

Scope: maintainer CI

Inspect: release workflows, publish scripts

Pass when:
- Public package releases use PyPI's trusted publishing with attestations
- The workflow uses `pypa/gh-action-pypi-publish` with OIDC (Poetry builds the package, then the action publishes with attestations)

Fail signals:
- Public package publishing without attestations or trusted publishing
- `poetry publish` run manually without provenance

Default severity: High for public packages

### 11. Secure CI/CD release pipelines

Scope: maintainer CI

Inspect: release workflows, GitHub Actions configs

Pass when:
- GitHub Actions are pinned by commit SHA (not tags)
- `GITHUB_TOKEN` permissions are minimally scoped
- Workflow hardening is validated with `zizmor` or equivalent linter
- Release jobs use isolated runners or environments

Fail signals:
- Actions pinned by mutable tag (e.g. `@v3` instead of `@sha256:...`)
- Overly broad `GITHUB_TOKEN` permissions
- No workflow security linting

Default severity: Medium

### 12. Minimise the dependency tree

Scope: repo design

Inspect: `pyproject.toml`, `poetry.lock`, dependency groups

Pass when:
- The dependency footprint is justified
- Dev/test/docs dependencies are separated into dependency groups (`[tool.poetry.group.dev.dependencies]`, `[tool.poetry.group.test.dependencies]`)
- No unnecessary heavy dependencies when lighter alternatives exist
- SBOM generation is considered for supply chain visibility (e.g. `cyclonedx-py`)

Fail signals:
- Bloated dependencies with obvious lighter alternatives
- Dev dependencies in the main `[tool.poetry.dependencies]` group

Default severity: Medium

### 13. Review package health before adoption

Scope: dependency intake process

Inspect: contributor docs, issue or PR templates, team process notes

Pass when:
- The team checks package health signals before adopting new dependencies (maintenance status, download counts, known vulnerabilities, vulnerability databases)

Fail signals:
- No evidence that new packages are reviewed before adoption

Default severity: Medium

### 14. Inspect the published artifact

Scope: dependency intake process

Inspect: contributor docs, package review notes, user confirmation

Pass when:
- The team inspects the actual wheel or sdist for high-risk dependencies (e.g. `poetry build` then inspect the archive, or `pip download --no-deps <pkg>` to review the published artifact)

Fail signals:
- Package review relies only on PyPI metadata or GitHub source view

Default severity: Low to Medium

## Evidence Tips

- Poetry stores a `content-hash` in `poetry.lock` that reflects the dependency specification in `pyproject.toml`. A mismatch means the lockfile is stale.
- `poetry install --no-update` is the Poetry equivalent of `npm ci` — it installs exactly what the lockfile specifies without re-resolving.
- Poetry's supplemental sources can introduce dependency confusion if not configured with `priority = "explicit"`. Check `[[tool.poetry.source]]` entries.
- `poetry export -f requirements.txt` can bridge Poetry projects to tools that expect `requirements.txt` (e.g. `pip-audit`, Docker builds without Poetry).
- For maintainer checks, treat the presence of `[tool.poetry]` with a `name` and `version` and no `Private :: Do Not Upload` classifier as a signal to inspect publishing items 9–11.
- Poetry does not have a built-in release-age gating mechanism. This must be enforced via dependency bot configuration or team process.
