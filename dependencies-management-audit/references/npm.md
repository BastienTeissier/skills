# npm Audit Checklist

Audit reference for repositories using **npm** as their package manager.

Source basis: Liran Tal's npm security best-practices guide at `https://github.com/lirantal/npm-security-best-practices`. Re-check the upstream document when the latest recommendations matter.

## Key Files to Inspect

- `package.json` (root and workspaces)
- `package-lock.json`
- `.npmrc`
- `.github/workflows/*`, `.gitlab-ci.yml`
- `.env*`, `.devcontainer/*`, Dockerfiles

## Status Model

- `Pass`: repo evidence satisfies the control
- `Fail`: repo evidence shows the control is missing or contradicted
- `Needs confirmation`: the control cannot be proven from repository contents alone
- `Not applicable`: the repo's role makes the control irrelevant

## Checklist

### 1. Constrain install-time script execution

Scope: repo plus developer environment

Inspect: `.npmrc`, `package.json`

Pass when:
- `.npmrc` contains `ignore-scripts=true` and trusted packages are allowlisted individually
- Or `package.json` uses `"preinstall"` hooks that restrict execution

Fail signals:
- Unrestricted `npm install` with no lifecycle-script restrictions
- No control over postinstall execution
- Git or tarball sources allowed without review

Default severity: High

### 2. Delay adoption of newly published versions

Scope: repo plus developer environment

Inspect: `.npmrc`, dependency bot config

Pass when:
- Dependency update PRs use a cooldown period before merging
- Bot config (Renovate/Dependabot) enforces a minimum stabilization window

Fail signals:
- Direct installs or automated upgrades always target the newest release immediately

Default severity: Medium

### 3. Harden ad-hoc installs with package vetting tools

Scope: process

Inspect: shell aliases, docs, CI wrappers, `package.json` scripts

Pass when:
- The team uses a pre-install vetting tool such as `npq` or a blocking firewall such as `sfw`, or documents an equivalent review step

Fail signals:
- No evidence of vetting for one-off package additions

Default severity: Medium

### 4. Validate lockfiles and dependency sources

Scope: repo

Inspect: `package-lock.json`, `package.json`, `.npmrc`

Pass when:
- `package-lock.json` is committed
- Lockfile is validated with `lockfile-lint` or an equivalent policy (e.g. in CI or as a `package.json` script)
- No git or direct tarball sources appear without justification

Fail signals:
- Missing lockfile
- No lockfile validation
- Git or direct tarball sources without justification

Default severity: High

### 5. Use deterministic install commands

Scope: repo

Inspect: CI workflows, Dockerfiles, setup scripts

Pass when:
- CI and production builds use `npm ci` (not `npm install`)

Fail signals:
- `npm install` in CI or production image builds
- Workflows that can mutate the lockfile during install

Default severity: High

### 6. Avoid blind upgrades

Scope: repo and automation

Inspect: CI workflows, release scripts, Dependabot/Renovate/Snyk configs, `package.json` scripts

Pass when:
- Updates arrive through reviewed pull requests or interactive workflows
- Automated tooling avoids force-updating every dependency in place

Fail signals:
- `npm update` in CI or scripts
- `npm-check-updates -u` or `ncu -u` unattended
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
- The project supports isolated development through a dev container or comparable sandboxed workflow

Fail signals:
- No isolation guidance for a repo with heavy dependency churn or risky install behavior

Default severity: Medium

### 9. Require 2FA for npm maintainers

Scope: maintainer account

Inspect: maintainer docs, release docs, user confirmation

Pass when:
- Maintainers confirm npm 2FA is required for auth-and-writes

Fail signals:
- Maintainers publish without 2FA

Default severity: High for public packages

### 10. Publish with provenance attestations

Scope: maintainer CI

Inspect: release workflows, publish scripts

Pass when:
- Public package releases use `npm publish --provenance`
- The workflow grants `id-token: write`

Fail signals:
- Public package publishing without provenance

Default severity: High for public packages

### 11. Use trusted publishing with OIDC

Scope: maintainer CI and npm registry settings

Inspect: release workflows, registry configuration documentation, user confirmation

Pass when:
- Publishing relies on trusted OIDC-based federation instead of long-lived npm tokens

Fail signals:
- Long-lived publish tokens stored in CI secrets
- `npm publish` exists but registry-side trusted publishing is unknown

Default severity: High for public packages

### 12. Minimise the dependency tree

Scope: repo design

Inspect: `package.json`, workspace manifests, repeated utility dependencies

Pass when:
- The dependency footprint is justified
- Libraries avoid easy-to-remove utility packages
- Direct git or URL dependencies are rare and deliberate

Fail signals:
- Bloated library dependencies with obvious native or platform alternatives

Default severity: Medium

### 13. Review package health before adoption

Scope: dependency intake process

Inspect: contributor docs, issue or PR templates, team process notes

Pass when:
- The team checks package health signals before adopting new dependencies

Fail signals:
- No evidence that new packages are reviewed for maintenance, popularity, or known vulnerabilities

Default severity: Medium

### 14. Inspect the published artifact, not just the npm web page

Scope: dependency intake process

Inspect: contributor docs, package review notes, user confirmation

Pass when:
- The team inspects the actual tarball (`npm pack --dry-run` or equivalent) for high-risk dependencies

Fail signals:
- Package review relies only on the npm website metadata or rendered source view

Default severity: Low to Medium

## Evidence Tips

- A repo can only prove repo-level controls. Machine-level settings such as global npm config often require explicit user confirmation.
- Monorepos often mix controls. Score each workspace separately, then summarise the strongest and weakest paths.
- For maintainer checks, treat the presence of a publish workflow or a non-private package as a signal to inspect items 9–11.
