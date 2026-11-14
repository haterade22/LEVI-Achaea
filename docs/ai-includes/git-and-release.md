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
3. Commit this session's files, staged by path (version files + your code changes). Do not tag yet
4. Push the commit straight to `main` (`git push origin HEAD:main`, no pull request; see "Merge finished work straight into `main`" below). When its `Build & Validate` run passes, tag that commit and push the tag: `git push origin v<new_version>` — **push the ONE tag by name; never `git push --tags`** (see below; `.githooks/pre-push` refuses two `v*` tags in one push, a tag that is not `v` + `version.txt` at its commit, a tag whose commit is not on `origin/main`, and a rewrite of `main`)
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

---

## The release steps and their incidents

The steps are in `CLAUDE.md` ("Build, Test and Release"). This table is the reason for each one. It was assembled on
2026-11-13 from the text above and from the maintainer's release notes, which until then were outside git.

| Step | Rule | What happened | Enforced by |
|---|---|---|---|
| 1 | Own worktree and branch; stage by path; never switch a shared tree's branch | 2026-10-01, v4.7.371: a second session changed branch between another session's `checkout -b` and `commit`, so the commit landed on the wrong branch and both had picked the same version. 2026-10-11, v4.7.413: `git add -A` shipped half of another session's work | Nothing. Rule only |
| 2 | Check the top tag on origin before the bump, before the push and before the tag | 2026-10-23: v4.7.448 was tagged on an unmerged branch, and v4.7.449 from `main` would have dropped its fix. 2026-11-03: two numbers were taken by another session during one fix. 2026-11-13: a commit that waited for approval lost v4.7.493; a tag with the lower number would have become "Latest" | `tools/ci_local.py` prints a warning (a higher tag on origin, or the same number on a commit this tree does not have). `.githooks/pre-push` refuses a tag whose commit is not on `origin/main` |
| 3 | Run every `validate` step before the push | 2026-11-09, PR #169: `kb_rules.py --check` failed in CI after a partial local run (a Lua file is an input of a generated page). 2026-11-13: `kb_sim.py --check` printed "skip" and exited 0 under the `python3` on PATH | `tools/ci_local.py`: one list, NOT RUN is never a pass, `Ready to push: YES` only for a full clean run on a committed tree |
| 4 | Rebase on `origin/main`, then check again | 2026-11-13: after a rebase, lines that other documents cite had moved | Nothing. Rule only |
| 5 | Push straight to `main`; no pull request | 2026-11-11 (the maintainer): two pushed branches with no pull request sat unmerged for days | Nothing; `main` has no branch protection. `.githooks/pre-push` refuses a rewrite of `main` |
| 6 | Wait for the `Build & Validate` run of that commit, selected by workflow name | 2026-11-03, v4.7.477: tagged when the checks had not started; a test that made a folder passed on Windows and failed on Linux, so `version.txt` on `main` announced a version that had no release. 2026-11-09, v4.7.484: a watcher followed "Dementia Mapper", the other workflow a push starts, and reported success | `tools/release.py tag-ready <version>` prints the tag command only when that run passed for that commit |
| 6 | A tag run with no jobs is an outage: run it again, do not tag again | 2026-11-09, v4.7.481: the tag run failed with `jobs: []` during a GitHub Actions outage | Nothing. Check the jobs list and githubstatus.com, then `gh run rerun <id>` |
| 7 | Tag the commit that holds the version; push ONE tag by name; never `git push --tags` | 2026-08-03, v4.7.208: `--tags` pushed stale tags, each built an old release, and "Latest" pointed at a two-week-old build. 2026-09-16, v4.7.313: the tag went on the commit before the bump, so the "v4.7.313" package said 4.7.312 | `.githooks/pre-push` refuses two `v*` tags in one push and a tag that is not `v` + `version.txt`. The release build fails when the tag is not `v` + `version.txt` |
| 7 | One `&&` chain, with the commit message in a file | 2026-09-16, v4.7.313: the tag command stood on the line after a heredoc, so it ran although the chain before it had failed | Nothing. Rule only |
| 8 | Refresh `muddler_project/build/` in the main checkout: the mpackage AND the unzipped `Levi_Ataxia.xml` | A release made from a worktree leaves that folder at the old version, and the maintainer imports from it. Skipped for three releases by 2026-11-12; the xml alone was left old for v4.7.499 and v4.7.500 | `tools/release.py post` compares both files with the release and prints the commands |
| 8 | Remove the merged worktree and branch | 2026-11-11: nine old worktrees made the Lua language server index about 15,000 files | Nothing. Rule only |

Repair of a wrong "Latest": `gh release edit v<version> --latest`, then `gh release delete <stray> --yes --cleanup-tag=false` (see "NEVER `git push --tags`" above).

