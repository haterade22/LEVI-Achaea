# Ripple Map

Every Mnemosyne ripple ("level") is a fresh room layout, so the map builds a per-ripple room graph as you walk and wipes it whenever the ripple changes. Mnemosyne is an **unmapped instance** (`gmcp.Room.Info.area == ""`) so Mudlet's own mapper draws nothing — but `num`/`name`/`exits` still arrive over gmcp, so we plot rooms on a self-managed grid. Two files: `005_Ripple_Map.lua` is the pure graph + runtime hooks; `006_Ripple_Map_Window.lua` is the draggable grid widget. Everything hangs off `ataxia.mnemosyne.map` (aliased `local MAP`).

## Data model

Each room is a record keyed by its gmcp room `num`:

| Field | Type | Meaning |
|-------|------|---------|
| `num` | number | Room id (coerced to number — see below) |
| `name` | string | Room name from gmcp |
| `x`, `y` | number/nil | Grid coordinate (`+y` = north); `nil` until placed |
| `exits` | table | `dir -> dest` for **every** exit the game REPORTS |
| `edges` | table | `dir -> nbNum` for exits we've actually WALKED |
| `visited` | bool | `true` on a real arrival; `false` on a propagation stub |

The `exits`/`edges` split is the core of the model. **`exits`** is everything gmcp advertises for the room (used to detect unexplored exits and to place neighbours); **`edges`** is only the connections we've traversed (used for pathfinding, so BFS never routes through a door we haven't confirmed by walking it). A **`visited` room** is one we've physically arrived in via `onRoom`; an **unvisited stub** is a neighbour created coords-only by topology propagation — it exists on the grid but isn't drawn until we walk into it.

Direction handling is table-driven:

| Table | Maps | Use |
|-------|------|-----|
| `MAP.OFFSETS` | `dir -> {dx, dy}` | Planar placement (`north {0,1}`, `southeast {1,-1}`, …). `up`/`down`/`in`/`out` are non-planar: absent here, so they're tracked only as edges and never get a grid coord |
| `MAP.OPPOSITE` | `dir -> reverse dir` | Records the reverse walked edge; includes `up/down`, `in/out` |
| `DIRNORM` (`MAP.normDir`) | short/long/any-case -> canonical long form | e.g. `n`/`NORTH` -> `north`; returns `nil` for non-directions |
| `DIRSHORT` (`MAP.shortDir`) | long form -> short form | `north` -> `n`, `southwest` -> `sw`; used when queueing movement commands |

## onRoom flow

`MAP.onRoom(num, name, exits, moveDir)` records an arrival. Order of operations:

```
onRoom(num, name, exits, moveDir):
  num = tonumber(num) or num                 -- normalise the id
  from = rooms[current]                       -- room we came from (if any)
  create rooms[num] if absent, push onto order[]
  room.visited = true                         -- a real arrival, not a stub
  if name: room.name = name

  -- 1. Record REPORTED exits (rebuilt fresh each visit)
  room.exits = {}
  for d, dest in gmcp exits:
    nd = normDir(d)
    if nd: room.exits[nd] = tonumber(dest) or dest   -- coerce string dest -> number

  -- 2. Resolve which direction we moved to get here
  dir = normDir(moveDir)                              -- (a) explicit move dir
  if not dir and from: for d,dest in from.exits: if dest==num then dir=d   -- (b) exits-dest match
  if not dir and from and _lastMoveDir: dir = normDir(_lastMoveDir)        -- (c) fallback

  -- 3. Assign coordinates
  if origin == nil: origin = num; room.x, room.y = 0, 0     -- first room anchors at (0,0)
  elseif room.x == nil and from placed and dir known:
    room.x, room.y = from.x + OFFSETS[dir][1], from.y + OFFSETS[dir][2]
  -- else: keep whatever coord propagation already assigned

  -- 4. Record the walked edge BOTH ways
  if from and dir: from.edges[dir] = num; room.edges[OPPOSITE[dir]] = from.num

  -- 5. Fill in neighbours from the exit graph
  _propagate(room)

  current = num; _lastMoveDir = nil
```

### Notable behaviours

- **String-dest coercion (step 1).** gmcp reports exit destinations as **strings** (`exits = { north = "67701" }`). They are run through `tonumber` so they compare against numeric room `num`s. Without this, `"67701" == 67700` is always false and neither the exits-dest fallback (step 2b) nor propagation (step 5) ever matches anything.
- **Direction resolution is a three-tier fallback (step 2).** Prefer the explicit `moveDir`; else find the exit in the previous room whose dest equals this room's num; else fall back to the last movement direction captured from `sysDataSendRequest`. Only a resolved direction with an entry in `OFFSETS` yields movement-based coordinates.
- **Coordinates are sticky (step 3).** If a room already has an `x` (assigned by propagation before we walked in), `onRoom` keeps it rather than recomputing — so a stub's position doesn't jump when it's finally visited.
- **Edges are bidirectional (step 4).** Walking `north` from A to B records `A.edges.north = B` and `B.edges.south = A`, so BFS can route the return trip.

## Topology propagation — `MAP._propagate`

This is the load-bearing mechanism (added v4.7.44). Because the game hands us each room's full exit graph as `dir -> neighbour num`, once a room is placed we can position all of its neighbours **directly from the exit graph**, without ever having captured which way we moved:

```
_propagate(room):
  if room unplaced (room.x == nil): return
  for d, dest in room.exits:
    off = OFFSETS[d]
    if off and dest is a positive number and dest ~= room.num:
      nb = rooms[dest] or new stub { exits={}, edges={}, visited=false }
      if nb.x == nil:
        nb.x, nb.y = room.x + off[1], room.y + off[2]
```

Neighbours are created as **unvisited stubs** — coordinates only, no name or exits — and only start rendering (and gain their own exits) once they're actually visited via `onRoom`. This is what makes the grid fill in reliably even when the captured movement direction is unknown or wrong.

### The bug it fixed

Before propagation coerced dest ids, exit destinations (strings) were compared against numeric room nums, so `"67701" == 67700` was always false. No room past the origin ever received coordinates: only the origin got `(0,0)`, every other room stayed `x == nil`, and `mnem map status` reported `bounds=0,0,0,0` with a blank grid. Coercing dests to numbers (in both `onRoom` step 1 and the `type(dest) == "number"` guard here) is what lets propagation place real neighbours.

## Derived queries

| Function | Returns | Notes |
|----------|---------|-------|
| `MAP.unexploredExits(num)` | list of dirs REPORTED but not in `edges` | The exits we know about but haven't walked |
| `MAP.hasUnexplored(num)` | bool | `#unexploredExits > 0`; drives the gold "?" cell style |
| `MAP.path(fromNum, toNum)` | list of SHORT-dir steps, or `nil` | **BFS over WALKED `edges` only**; `{}` if already there, `nil` if unreachable |
| `MAP.bounds()` | `minx, maxx, miny, maxy` | **VISITED rooms only**, so unplaced/stub coords don't stretch the grid |

`MAP.path` walks the `edges` graph (never `exits`), reconstructs the route via a `from_of` predecessor map, and emits each hop through `shortDir` so the result is directly sendable (e.g. `{"w","s"}`). Restricting `bounds` to `r.visited` keeps the drawn window tight even though stubs carry coordinates.

## Reset & re-seed

The map's lifecycle is driven by two events, both independent of telemetry reporting:

| Event | Handler | Effect |
|-------|---------|--------|
| Ripple number changes | `MAP.onRipple(n)` | `MAP.reset()` (wipe graph), set `_ripple = n`, **re-seed** the current room from gmcp, `render()` |
| Fresh Mnemosyne entry | `gmcp.Room` handler | `MAP.reset()` + clear `_ripple` on the `inMnem()` rising edge (`_wasInMnem` tracks it) |

```
onRipple(n):
  if n ~= nil and n ~= _ripple:
    reset()
    _ripple = n
    if inMnem() and gmcp.Room.Info:            -- RE-SEED
      onRoom(Info.num, Info.name, Info.exits, nil)
    render()
```

`MAP.reset()` clears `rooms`, `order`, `current`, `origin`, and `_lastMoveDir`. The **re-seed is essential**: the "You wade N ripples deep…" line fires while you are *already standing* in the new level's first room, so a bare reset would leave the map blank until you took a step. Re-seeding from `gmcp.Room.Info` immediately plots (and propagates) the arrival room.

### Notable behaviours

- **`MAP.inMnem()` gate.** True when `ataxiaBasher.inMnemosyne` is set **OR** a telemetry run is active (`ataxia.mnemosyne.run.active`). The survey flag is set opportunistically and can be missed between floors, so either signal counts — the map works with reporting fully off.
- **Movement capture (`sysDataSendRequest`).** While `inMnem()`, the outgoing command's trailing word is matched (`(%a+)%s*$`), normalised, and stored in `MAP._lastMoveDir` — the movement aliases send `".. <dir>"`, so this recovers the direction the exits-dest fallback and step-2c use. It's self-correcting: the last movement command before the room change wins.
- **Room hook (`gmcp.Room`).** On every room change it resets on a fresh Mnemosyne entry, calls `autoShow()`, then (if `inMnem()`) `onRoom(Info.num, Info.name, Info.exits, _lastMoveDir)` + `render()`.
- **WADE STATUS drives the reset.** `M.onGo()` (trigger 006) fires for telemetry OR just for the map — it's gated `M._auto() or ataxiaBasher.inMnemosyne` and always issues `send("wade status", false)`. That pulls the ripple line even with reporting off, so `M.onRipple(n)` (which calls `map.onRipple(n)` *before* its own `_auto()` gate) still drives the per-ripple wipe. See [01-architecture.md](01-architecture.md) for the full run/GO! lifecycle.

## Widget — `006_Ripple_Map_Window.lua`

A draggable grid mini-map. `MAP.build()` wraps an `Adjustable.Container` named `ataxia.mnemosyne.map.window` (position auto-persists by that name) holding a `Geyser.Container`; `MAP._cell(id)` lazily creates the per-cell `Geyser.Label`s. Build is wrapped in `pcall` and retried on `sysLoadEvent` in case `main` wasn't ready.

`MAP.render()` draws a **fixed `LEVEL = 4` × 4 grid** — every Mnemosyne ripple is a 4×4 room layout, so the whole frame is shown rather than auto-sizing to visited rooms. `+y` (north) is at the top. The frame extent is the bounds of the visited rooms **plus the "frontier"** (grid positions of unvisited rooms that a visited room's unwalked exit points at — `r.x/r.y + OFFSETS[unexploredExit]`), so it aligns toward where real rooms are; `fit()` then pads each axis up to 4, or windows on the current room if the graph ever spans wider than 4 (loop/inconsistency).

Every one of the (usually 16) cells is drawn. A **visited** room's cell uses a priority style branch (`r.num == MAP.current` → `elseif hasUnexplored` → else), so the current room is always green even when it has unwalked exits:

| Cell | Style |
|------|-------|
| Current room (`r.num == MAP.current`) | green (`STYLE.current`) |
| Visited room with unexplored exits (`hasUnexplored`) | gold-bordered (`STYLE.unexplored`) |
| Other visited room | grey (`STYLE.room`) |
| **Unvisited grid position** | dim (`STYLE.placeholder`) |

The `"?"` marker is set **separately** — `lbl:echo(MAP.hasUnexplored(r.num) and "?" or "")` runs unconditionally for visited cells, independent of the style branch. So any room with a reported-but-unwalked exit shows `?`, **including the green current room** (the common case — you've just arrived and haven't walked its other exits yet); a fully-explored room shows nothing.

A visited cell's tooltip is the room name, and its `setClickCallback(function() MAP.walkTo(r.num) end)` uses a **direct function** (not a name-string callback) so it always resolves. Placeholder cells are inert — a no-op click callback and an `"unexplored"` tooltip.

### Click-to-walk

`MAP.walkTo(num)` computes `MAP.path(current, num)`. On `nil` it echoes `No known path to that room` (you haven't walked a route there yet); on a non-empty path it queues the moves through the game's **free queue** — `send("queue addclear free <first>")` then `send("queue add free <step>")` for the rest — the same mechanism the movement aliases use, so moves execute one per balance in order.

### Show / hide & diagnostics

| Function | Purpose |
|----------|---------|
| `MAP.autoShow()` | Shows the window when `_enabled()` and `inMnem()`, else hides it. Called from the room hook and on load. Note: 006's local `inMnem()` checks **only** `ataxiaBasher.inMnemosyne`, stricter than `MAP.inMnem()` |
| `MAP.toggle(state)` | Flips `ataxia.settings.reporting.mapEnabled` (`mnem map on\|off`), saves settings, re-runs `autoShow()` |
| `MAP._enabled()` | Reads `mapEnabled` from `_cfg()`, defaulting to `true` |
| `MAP.status()` | `mnem map status` diagnostic — echoes `inMnem`/`enabled`/`rooms`/`visited`/`placed`/`current`/`lastMove`/`ripple`/`bounds`, **and** dumps the raw `gmcp.Room.Info.exits` (`dir->dest`) so you can tell at a glance whether the game hands real neighbour room-nums (usable for propagation) or unmapped placeholders |

## Testing

The widget (006) needs `Geyser`/`main` and Adjustable containers, so it isn't unit-tested. The pure graph in 005 is covered in [`test_mnemosyne.lua`](../../../src_new/tests/test_mnemosyne.lua) under the `describe("ripple map graph")` block. Locked-in behaviours:

| Test | Locks in |
|------|----------|
| assigns grid coordinates by direction of travel | movement-based placement from a known `moveDir` |
| infers direction from the previous room's exits when moveDir is nil | the exits-dest fallback (step 2b) |
| positions neighbours from the exit graph before they're visited | `_propagate` creates placed unvisited stubs; the stub keeps its coord on arrival |
| coerces string exit dest ids so exits-dest inference still matches | the `tonumber` dest coercion (the propagation bug fix) |
| marks exits reported but not walked as unexplored | `unexploredExits` / `hasUnexplored` (exits minus edges) |
| pathfinds back through walked edges as short directions | BFS over `edges` returning `{"w","s"}` |
| returns nil for an unreachable room | islanded room with no edges -> `nil` path |
| resets the graph only when the ripple number changes | `onRipple` keeps on same `n`, wipes on new `n` |
| re-seeds the current room from gmcp after a ripple reset | reset + `onRoom` from `gmcp.Room.Info` (current becomes the new room) |
| normalises and shortens directions | `normDir` / `shortDir` |

All Mudlet I/O is mocked; the graph is exercised by calling `MAP.onRoom` / `MAP.onRipple` / `MAP.path` directly.

---

See also: [01-architecture.md](01-architecture.md) (run lifecycle, gating, event flow), [02-reporting.md](02-reporting.md) (HTTP queue + Reporter API), [03-parsing-triggers.md](03-parsing-triggers.md) (trigger→handler wiring).
