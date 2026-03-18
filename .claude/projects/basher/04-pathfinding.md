# Pathfinding & Area Bash

## Path Generation

Function: `ataxiaBasher_generatePath()` in `genrunning/001_Bashing_API.lua`

### Algorithm

1. Check for stored path: `ataxiaBasherPaths[currentArea]`
2. If current room is in the stored path, start from that position onwards
3. If not in path, use full stored path as-is
4. If no stored path exists, query mapper: `getAreaRooms(getRoomArea(mmp.currentroom))`
5. Sort all rooms and set as `ataxiaBasher_path`
6. Navigate to first room: `expandAlias("goto " .. ataxiaBasher_path[1])`
7. Start stuck timer

### Path Storage

Paths saved in `ataxiaBasherPaths[areaName]` table, persisted to `getMudletHomeDir()/basherpaths`.

Custom paths recorded via `saveRoomPath()` which copies from `mapping_path[]`.

## Room Progression

Function: `ataxiaBasher_nextRoom()` in `genrunning/004_Autobashing_Functions.lua`

1. Call `ataxiaBasher_roomBashed()` — removes current room from `ataxiaBasher_path`
2. If manual mode, return (player moves)
3. If path has rooms remaining, navigate to next: `expandAlias("goto " .. path[1])`
4. If path empty, call `ataxiaBasher_areaoff()` — area complete
5. Start stuck timer

## Room Removal

Rooms are removed from `ataxiaBasher_path` in two places:
- **On arrival**: `002_ataxia_Room_Update.lua` lines 62-67 removes current room from path
- **On progression**: `ataxiaBasher_roomBashed()` removes first room from path

## Stuck Detection

Function: `ataxiaBasher_startStuckTimer()` in `genrunning/001_Bashing_API.lua`

- Records `mmp.speedWalkCounter` at start
- After `stuckTimeout` (default 15s), checks if counter advanced
- If unchanged: call `ataxiaBasher_pathFail()`

## Path Failure

Function: `ataxiaBasher_pathFail()` in `genrunning/001_Bashing_API.lua`

- Remove first room from path (blocked/unreachable)
- If path has rooms, retry with next room
- If path exhausted, call `ataxiaBasher_areaoff()` unless manual mode

## Mapper Integration

| Function | Purpose |
|----------|---------|
| `mmp.pause("on"/"off")` | Pause/resume mapper movement |
| `mmp.speedWalkCounter` | Movement progress counter (stuck detection) |
| `mmp.previousroom` | Last room before current (flee fallback) |
| `mmp.currentroom` | Current room number |
| `expandAlias("goto " .. roomNum)` | Navigate via mapper |
| `getAreaRooms(areaId)` | Get all rooms in area (fallback path) |

## Event Handlers

| Event | Handler | Purpose |
|-------|---------|---------|
| `"mmapper failed path"` | `ataxiaBasher_pathFail()` | Remove blocked room, retry |
| `"mmapper arrived"` | `ataxiaBasher_arrived()` | Mark room as bashed in areabash |
