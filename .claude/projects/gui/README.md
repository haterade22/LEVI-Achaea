# GUI system (ataxiagui): the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### GUI System (ataxiagui)

~20 windows using `Adjustable.Container`. Tabbed chat, map, bash stats, afflictions, vital bars, SLC, and more.

**Full documentation**: See `memory/gui-windows.md` (Adjustable.Container patterns, namespace migration status, vital bars, ANSI color handling)

**Chat colours are the GAME'S CONFIG COLOUR (v4.7.375).** `zgui.showChat` (`update_windows/001_showChat.lua`) keeps the ANSI in `Comm.Channel.Text.text` (`ataxiagui_chatAnsiToDecho`), so the chat matches the main window. Clans take CONFIG COLOUR CLANS. Never repaint from a package palette. The channel comes from **`Text.channel`** (`ataxiagui_chatChannel`), never from the deprecated `Comm.Channel.Start`: Start arrives AFTER Text, so on the Text event it names the PREVIOUS message's channel. v4.7.100 read it first, and every line was coloured and routed as the one before it.
