# Campus time attack backend

Isolated Firebase codebase `campus-game`, Node 22. No service has been deployed by this implementation.

Authenticated v2 callable `campusGame` in `us-central1`, Firebase callable request `{data:{action,...}}`. Responses use `serverNow` milliseconds; Firebase errors use standard callable codes. Public data never includes UID, email, real name or student ID. The game nickname is the canonical My Page `users/{authenticated UID}.displayName`; the game has no separate alias editor or caller-selected profile reference.

Actions: `profile {consent}`; `courses {}`; `best {direction}`; `standings {courseKey}`; `challenge {direction}`; `cancelChallenge {challengeId}`; `trace {challengeId,samples:[{t,x,z,y}],finish?:true}`; `recover {challengeId}`; `createRoom {direction}`; `joinRoom {code}`; `room {roomId}`; `readyRoom {roomId,ready}`; `startRoom {roomId}`; `leaveRoom {roomId}`. Game course IDs are `outward`, `return`, `s_bay`, and `neon_city`.

Courses return `{courses:[{direction,key,courseKey,length}],serverNow}`. Challenges return `{challengeId,courseKey,startAt,serverNow}`. Start is scheduled 3 seconds ahead. Room responses include `{roomId,code,courseKey,direction,status,startAt,serverNow,players}`. Each player exposes `{playerId,nickname,progress,status,ready,host,self,position:{x,z}|null,yaw,elapsedMs}`; only the requesting player sees its `challengeId`. Membership, rather than knowledge of the code, grants room access. No rooms list exists. All players must be ready; host starts 2–4 players; late joins are blocked. Poll at 2 seconds. A network disconnect preserves membership and rejoin using code or room ID works before expiry. Explicit leaving during a race forfeits that race. A leaving host transfers host role; empty rooms close.

Trace sample `t` is milliseconds since server `startAt`, strictly increasing, with intervals at most 5000ms. Send samples each second and upload approximately once a second (minimum 250ms between uploads, at most 32 samples per request and 16KB request). Samples may not be more than 100ms ahead or 35 seconds old. For the current pop family validate a 48m road/shoulder/off-road belt, maximum speed 22m/s plus 2m position tolerance per sample, forward route-distance speed, maximum backward progress 12m and ordered 150m checkpoint progression. Course polyline local X/Z metres and its frozen fingerprint are authoritative. Completion requires position and progress within 15m of the finish and final sample at most 2 seconds old. Elapsed time is calculated from server receipt time minus server start plus accumulated server recovery penalties; client score and penalty fields are ignored. This bounds implausible traces but cannot prove honest execution on a fully modified client; it is not cryptographic proof or GPS verification.

`standings` returns at most 50 sorted `{playerId,nickname,elapsedMs}` records. Consent defaults false, and must be explicitly boolean. Revocation removes current public records transactionally; private best remains. Consent does not republish an earlier private score. Public best updates compare the current verified run independently of private best. After renewed consent a new slower verified run can publish while an older faster private best remains private. Canonical My Page name changes refresh published records and every member name on server reads, including while the owner is offline. All client Firestore reads and writes for both game roots are denied; use the authenticated callable.

Rate limits are persisted in a separate transaction, including rejected attempts: create/join combined 8 attempts/minute per user, traces 240/minute, other actions 120/minute. Twelve-hex-character room codes contain 48 random bits; room/challenge IDs contain 128 random bits. Quotas are per account; coordinated multiple-account abuse is outside these bounds. Do not enable automatic client retries for failed join attempts.

Retention: rooms, challenge documents, and code lookups expire after 20 minutes; quota records after 24 hours. `campusGameCleanup` runs hourly and deletes up to 5000 expired documents using the collection-group `items` field `campusGameExpiresAt`. That collection-group query needs an ascending single-field collection-group index on `campusGameExpiresAt` (see `firestore.indexes.game.json`). Expiry is enforced by every game operation immediately even before deletion. Private profile/best and consensual boards persist until consent withdrawal or account data deletion; full account erasure must delete both game roots for that identity.

Freeze updated courses with `npm run freeze --prefix game-functions`; this imports the independent `assets/models/campus/pop_courses.json` game asset, requires all four finite 3D course point arrays, rounds every coordinate to integer centimetres for FNV1a course keys, verifies frontend fingerprints, and calculates horizontal X/Z polyline lengths. Tests intentionally use tiny frozen courses and a fake clock. Course changes invalidate old challenges/rooms.

Verification (PowerShell at repository root):

```
node --test game-functions/test/core.test.cjs
$env:NODE_PATH = (Join-Path (Get-Location) 'security-functions/node_modules')
node -e "require('./game-functions/index.cjs')"
node_modules/.bin/firebase.cmd emulators:exec --only firestore --project demo-campus-game --config firebase.game-test.json "node --test game-functions/test/*emulator.cjs"
```

Install codebase dependencies separately with `npm ci --prefix game-functions` before deployment. During local verification existing installed sibling dependencies were used; lockfile resolution was offline. The emulator config is standalone and never targets real data. The emulator appends local debug logs at repository root.

Main configuration additions (owner integrates): firebase.json functions entry `{"source":"game-functions","codebase":"campus-game"}`. Merge the two deny rules in `firestore.game.rules` into existing rules; a broader existing allow rule would override a deny, so review overlap. Merge the index definition into the main indexes file before eventual deployment. Production activation requires the user-authorized deployment workflow; none was executed here.

Own score/rank: `best {direction}` returns `{courseKey,elapsedMs,rank,optedIn,serverNow}`; `standings` also returns `own:{elapsedMs,rank,optedIn}`. Private best is available without consent; public rank is null unless a public record exists. Rank uses bounded-cost Firestore count aggregation of strictly faster scores, so ties share rank. Aggregation is a separate read and is a current best-effort snapshot during concurrent finishes. Server score includes finish upload network latency; UI should label server-verified time separately from local time.

Earlier QA additionally ran an actual Functions HTTP callable test with two independently issued anonymous Auth emulator ID tokens:

```
node_modules/.bin/firebase.cmd emulators:exec --only firestore,auth,functions --project demo-campus-game --config firebase.game-test.json "node --test game-functions/test/callable.integration.cjs"
```

That checks authentication, membership, readiness, shared start, self-only challenge disclosure, rejoin and host leaving through the real callable wrapper. Full verified race/finish/rank and invalid trace cases run against Firestore-backed core with a deterministic clock. The merged root `firestore.rules` are tested under anonymous, ordinary signed-in, verified CIT student, and seeded CIT admin contexts. Earlier results: 10 unit tests, 4 Firestore emulator tests, and 1 Functions/Auth HTTP integration test passed. Later complete race evidence below supersedes this partial HTTP verification. Locked dependencies were subsequently installed successfully using `npm ci --offline --ignore-scripts --prefix game-functions`. Host runtime is Node 24; Firebase package requests Node 22. Scheduled delivery was not exercised through Pub/Sub; the cleanup handler was subsequently verified directly through `.run` against local Firestore.

`getProfile {}` is a read-only profile action returning canonical nickname/consent/profileReady/serverNow so opening the UI does not overwrite existing opt-in. Own result now also includes `publicElapsedMs`; rank corresponds to that public score and may differ from private `elapsedMs` after renewed consent. Opponent heading initializes from the first course segment and persists during stationary trace uploads.

## Final authenticated integration evidence

Latest unit command `node --test game-functions/test/core.test.cjs`: **10 passed, 0 failed**.

Latest actual callable command:

```
node_modules/.bin/firebase.cmd emulators:exec --only firestore,auth,functions --project demo-campus-game --config firebase.game-test.json "node --test game-functions/test/callable*.cjs"
```

Result: **2 passed, 0 failed, exit 0**. The full-course test issued independent anonymous Firebase Auth emulator tokens to Red, Blue, and an outsider and used the actual HTTP callable, Functions process, Firestore transactions, and real server clock. It did not replace course data or override server time. Course: `cit_bus_best_v1_outward_7b9f7c21`, actual frozen polyline length 4090.538m. Two clients followed the frozen centreline at 20m/s; final server-verified times were Red **204882ms** and Blue **205914ms**. Both sent a bogus raw score of 1ms, which was ignored. Full test duration including setup and checks: 222723ms.

Room evidence: membership required before reads; outsider denied; late join denied; independent members ready; identical server start timestamp; own challenge identifier disclosed only to self; member-only opponent position synchronization; Blue skipped a 5-second upload round (10-second interval between uploads), rejoined by code, and recovered with buffered 1-second trace samples; both completed, room status became finished, and finish order matched server elapsed times. Companion actual HTTP test verified unauthenticated denial and host leave/transfer.

Ranking evidence: verified room finishes populated opted-in public records and ranks 1/2; private best matched the verified time; withdrawal removed Red's public entry, returned rank null for Red, and promoted Blue to rank 1. The separate unit/real-Firestore regression verifies renewed consent does not republish an old private record, but a new slower verified run can publish independently while the faster private best remains private.

Time attack evidence: room and solo runs share the same authenticated challenge/trace validation path. Solo cancellation, future/stale timestamps, speed warp, off-corridor movement, skipped progress/checkpoints, course-version mismatch and prolonged unbuffered trace gaps are tested with deterministic clocks against core and real Firestore. The completed full-course HTTP run provides real-clock end-to-end finish evidence for that path; it is a synthetic backend client test, not a rendered browser play session.

Production status: no deployment, commit, push, production reads or production writes were performed. These results apply to the demo emulator environment. The emulator used host Node 24 although deployed functions request Node 22. Scheduled delivery was not exercised through Pub/Sub; the cleanup handler was subsequently verified directly through `.run` against local Firestore. Only buffered disconnects within the trace timestamp limits can resume the same verified run; a long gap beyond those limits requires cancellation/new challenge.

Latest merged-rule/transaction command `node_modules/.bin/firebase.cmd emulators:exec --only firestore --project demo-campus-game --config firebase.game-test.json "node --test game-functions/test/*emulator.cjs"`: **4 passed, 0 failed, exit 0**. Includes renewed-consent publication and complete two-identity lifecycle, concurrent room capacity, failed-attempt quotas, and merged root rules rejecting direct game reads/lists/writes even for verified CIT students and a seeded active CIT admin. Expected PERMISSION_DENIED logs are successful negative assertions. All emulator processes shut down after verification.


## Cleanup handler verification

Command: `node_modules/.bin/firebase.cmd emulators:exec --only firestore --project demo-campus-game --config firebase.game-test.json "node --test game-functions/test/cleanup.integration.cjs"`. Result: **1 passed, 0 failed, exit 0**. The test invoked the actual exported `campusGameCleanup.run` handler twice against demo Firestore. Expired room, code lookup, challenge, and quota documents were deleted. An active room, a persistent profile without expiry, and an expired record under a foreign root were retained unchanged. The second invocation was idempotent. All test rows were removed and the emulator stopped. No production implementation change, scheduler registration, deployment, or production data access occurred. The handler logic is verified; actual scheduled delivery remains outside this local invocation.

For subsequent browser integration, start persistent local services with `node_modules/.bin/firebase.cmd emulators:start --only firestore,auth,functions --project demo-campus-game --config firebase.game-test.json`. Ports: Firestore8188, Auth9198, Functions5018. Callable: `http://127.0.0.1:5018/demo-campus-game/us-central1/campusGame`. Use the demo project ID with Auth emulator issued tokens. Root owns the persistent emulator lifetime after this QA task.


## Canonical My Page nickname revision

Identity is resolved exclusively from `users/{authenticated UID}.displayName`. Game `profile` accepts consent only; supplied nickname, displayName, UID, userId, profile, profileId, profileRef, email, realName, or studentId payload fields are rejected. `getProfile` returns `{nickname:string|null,consent:boolean,profileReady:boolean,serverNow}`. The backend never writes canonical `users` documents. Ordinary existing long names and ZWJ emoji are preserved without game-specific truncation. Empty/inactive/mismatched profiles, email or email-prefix legacy defaults, and exact student-ID defaults are not used as game names; no Auth/email/real-name fallback exists. Missing canonical names prevent public opt-in and room create/join, while explicit existing consent and private best are retained. Existing room members with unavailable names show only a generic Player label.

Room reads resolve all authenticated members from their canonical profiles. Standings resolve public player IDs through a private server-only UID map and hydrate current canonical names even when the owner is offline. A missing/unsafe canonical name removes its public record. Rank responses account for faster records being removed in the same buffered transaction, so an offline first-place name removal promotes the remaining player in that response. Rank aggregation still has the documented concurrent-update snapshot limitation. Restoring a name does not implicitly republish an old private score; a new verified opted-in run is needed.

Latest validation: `node --test game-functions/test/core.test.cjs` **13 passed, 0 failed**. Canonical-name/forged-reference/missing-profile tests cover name changes in rankings and rooms, retained consent/private scores, no canonical writes, long/emoji names, and removal of an offline top-ranked name without a rank gap.

Sequential integrated command (sequential files avoid fixture cleanup interfering with other test clients):

```
node_modules/.bin/firebase.cmd emulators:exec --only firestore,auth,functions --project demo-campus-game --config firebase.game-test.json "node --test --test-concurrency=1 game-functions/test/*emulator.cjs game-functions/test/callable.integration.cjs game-functions/test/cleanup.integration.cjs"
```

Result: **7 passed, 0 failed, exit 0**: concurrent room capacity/quota, consent/public-best regression, complete two-identity Firestore-backed race, canonical profile/rank/room regression, actual two-Auth-token HTTP callable flow with name change/missing/forged-reference checks, exported cleanup repeat/protection, and merged root rules under student/admin contexts. An earlier parallel combined run failed because cleanup deleted another test fixture; files were isolated with `--test-concurrency=1` and all checks passed. All emulator services stopped and backend was handed off frozen for the root two-browser UI race. The earlier full real-clock HTTP race evidence predates the canonical-name revision; its fixture has been adapted to admin-seeded canonical profiles, while root owns the latest full UI race. No production deployment or data access occurred.


## Independent pop game courses and safe recovery

The accurate campus viewer/map remains separate. Active server game courses are frozen original stylized geometry under family `pop`, version 2; the prior accurate course snapshot is archived in `courses.campus-v1.json` and is not selected by current challenge/best/standings/room APIs. The distinct `cit_bus_best_v2_pop_` prefix and per-course fingerprint prevent prior v1 or other course times from mixing.

| Course ID | Frozen key suffix | Horizontal metres |
|---|---|---:|
| outward | 2edfca69 | 1067.629 |
| return | d2de1edd | 1067.629 |
| s_bay | 5dbf1dfb | 1876.826 |
| neon_city | a48f537d | 2683.114 |

All active course points are `[x,z,roadSurfaceY]` and `layerAware:true`. Trace sample `y` is required and represents vehicle centre, normally road surface +1.4m. Projection is limited to the validated backward/forward progress window and compares height, preventing an overlapping bridge deck from being mistaken for another course section. Samples must remain within 5m of expected vehicle height; vertical change is bounded by 8m/s plus 1m tolerance per sample. The off-road belt does not permit a wrong bridge layer. Invalid trace uploads commit no progress; the authenticated challenge may still recover safely.

`recover {challengeId}` selects only the most recent server-validated 150m checkpoint (never a client checkpoint, coordinates or height). It rolls progress and position back, sets the trace baseline `t` to current server elapsed time, and adds **5000ms** to the eventual score. Repeated recoveries require at least 2 seconds and add another server penalty. Recovery rejects extra checkpoint/position payloads, other owners, old course versions, pre-start/finished/cancelled/expired challenges and room members who left. Shared room start time is unchanged. Response: `{challengeId,progress,position:{x,z,y},yaw,t,penaltyMs,addedPenaltyMs:5000,serverNow,room?}`. Recovery response `position.y` is road surface; client sets physical body centre to +1.4m. Normal room positions are body centre. Clear pre-recovery buffered samples and send only new samples with `t` greater than the returned baseline. Room views expose the accepted rollback and cumulative penalty to members. Penalty-adjusted finish times determine ordering and public/private bests.

Final deterministic validation: `node --test game-functions/test/*.test.cjs` **22 passed, 0 failed**. Every finalized 3D course completes a full height-validated trace and a full recovery trace; keys match frontend, penalties remain server-calculated, old/cross-course scores stay isolated, canonical-name/consent regressions remain passing, and explicit overlapping-deck tests reject missing/wrong height. Real Firestore recovery tests additionally verify a raw 26-second finish with a 5-second fee ranks behind a 27-second finish without recovery.

Final pop-family integrated command (same isolated sequential command above) completed with **8 passed, 0 failed, exit 0** after all four finalized course keys were frozen. It includes actual Auth/Functions HTTP trace plus recovery to checkpoint zero, forged checkpoint rejection, five-second server penalty, altitude response and member rollback state; real Firestore penalty-adjusted race ordering and cross-course/version isolation; canonical name, ranking consent, room, merged student/admin rule and exported cleanup regressions. All emulators stopped. Full rendered four-course/two-browser playability and online race QA is owned by the parent/frontend workstream. No deployment or production data access occurred.

## Room polling quota correction

Two-client Flutter QA exposed `room` reads returning 429 after one create plus seven polls: admission create/join and room-read actions accidentally shared the same internal `room` limiter bucket (8/minute). The backend now uses a separate `room-admission` bucket capped at 8 create/join attempts/minute, while authenticated room reads use their normal 120/minute cap. Flutter polls every 2 seconds (about 30 reads/minute), which fits the read quota without weakening failed-code protection. Latest `node --test game-functions/test/*.test.cjs`: **23 passed, 0 failed**. The new regression verifies 120 room reads, independent admission limits, persisted failed-code limits and window reset. No additional emulator was started; root-owned persistent emulator lifetime was unchanged. The separate harness join-input 404 was not a backend change.

### Room transaction lock order — 2026-10-04

Room-associated actions resolve routing without retained transaction locks, then acquire the shared room before canonical/private profile reads. Challenge ownership and membership/state checks are repeated inside the gameplay transaction; routing fields are server-only and immutable. Transaction document reads are cached for the same snapshot. Timing, speed, height, consent and identity rules are unchanged.

Validation: node --test game-functions/test/*.test.cjs passed 24 tests. Against already running local Firestore/Auth/Functions emulators (8188/9198/5018), node --test --test-concurrency=1 game-functions/test/backend.emulator.cjs game-functions/test/firestore.emulator.cjs game-functions/test/cleanup.integration.cjs game-functions/test/callable.integration.cjs passed 9 integrations in 53.4s. Set FIRESTORE_EMULATOR_HOST=127.0.0.1:8188, FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9198, GCLOUD_PROJECT and GAME_TEST_PROJECT=demo-campus-game-backend-isolated. Backend/rules/cleanup fixtures use an isolated demo project; HTTP tests target demo-campus-game and seed only their generated authenticated profiles. No emulator restart or production access.

The new real Firestore regression runs opposing player polls and traces concurrently for four rounds, verifies a shared start and both server finishes, and completed those rounds in 16.9s. This is correctness evidence, not a latency improvement claim; the instrumented UI run must still measure request durations. New unit coverage verifies room-first reads for polling, joining, readiness, trace, recovery and cancellation, including rejecting another player's challenge.

### Unchanged identity write suppression — 2026-10-04

Existing private consent and player mapping documents are written only when their stored values differ. Room polling and traces retain all canonical name validation and consent/public synchronization, but stop rewriting unchanged identity records. Quota keys, counts, expiry and admission grouping are unchanged. The lock-order unit regression also asserts polls/join/readiness do not write unchanged identity records and an actual consent change does persist.

Latest verification: 24/24 unit tests and the same 9/9 sequential emulator integrations passed (53.6s). Concurrent four-round poll/trace test completed in 12.4s; variation from the previous 16.9s is not sufficient to claim a measured performance improvement. Real UI sampling queues and instrumented latency validation remain separate requirements. All tests used the existing emulators and isolated backend/rules/cleanup projects; root UI fixtures were not cleaned up.

### Independent quota lanes with legacy inheritance — 2026-10-04

Quota documents now use hashed UID plus the action lane. Create/join still share room-admission (8/minute), trace remains 240/minute, and other actions remain 120/minute. An absent lane reads its existing legacy UID bucket and inherits that lane's active minute count before charging the request, preventing a migration reset. Existing lane documents no longer read or write other lanes. Failed room codes still consume admission quota; expiry remains 24 hours and uses the same cleanup collection-group timestamp. Legacy documents are left for normal expiry. Authentication and gameplay validation are unchanged.

Verification commands are the unit and sequential emulator commands above: 25/25 units and 9/9 integrations passed, the latter in 58.7s on existing emulators with isolated backend/rules/cleanup projects. New regression covers active legacy limits 7/8 admission, 119/120 room, 239/240 trace, failed attempts, shared create/join cap, minute rollover, lane independence and TTL. Four concurrent room/trace rounds passed in 16.1s; no latency-resolution claim is made. Root UI fixtures and emulator process state were untouched.
