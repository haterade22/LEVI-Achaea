# Reporting: HTTP Client & Reporter API

Two files: `001_HTTP_Client.lua` (transport — a serial POST queue) and `002_Reporter_API.lua` (one thin function per endpoint + run state). The tracker takes **no auth header**; every request is a POST whose JSON body carries a `token` field, stamped on automatically by the client.

## Configuration

`M._cfg()` returns (and lazily creates) `ataxia.settings.reporting`:

| Key | Default | Purpose |
|-----|---------|---------|
| `enabled` | false | Master auto-report toggle (`mnem on/off`) |
| `contemplate` | true | Stored boon-enrichment toggle (`BOON CONTEMPLATE`). **No longer gates `/boons_offered`** — offers post immediately now (see Notable behaviours); the enrichment chain (`_contemplateNext`) is retained but off the offer path |
| `url` | `M.DEFAULT_URL` | Tracker base URL |
| `token` | nil | API token (`mnem token <t>`) |
| `debug` | nil | Verbose `M.decho` echoes |
| `mapEnabled` | true | Ripple mini-map toggle (see [04](04-ripple-map.md)) |

- `M.DEFAULT_URL = "http://104.128.56.238:8000"`
- `M._baseUrl()` falls back to the default if `url` is empty and trims trailing slashes.
- `M._hasToken()` — token is a non-empty string.

## Serial POST Queue (`001_HTTP_Client.lua`)

Requests are sent **one at a time** — the next only fires after `sysPostHttpDone`/`sysPostHttpError` for the previous — so endpoint ordering is guaranteed (`/ripple_level` before its monsters/boss/effects; `/boons_offered` before `/boons_selected`).

```
M._enqueue(endpoint, payload, onOk, onError)
  ├─ stamp payload.token
  ├─ table.insert(M._queue, {endpoint, payload, onOk, onError, tries=0})
  └─ M._pump()

M._pump()                    (no-op if M._busy or queue empty)
  ├─ yajl.to_string(payload)  (drop request on encode failure)
  ├─ M._busy = true
  ├─ arm watchdog: tempTimer(REQUEST_TIMEOUT=20s, → M._onTimeout)
  └─ postHTTP(json, baseUrl..endpoint, {Content-Type: application/json})

sysPostHttpDone  → M._onDone(_, url, body)
  ├─ ignore unless M._busy AND _matchesHead(url)
  ├─ parse JSON body (yajl.to_value, pcall-guarded)
  ├─ req.onOk(parsed, body)   (pcall-guarded)
  └─ M._finish()  → drop head, M._busy=false, _pump() next

sysPostHttpError → M._onError(_, err, url)
  ├─ ignore unless M._busy AND _matchesHead(url)
  ├─ retry ONCE if req.tries<1 and endpoint in M._IDEMPOTENT
  └─ else echo failure, M._fireError(req, err), M._finish()

M._onTimeout()               (watchdog fired: dropped response / POST→GET)
  └─ M._fireError(req, "timeout"), M._finish()   (same recovery as an error)
```

**Error recovery.** `M._fireError(req, err)` invokes the request's `onError(err)` callback (pcall-guarded), reached from BOTH the error event and the watchdog — so a failed request can undo optimistic local state. `startRun()` uses this: it sets `run.active = true` optimistically before `/run_start`, and its `onError` resets `run.active = false`, so a `/run_start` that 500s **or** times out doesn't leave the client firing `ripple`/`monsters`/`boss`/`effects`/`boons` at a run the server never created (recovery would otherwise wait for the next `/run_end` or reload's `runExists`).

### Safety features

| Feature | Function | Why |
|---------|----------|-----|
| Endpoint matching | `M._matchesHead(url)` | A done/error event is accepted only if its URL equals the exact endpoint of the queue head — stray/duplicate events or ad-hoc `postHTTP` to the same host can't be misattributed |
| Watchdog | `M._watchdog` timer, `REQUEST_TIMEOUT = 20` | Force-advances a stuck request (e.g. a POST silently redirected to GET, or a dropped response) so the queue never stalls permanently |
| Idempotent-only retry | `M._IDEMPOTENT = { ["/ripple_level"]=true, ["/run_exists"]=true }` | Only endpoints safe to repeat are auto-retried; everything else is left alone to avoid double-posting a run/death/etc. |
| Handler survival | `registerAnonymousEventHandler` for all 4 http events | Handlers survive `uninstallPackage` (same reasoning as `ataxia.updater`); prior handlers are `killAnonymousEventHandler`'d on reload |

### Health check (`mnem test`)

`M.testHealth()` does a plain `getHTTP(baseUrl.."/health", {})`. Separate `sysGetHttpDone`/`sysGetHttpError` handlers (`_onGetDone`/`_onGetError`) match on the `/health` URL and echo the result. GET is used here, not the POST queue.

## Reporter API (`002_Reporter_API.lua`)

Each function guards on `M._hasToken()` and enqueues. Payload shapes:

| Function | Endpoint | Payload (plus auto `token`) | Response used |
|----------|----------|------------------------------|---------------|
| `startRun()` | `POST /run_start` | `{}` | `public_id` → `run.publicId` |
| `runExists()` | `POST /run_exists` | `{}` | `exists`, `ripple` → sync run state |
| `endRun()` | `POST /run_end` | `{}` | — (echo only) |
| `setRipple(n)` | `POST /ripple_level` | `{ ripple = n }` | — (sets `run.ripple` on OK) |
| `reportMonsters(str)` | `POST /monsters` | `{ monsters = str }` | — |
| `reportBoss(name)` | `POST /boss` | `{ boss = name }` | — |
| `reportEffects(list)` | `POST /effects` | `{ effects = [{name, description}, …] }` | — |
| `reportBoonsOffered(list)` | `POST /boons_offered` | `{ offered = [{name, description, quote?, rarity?, num_echoes_possible?}, …] }` | — |
| `reportBoonsSelected(names)` | `POST /boons_selected` | `{ selected = [name, …] }` | — |
| `reportDeath(killer)` | `POST /death` | `{ killer = <name or "unknown"> }` | — |

### Notable behaviours

- **`setRipple(n)` guard.** Skips locally if `n <= run.ripple` (the API errors on a lower ripple and no-ops on equal). `run.ripple` is only advanced inside the success callback.
- **`startRun()` optimism.** Sets `run.active = true` and calls `_resetRun()` *synchronously* before the async POST, so the first wave isn't lost while waiting for the response.
- **Pause / resume (no new `public_id`).** A "beseech that it grow still" pause sets `run.paused` (`onRunPause`, `004_Parsers.lua`) **without** ending the run server-side. The next wade's `onRunStart` then resumes via **`runExists()`** (`/run_exists`) instead of `startRun()`, so no fresh `/run_start` fires and **no new `public_id` is minted** — the resumed run keeps its server-side identity, and `/run_exists` re-syncs `run.active` + `run.ripple`. `run.paused` is cleared unconditionally in `_resetRun()` (hence on any genuine `startRun`/`endRun`) and in `onRunEnd`, so a telemetry-off end can't hijack the next fresh wade into a resume.
- **`endRun()`** flushes any final-wave monsters (`_flushMonsters()`) before enqueuing `/run_end`, then resets locally immediately (the run is over regardless of the response).
- **`reportBoonsOffered` is posted immediately.** `_reportBoonsOfferedEnriched(list)` (`004_Parsers.lua`) records local history and calls `reportBoonsOffered(list)` **right away**, with the `name`+`description` scraped straight off the offer screen — it is **not** gated behind the per-boon `BOON CONTEMPLATE` enrichment chain. (The old design contemplated each boon (~0.5s apiece) to fill `rarity`/`quote`/`num_echoes_possible` *before* posting; that chain competed with the next ripple's captures for the single `_capturing` slot and, on a lost race, stalled and silently dropped the whole `/boons_offered`, and even on success could post after the player had already waded onto the next ripple.) Name+description is all the tracker needs; the optional enrichment fields are learned locally instead (BOONS list via trigger 013 + `mnem boonfill`), which is why the `/boons_offered` payload lists them as optional (`?`).
- **`reportBoonsSelected`** accepts a string or array; a bare string is wrapped to `{ str }`.
- **`reportDeath`** defaults `killer` to `"unknown"` when empty.

### Monster buffering

`M.run.pendingMonsters` accumulates spawn lines (de-duped) captured at `GO!`. `M._flushMonsters()` joins them with `"; "` into a single `reportMonsters()` call and clears the buffer. It runs in `onRipple()` (after `setRipple`) and again in `endRun()`.
