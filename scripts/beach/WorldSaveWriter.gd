class_name WorldSaveWriter
extends RefCounted
## One detached immutable snapshot in flight and at most one coalesced successor.
## The worker never accesses the scene tree or live player/object dictionaries.
var thread: Thread
var pending: Dictionary = {}
var active_state: WorldState
var last_result := true

func request(state: WorldState) -> bool:
	if not state.writable: return false
	poll()
	pending={"snapshot":state.snapshot(),"path":state.path,"state":state}
	if thread==null: _start()
	return thread!=null or not pending.is_empty()

func _start() -> void:
	if pending.is_empty(): return
	var job := pending
	pending={}
	active_state=job["state"]
	thread=Thread.new()
	var err := thread.start(_write_snapshot.bind(job["snapshot"],job["path"],active_state.recovery))
	if err!=OK:
		thread=null
		last_result=false
		push_warning("World checkpoint worker could not start; previous save retained")

func _write_snapshot(snapshot: Dictionary,path: String,recovery: String) -> Dictionary:
	var detached := WorldState.new()
	detached.path=path
	detached.recovery=recovery
	detached.seed_value=int(snapshot["seed"])
	detached.objects=snapshot["objects"]
	detached.events=snapshot["events"]
	detached.player=snapshot["player"]
	return {"success":detached.write_save(),"recovery":detached.recovery}

func _finish() -> void:
	var result: Dictionary = thread.wait_to_finish()
	thread=null
	last_result=bool(result["success"])
	if last_result: active_state.recovery=result["recovery"]
	else: push_warning("World checkpoint failed; previous save retained")
	active_state=null

func poll() -> void:
	if thread!=null and not thread.is_alive(): _finish()
	if thread==null and not pending.is_empty(): _start()

func flush() -> bool:
	while thread!=null or not pending.is_empty():
		if thread!=null: _finish()
		if not pending.is_empty(): _start()
	return last_result

func queued_count() -> int:
	return int(thread!=null)+int(not pending.is_empty())
