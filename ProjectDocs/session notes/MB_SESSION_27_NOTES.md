MB16 Session 31 — Notes

Dev session. Door system + vestibule architecture.

Session type: Dev
Phase: Phase 4 — Base Event Layer + Social Systems
Status: Door animations wired into sim movement engine. Vestibule scenes added between rooms and hallways, replacing old DoorwayPos/RoomX_Doorway markers. Characters wait at doors, navigate L-shaped vestibules. Proximity system deferred to future phase with directional facings.


What we built / decided


Door wait system (sim.gd) — Characters pause at door waypoints (movement_phase = "waiting_door"), call request_open(), wait for door_opened signal, then resume walking. If door is already open, they walk through immediately. No timers — pure state check.
Door future-proofing (door.gd) — request_open() returns bool (false if locked). Added is_locked(), is_closed(), get_state(), lock(), unlock(). New signals: door_locked, door_unlocked, open_refused. close_wait_time exposed as @export (was hardcoded 1.5s).
Vestibule template scene — L-shaped corridor placed at every room doorway. Contains 4 Marker3D spots under Spots/: RoomOutSpot, MidSpot00, MidSpot01, RoomInSpot. Characters navigate the L-shape between hallway and room doors.
Vestibule instancing (building.gd) — _instance_vestibules() reads RoomX_Doorway markers as placement origins, instances vestibule scene, registers spot positions via Rooms.set_vestibule_data(). Per-slot scene override via slot.get("vestibule_scene") for future bespoke vestibules.
Pathfinder vestibule routing (pathfinder.gd) — Exit/enter waypoint sequences now route through vestibule spots. Two DRY helpers: _append_exit_waypoints() and _append_enter_waypoints(). Waypoint types unchanged — only positions changed.
Proximity system — DEFERRED — Original sprint item split into close proximity (bumping) and eyesight (directional awareness). Both need facing_direction on CharData. Moved to future phase where directional facing is added.


What's working (confirmed in sim)


Characters pause at room doors and hallway doors while they slide open
Characters navigate L-shaped vestibule between room and hallway
Multiple characters can use the same door — second character walks through immediately if door is still open
Door close timer works correctly — doors slide shut after last person passes
Vestibule placement via RoomX_Doorway markers confirmed working


Still broken / not firing reliably


Jamie float-through-floor bug was observed before vestibule fix — likely resolved by vestibule providing consistent Y positions through the doorway. Needs confirmation at scale.
Vestibule positioning may need per-floor tweaking of RoomX_Doorway markers in the editor.


Bugs fixed

BugFileRoot cause → fixCharacters walking through closed doorssim.gd_on_sim_waypoint_arrived had no door calls — added request_open() at wait waypoints and notify_through() at doorway waypointsCharacter floating through floor at doorwayvestibule systemY-position discontinuity between hallway and room markers — vestibule provides continuous path with consistent Y values

Files modified

FileChangesim.gdAdded waiting_door phase to _process(). Rewrote _on_sim_waypoint_arrived() with door handling at all 10 waypoint types. Added _request_door_and_wait() helper.door.gdFull rewrite — added locked state, request_open() returns bool, query methods (is_locked, is_closed, get_state), lock/unlock methods, new signals, exposed close_wait_time as @export.pathfinder.gdRewrote plan_route() and _plan_from_hallway() to route through vestibule spots. Added _append_exit_waypoints() and _append_enter_waypoints() DRY helpers.building.gdAdded DEFAULT_VESTIBULE_SCENE constant, _instance_vestibules() function. Removed DoorwayPos reading from _instance_room_scene(). Added call in _build_floors().rooms.gdAdded set_vestibule_data() and get_vestibule_spot() functions.vestibule_template.tscnNEW — L-shaped corridor scene with Geometry + 4 spot markers under Spots/.