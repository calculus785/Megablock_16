MB16 Session 6 Notes
Session type: Dev session
Phase: Phase 3 — The Building (Visual Prototype)
Status: Phase 3 substantially complete. Several items remain.

What We Did This Session
Building & Floor System

Built BuildingData class — floor type definitions, room slot data, building layout array
Built building.gd — instances floor PackedScenes, registers rooms and floors in Rooms autoload, Camera2D with pan/zoom
Three floor scene types created in editor: FloorApartments.tscn, FloorLargeCommon.tscn, FloorSmallCommon.tscn
Switched from hardcoded pixel coordinates to Marker2D nodes placed visually in engine
Each floor scene has: Sprite2D (PNG background), HallwayLine, ElevatorLeftWait, ElevatorRightWait, Spots/RoomN_Spawn, Spots/RoomN_Door
Rooms autoload extended with get_spawn_pos(), get_door_pos(), get_door_spot(), register_floor(), get_floor_data_by_index()
FloorLobby.tscn created with Shaft0_Pos, Shaft1_Pos, Shaft2_Pos markers — shaft X positions owned by this scene, not floor scenes

Characters Visual

character_body.gd built — ColorRect + name label, anchored at feet, reads favourite_color from CharData
Characters spawn at their apartment spawn_pos on startup
bootstrap.gd updated for Phase 3: builds building first, spawns characters, creates visual bodies, registers Rooms occupancy

Movement System

movement_controller.gd built — tweens characters through waypoints, handles elevator wait/ride phases via Pathfinder signals
actions.gd updated: start_movement() helper, _wander() picks valid destination and walks there, _go_home() walks character to home_room, _queue_intent_visit_bar/cafe() now calls start_movement before queuing intent
sim.gd updated: is_in_transit check in _on_tick skips characters in transit, passive boredom gain (+3 per half-hour), passive energy drain (-2 per half-hour) added to _on_half_hour
Memory.clear_intents() added — called when character commits to new destination, clears stale conflicting intents
other_character_in_room requirement in sim now uses Rooms.get_occupants() instead of Registry loop — excludes in-transit characters correctly

Elevator System

Full elevator system built in pathfinder.gd: 2 cars, max 3 passengers, 3-second door timer resets on boarding, queues requests, dispatches to nearest waiter, routes car between floors serving all passengers
passenger_boarded and passenger_exited signals replace old elevator_arrived — eliminates multi-character boarding race condition
Shaft X positions owned by FloorLobby.tscn markers, registered via Pathfinder.register_shaft_positions()
Characters walk to hallway wait position → wait for car → board → ride (Y follows car node in _process) → exit → walk along hallway to destination door → enter room
Both elevators working, characters pick closest shaft

Boredom & Sleep

Repetition boredom implemented in sim.gd (_apply_repetition_boredom) — checks last 4 storybook entries, penalises repeating same event, exempt list per trait
WANDER boredom threshold lowered to fire reliably
Characters sleeping when energy drops (verified in logs)

Bug fixes

Characters no longer spawn at scene origin when room ID is wrong
Elevator cars no longer drift to Y=0 when idle
Post-elevator float fixed — hallway snap waypoints added after ride exit
Multiple characters no longer board simultaneously
memory.gd duplicate resolved — merged two versions into one canonical file


Known Bugs / Pending Fixes
Sleep location bug (not fixed this session):
Characters are sleeping wherever they are instead of going home first. Fix is one line in events.gd:
gdscript# In SLEEP event requirements, add:
"in_home_room": true,

# In ENERGY_CRASH event requirements, lower threshold:
"stats_below": { "energy": 5 },  # was 10
GO_HOME rarely fires:
Characters get bored of GO_HOME before rolling it. Two fixes needed:

In events.gd: raise GO_HOME base_weight to 15, lower cooldown_events to 3, add { "condition": { "stats_above": { "boredom": 60 } }, "multiply": 2.0 } weight modifier
In sim.gd: raise passive energy drain to -3.0 per half-hour and raise REST cooldown to 8