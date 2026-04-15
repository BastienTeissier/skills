# pip Audit Checklist

Audit reference for repositories using **pip** as their Python package manager.

pip is the standard Python package installer. This checklist targets the classic workflow: `requirements.txt` with pinned versions and `pip install -r`.

## Key Files to Inspect

- `requirements.txt`, `requirements/*.txt` (split files for dev, test, prod)
- `setup.py`, `setup.cfg`, `pyproject.toml` (package metadata and build config)
- `.pip.conf` or `pip.conf` (pip configuration)
- `constraints.txt` (version constraints file)
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

Inspect: CI workflows, Dockerfiles, pip config, `requirements.txt`

Pass when:
- `--only-binary :all:` or `--only-binary <pkg>` is used in CI and production installs to avoid executing arbitrary `setup.py` code from source distributions
- Exceptions for packages that genuinely require source builds are documented

Fail signals:
- Source distributions are built without review in CI or production
- No `--only-binary` flag and packages with native extensions are installed from sdist

Default severity: High

### 2. Delay adoption of newly published versions

Scope: repo plus developer environment

Inspect: dependency bot config, team process docs

Pass when:
- Dependency bot config (Renovate/Dependabot) enforces a minimum stabilization window before merging version bumps
- Or the team documents a manual cooldown policy for new releases

Fail signals:
- No cooldown mechanism — freshly published versions are installed immediately
- pip has no built-in release-age gating, so this must be enforced through process or bot config

Default severity: Medium

### 3. Harden with package vetting tools

Scope: process and CI

Inspect: CI workflows, pre-commit config, contributor docs

Pass when:
- `pip-audit` or `uv-secure` runs in CI to detect known vulnerabilities in installed packages
- The team documents a vetting step before adding new packages

Fail signals:
- No automated vulnerability scanning in CI
- No evidence of vetting for one-off package additions

Default severity: Medium

### 4. Pin dependencies with hash verification

Scope: repo

Inspect: `requirements.txt`, `requirements/*.txt`, `constraints.txt`

Pass when:
- `requirements.txt` uses exact version pins (`==`) with `--require-hashes` and each entry includes `--hash=sha256:...`
- Or a lockfile tool (pip-tools, pipenv) generates pinned requirements with hashes
- No unpinned or loosely pinned dependencies (`>=`, `~=` without upper bounds) in production requirements

Fail signals:
- Missing or unpinned `requirements.txt`
- No hash verification — packages can be silently replaced on the index
- Loose version specifiers in production requirements

Default severity: High

### 5. Use deterministic install commands

Scope: repo

Inspect: CI workflows, Dockerfiles, setup scripts

Pass when:
- CI and production builds use `pip install -r requirements.txt` with fully pinned versions and hashes
- `--no-deps` is used where appropriate to prevent transitive resolution surprises
- Installs do not use `pip install <package>` without a lockfile or pin

Fail signals:
- `pip install` without pinned requirements in CI or production
- Workflows that can resolve different versions on each run

Default severity: High

### 6. Avoid blind upgrades

Scope: repo and automation

Inspect: CI workflows, release scripts, Dependabot/Renovate configs

Pass when:
- Updates arrive through reviewed pull requests or interactive workflows
- `pip install --upgrade` is not run unattended on default branches

Fail signals:
- `pip install --upgrade` or `pip-compile --upgrade` in CI without review gates
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
- The project uses virtual environments (`venv`, `virtualenv`) consistently
- Or development is isolated through dev containers or Docker
- No system-wide installs (`pip install --user` or bare `pip install` outside a venv)

Fail signals:
- `pip install` without a virtual environment
- `--user` or system-level installs recommended in contributor docs
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
- Manual publishing with unscoped credentials

Default severity: High for public packages

### 10. Publish with provenance attestations

Scope: maintainer CI

Inspect: release workflows, publish scripts

Pass when:
- Public package releases use PyPI's trusted publishing with attestations
- The workflow uses `pypa/gh-action-pypi-publish` with OIDC
- Attestations are verifiable on PyPI

Fail signals:
- Public package publishing without attestations or trusted publishing

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

Inspect: `requirements.txt`, `setup.cfg`, `pyproject.toml`, optional dependency groups

Pass when:
- The dependency footprint is justified
- Dev/test dependencies are separated from production requirements (e.g. `requirements-dev.txt`, `[project.optional-dependencies]`)
- No unnecessary heavy dependencies when lighter alternatives exist
- SBOM generation is considered for supply chain visibility (e.g. `cyclonedx-py`)

Fail signals:
- Bloated dependencies with obvious lighter alternatives
- Dev dependencies mixed into production requirements

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
- The team inspects the actual wheel or sdist for high-risk dependencies (e.g. `pip download --no-deps <pkg>` then inspect the archive for unexpected files, native extensions, or post-install hooks)

Fail signals:
- Package review relies only on PyPI metadata or GitHub source view

Default severity: Low to Medium

## Evidence Tips

- pip has no built-in lockfile — `requirements.txt` with `--require-hashes` is the closest equivalent. Consider recommending pip-tools (`pip-compile`) as an upgrade path for projects lacking hash-pinned requirements.
- `--only-binary :all:` prevents arbitrary `setup.py` execution from source distributions but may fail for packages without pre-built wheels for the target platform.
- pip has no built-in release-age gating — this must be enforced via bot config or team process.
- `pip-audit` can scan both `requirements.txt` files and installed environments against the OSV database.
- For maintainer checks, treat the presence of a `setup.py`/`setup.cfg`/`pyproject.toml` with `[project]` metadata and no `Private :: Do Not Upload` classifier as a signal to inspect publishing items 9–11.
- Multiple index URLs (`--extra-index-url`) without `--index-url` pinning can be vulnerable to dependency confusion attacks.
