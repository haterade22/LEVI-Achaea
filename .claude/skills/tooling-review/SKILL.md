---
name: tooling-review
description: Review last 2 weeks of Claude Code and VS Code updates, cross-reference against project config to find improvements
---

# Tooling Update Review

Review recent Claude Code and VS Code releases, then cross-reference against the LEVI-Achaea project's tooling configuration to surface actionable improvements.

## Step 1: Fetch Claude Code Updates

Gather Claude Code release notes from the last 14 days.

```bash
gh release list --repo anthropics/claude-code --limit 10
```

- For each release tagged within the last 14 days, fetch details via `gh release view <TAG> --repo anthropics/claude-code`
- Fallback: `WebSearch` for "Claude Code changelog" + `WebFetch` on results
- Extract: new features, new hooks, new settings, new tools, deprecations, breaking changes

## Step 2: Fetch VS Code Updates

- `WebFetch` on `https://code.visualstudio.com/updates`
- `gh release list --repo microsoft/vscode --limit 5` for exact dates
- Extract: new editor features, extension APIs, settings, terminal changes, Lua-relevant changes

## Step 3: Snapshot Current Project Config

Read these files to understand current state:

1. `.claude/settings.local.json` — hooks, permissions
2. `.vscode/settings.json` — VS Code editor settings
3. `.vscode/extensions.json` — recommended extensions
4. `CLAUDE.md` — hooks, skills, conventions
5. List `.claude/hooks/` — all hook scripts
6. List `.claude/skills/` — all skill directories

## Step 4: Cross-Reference Analysis

Launch **3 parallel agents** (Sonnet):

### Agent 1 — Claude Code Opportunities
Compare new features against `.claude/` config. Check for: new hook events, settings, deprecations, plugin updates relevant to Lua development.

### Agent 2 — VS Code Opportunities
Compare new features against `.vscode/` config. Check for: Lua extension updates, debugging improvements, terminal changes, sumneko.lua changes.

### Agent 3 — Integration Opportunities
Look for synergies between tools, CLAUDE.md documentation updates needed, workflow improvements.

## Step 5: Report

```
## Claude Code Updates (last 14 days)
- [version]: [key changes]

## VS Code Updates (last 14 days)
- [version]: [key changes]

## Actionable Improvements

### HIGH — Direct workflow improvements
- [What] — [File(s)] — [Why]

### MEDIUM — Worth exploring
- [What] — [File(s)] — [Why]

### LOW — Minor tweaks
- [What] — [File(s)] — [Why]

## Deprecation Warnings
- [Feature] — [Timeline] — [Migration]

## No Action Needed
- [Feature] — [Why not applicable]
```

## Important

- **READ-ONLY** analysis. Do not modify files.
- Focus on **project-specific** recommendations (Lua, Mudlet, combat system).
- Skip features that don't apply (C#, .NET, Python-specific).
