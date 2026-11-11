# Sub2API maintained upstream builds

This setup upgrades the **official Wei-Shaw/sub2api release** while preserving the account-level "hide readable thinking" option. It does not freeze the application at 0.2.20.

## Source of truth

- **Upstream:** `Wei-Shaw/sub2api`, latest published non-prerelease release.
- **Standalone patch:** `ci/sub2api-maintained/feature.patch`.
- **Builder:** `.github/workflows/sub2api-upstream-patch.yml` (scheduled and manual).
- **Build output:** GitHub prerelease named `sub2api-patched-vX.Y.Z-<patch-sha>`, containing a gzip-compressed Docker image and SHA256 checksum.
- **Server command:** `/usr/local/sbin/sub2api-maintained-upgrade`.

Each build starts from a **fresh official source archive**, applies the patch with fuzz disabled, runs thinking-visibility regression tests, then builds the full Docker image. A failure prevents publication of any replacement image. The previous production deployment is untouched.

## Upgrade commands on the VPS

```bash
# Check latest compatible version (no changes).
sudo sub2api-maintained-upgrade --check

# Back up the database, verify and install the latest successful build.
sudo sub2api-maintained-upgrade --apply

# Optionally choose a specific release already published by CI.
sudo sub2api-maintained-upgrade --apply sub2api-patched-v0.2.21-<12-char-patch-digest>
```

The command only recreates the **sub2api** service. PostgreSQL, Redis, and the compatibility proxy remain running. It waits for the new container and HTTP health checks. Compose and database backups go under `/root/sub2api/backups/sub2api-maintained/<UTC timestamp>/`.

**Database migration warning:** Restoring the previous image/Compose file after a failed upgrade does not undo migrations already committed by the new release. Incompatible schema migrations may require operator-supervised recovery using the saved database dump. Production upgrades therefore require an explicit `--apply` command and should not run unattended.

## Maintaining the patch after future upstream changes

GitHub Actions will attempt each later release automatically. A successful test and image build produce a new version-specific image. If upstream changes the code surrounding the patch and it no longer applies cleanly, the workflow will fail rather than silently discard the feature. Update `feature.patch` against the new release, ensure the account toggle, thinking redaction, signatures, tool calls and token accounting still work, and re-run the workflow.

The hide-reading-thinking setting controls client-visible content. It **does not** disable the model's reasoning or reduce its reasoning token billing. The account flags remain in PostgreSQL through upgrades.

## GitHub Actions

Workflow: https://github.com/Yi-Lings/open-source-publish/actions/workflows/sub2api-upstream-patch.yml

Temporary releases contain **source-derived images only**; they do not include the VPS `.env`, database, credentials or customer data.

Avoid using `docker compose pull sub2api` to update the locally patched image. Use the documented updater, which chooses and verifies a tested, versioned build.
