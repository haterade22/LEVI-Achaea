# Item catalog: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Item Catalog (`itemCatalog`)
Catalogs artefacts, talismans, promo items, and special equipment. Cross-references against a knowledge base to identify what each item does. Auto-probes unknowns and flags them for review.

**Key Files:**
| File | Purpose |
|------|---------|
| `src_new/scripts/.../item_catalog/001_Item_Catalog_Init.lua` | Namespace, config, state machine, echo helpers, skip patterns |
| `src_new/scripts/.../item_catalog/002_Item_Catalog_DB.lua` | Knowledge base (200+ artefacts, all talisman sets) |
| `src_new/scripts/.../item_catalog/003_Item_Catalog_Functions.lua` | Scan orchestration, KB matching, display, search, command dispatch |
| `src_new/scripts/.../item_catalog/004_Item_Catalog_Save_Load.lua` | Persistence (save/load/backup) |
| `src_new/aliases/.../item_catalog/001_Item_Catalog.lua` | `catalog` alias dispatcher |

**Namespace:** `itemCatalog` (global). **Alias:** `catalog`.

**Data Structures:**
- `itemCatalog.kb` — Knowledge base keyed by normalized item name (type, category, power, effect, credits, tier)
- `itemCatalog.talismanKB` — Talisman keyword lookup (set, effect)
- `itemCatalog.items` — Discovered items keyed by ID (name, location, source, kbKey, probeText, userNote, etc.)

**Scan Flow:** ARTEFACT LIST → TALISMAN LIST → Auto-probe unknowns (0.7s delay). Uses `tempRegexTrigger` with timer-based end-of-output detection and MORE pagination handling.

**Commands:**
| Command | Purpose |
|---------|---------|
| `catalog scan` | Full scan (ARTEFACT LIST + TALISMAN LIST + auto-probe) |
| `catalog quick` | Quick scan (no probing) |
| `catalog show [artefacts\|talismans\|promo\|unknown]` | Display by type/category |
| `catalog search <keyword>` | Search name, power, effect, set, category |
| `catalog info <id>` | Full item details |
| `catalog note <id> <text>` | Add manual annotation |
| `catalog unknowns` | List unidentified items |
| `catalog save` / `catalog load` | Manual save/load |
| `catalog help` | Command reference |

**Persistence:** `table.save/load` to `getMudletHomeDir()/itemcatalog` with `_ataxia_backup.itemcatalog` fallback. Integrated into `ataxia_saveSettings()`/`ataxia_loadSettings()`.
