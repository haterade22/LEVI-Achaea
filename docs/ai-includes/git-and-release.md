# Versioning, the release chain and the merge rules: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Versioning & Auto-Update

**Version is tracked in 3 places** (must stay in sync):

| Location | Format | Purpose |
|----------|--------|---------|
| `version.txt` | Plain text (`4.3.2`) | Remote check — fetched by clients on login |
| `muddler_project/mfile` | JSON (`"version": "4.3.2"`) | Build metadata — muddler reads this |
| `_groups.yaml` init script | Lua (`ataxiaVersion = "4.3.2"`) | Runtime global — compared against remote |

**Version bump workflow** (for every release):
1. Use `/version-bump <new_version>` in Claude Code, OR manually update all 3 files
2. Build with `/build` (or `./build.sh`)
3. Commit all changes (version files + any code changes), tag with `v<new_version>`
4. Push the commit straight to `main` (`git push origin HEAD:main`, no pull request; see "Merge finished work straight into `main`" below). When its `Build & Validate` run passes, push the tag: `git push origin v<new_version>` — **push the ONE tag by name; never `git push --tags`** (see below; `.githooks/pre-push` refuses two `v*` tags in one push, a tag that is not `v` + `version.txt` at its commit, a tag whose commit is not on `origin/main`, and a rewrite of `main`)
5. CI/CD automatically builds and creates a GitHub Release with the `.mpackage`

**IMPORTANT**: When asked to rebuild the package, ALWAYS perform the full release flow: version bump → build → commit → tag → push. Do not just build locally — the user expects the new version to reach GitHub so the auto-updater can pick it up.

**NEVER `git push --tags` (2026-08-03, learned the hard way).** It pushes every local tag the
remote lacks, and this clone carries stale ones. Each stale tag fires the `v*` release workflow,
which builds **that tag's old source** and publishes it as a release. GitHub then picks "Latest"
by **publish time, not semver**, so the last stale release to finish becomes
`/releases/latest` — the exact URL `sysupdate` downloads from
(`releases/latest/download/Levi_Ataxia.mpackage`). Pushing `v4.7.208` this way re-pointed Latest
at a two-week-old `v4.7.46` build while `version.txt` on raw `main` still advertised 4.7.208:
`sysupdate` would have installed the old package and only the `onInstalled` version cross-check
would have caught it. **The version CHECK (raw `main`) and the version DOWNLOAD
(`releases/latest`) read different sources and can disagree.** Repair without losing history:
`gh release edit v<version> --latest`, then `gh release delete <stray> --yes --cleanup-tag=false`.

**Several Claude sessions can share this working tree (2026-10-11).** A session that stages with
`git add -A` or `git commit -a` commits whatever another session has in progress: the Serpent
release v4.7.413 shipped half of the Shikudo tracking work that way, unmentioned in its changelog
entry, and switched the tree to `main` under the session whose work it was. **Stage by path; check
`git status` for files that are not yours before committing, branching or bumping the version;
and never switch the shared tree's branch while another session may be working in it.**
`ListAgents` shows the other sessions on this machine.

**Merge finished work straight into `main`; do not open a pull request (the user, 2026-11-11).**
Two pushed branches with no PR sat unmerged for days (`fix/bm-strike-knees`, `docs/audit-after-484`).
`main` has no branch protection, and `build.yml` runs on every push to `main`. So:
1. Work in your own worktree, on your own branch.
2. Run `/c/Python314/python -B tools/ci_local.py` and push only on `Ready to push: YES`. It runs EVERY
   step of the `validate` job in `build.yml`. No PR CI runs before `main` any more, so this is the only
   check before the push. That interpreter has `lupa` and `yaml`; the `python3` on PATH has neither, and
   there the run says NOT RUN and exits 2. `NOT YET` means the steps passed on files that are not
   committed: the push carries only the commit, so commit first (a new file left untracked fails on `main`).
3. `git fetch origin && git rebase origin/main`, then run the checks again if the rebase pulled in changes.
   After a docs rebase, check `file:line` citations into files that `main` changed.
4. `git push origin HEAD:main` from the worktree. This never switches the shared tree's branch.
   If the push is refused because `main` moved, go back to step 3.
5. Watch the `Build & Validate` run for that commit on `main` (select by workflow name; a push also
   starts "Dementia Mapper"). A release tag goes on that commit only after the run passes.
6. Remove the worktree and delete the branch (`git worktree remove`, `git branch -D`, and the remote
   branch if it was pushed). Save a patch of any uncommitted changes first.

**Auto-update system** (`ataxia.updater` namespace, `misc_scripts/021_Auto_Update.lua`):
- On `sysLoadEvent` (5s delay): downloads `version.txt` from GitHub raw, compares against `ataxiaVersion`
- If newer: shows notification, prompts user to type `SYSUPDATE`
- `sysupdate` alias: downloads `.mpackage` → save settings + profile backup → `uninstallPackage` → `installPackage` → cleanup
- **An update removes every edit inside the package (player report, 2026-11-03; backup since v4.7.478).** It does not merge. `ataxia.updater.backupProfile` writes `<profile>/sysupdate_backups/backup_1.xml` first (the last 3 stay, because the next update must not overwrite the only copy of an edit, and never `current/`, because Mudlet loads the newest file there). **Mudlet refuses `uninstallPackage` while a profile save runs, and the save runs on a background thread**, so `swapPackage` starts 1 s later and retries once a second, up to 30 tries, then stops with the old version in place (read in Mudlet's `development` source, not yet seen in a client). `saveProfile`'s first argument is a FOLDER (`saveProfile(folder, name)`, name since Mudlet 4.20; `true, path` or `nil, message`). `reportBackup` runs after the install, because only then is the file complete. A failed backup does not stop the update.
- Uses `sysDownloadDone`/`sysDownloadError` events (same pattern as mudlet-mapper), not `tempTimer`
- **Install triggers a load**: `sysInstallPackage` → `ataxia_updateApplied` → `ataxia_loadSettings()` (when not already loaded), so an install/self-update loads settings immediately — no reconnect required

**Conversion script** (`tools/convert_to_muddler.py`):
- Strips YAML headers from Lua files, outputs pure Lua
- Builds nested JSON hierarchy from `_groups.yaml` files
- Handles name collisions by prepending parent group names
- Preserves group inline scripts
- Converts pattern types, timer formats, key codes
- Rewrites stale file `hierarchy:` headers using per-type dissolved group sets (strips intermediate wrapper names)
- Unwraps root groups in JSON output (emits children directly into array, preventing extra nesting level from Muddler)
- Supports multi-package builds via CLI arguments:
  - `--package-name` — Package identifier (default: `Levi_Ataxia`)
  - `--package-title` — Human-readable title
  - `--package-version` — Version string
  - `--package-author` — Author name
  - `--include-roots` — Root group names to include from `_groups.yaml`
  - `--include-dirs` — Source subdirectory names to scan (default: derived from roots)

**Building a custom package**:
```bash
python tools/convert_to_muddler.py --src ./src_new --output ./my_package_project \
  --package-name My_Package --include-roots My_Package
```

**Comparison tool** (`tools/compare_builds.py`):
- Compares old Python-built XML against Muddler project source
- Verifies item counts, names, hierarchy, and code content
