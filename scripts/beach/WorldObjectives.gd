class_name WorldObjectives
extends RefCounted
## Optional concurrent goals. Automatic one-time renown never changes biomass or mutations.
const GOALS := [
    {"id":"banksia", "title":"Beyond the beach", "detail":"Discover Banksia Heights.", "site":"banksia", "kind":"discover", "goal":1},
    {"id":"coast", "title":"Coastal wanderer", "detail":"Travel 2,500 units east or west of the starting beach.", "kind":"coast", "goal":2500},
    {"id":"inland", "title":"Into the interior", "detail":"Explore 2,200 units inland.", "kind":"inland", "goal":2200},
    {"id":"sites", "title":"Know your territory", "detail":"Discover three named landmarks.", "kind":"sites", "goal":3},
    {"id":"upright", "title":"Stand tall", "detail":"Reach evolution 22 through the existing evolution system.", "kind":"evolution", "goal":22},
    {"id":"giant", "title":"City-sized appetite", "detail":"Reach evolution 34.", "kind":"evolution", "goal":34},
    {"id":"titan", "title":"Titan of the coast", "detail":"Reach evolution 80.", "kind":"evolution", "goal":80},
    {"id":"demolition", "title":"Leave your mark", "detail":"Destroy twelve different structures.", "kind":"demolished", "goal":12},
    {"id":"port", "title":"Close the harbour", "detail":"Destroy Seabrook Freight Terminal.", "site":"harbour", "kind":"destroy", "goal":1},
    {"id":"grid", "title":"Power down", "detail":"Destroy Ironbark Grid Station.", "site":"power", "kind":"destroy", "goal":1},
    {"id":"command", "title":"Challenge the command", "detail":"Destroy Highland Command.", "site":"command", "kind":"destroy", "goal":1},
    {"id":"response", "title":"Break the response", "detail":"Defeat five DEFCON responders in combat.", "kind":"responders", "goal":5},
    {"id":"escape", "title":"Lose the heat", "detail":"Reach DEFCON 2 or 1, then return alive to DEFCON 5.", "kind":"cooled", "goal":1}]
const COUNTERS := ["coast","inland","evolution","demolished","responders","hot","cooled"]
var state: WorldState
var record: Dictionary
var sites: Array[Dictionary]=[]
var notice := ""
var notice_time := 0.0
var clock := 0.0

func setup(world_state: WorldState,layout: WorldLayout) -> void:
    state=world_state
    sites=WorldLandmarks.locations(layout)
    record=state.events.get("objectives",{"version":1,"discovered":{},"completed":{},"counters":{},"tracked":"banksia"})
    state.events["objectives"]=record
    # Existing v1 saves gain goals without resetting progression or duplicating rewards.
    var destroyed := 0
    for delta in state.objects.values():
        if delta.get("destroyed",false): destroyed+=1
    record["counters"]["demolished"]=maxi(destroyed,int(record["counters"].get("demolished",0)))

static func valid(data: Variant) -> bool:
    if not data is Dictionary or data.get("version")!=1: return false
    if not data.get("tracked") is String: return false
    var ids: Array=[]
    for goal in GOALS: ids.append(goal["id"])
    if data["tracked"] not in ids: return false
    for field in ["discovered","completed","counters"]:
        if not data.get(field) is Dictionary: return false
    var site_ids: Array=[]
    for site in WorldLandmarks.SITES: site_ids.append(site["id"])
    for id in data["discovered"]:
        if id not in site_ids or not data["discovered"][id] is bool: return false
    for id in data["completed"]:
        if id not in ids or not data["completed"][id] is bool: return false
    for id in data["counters"]:
        var value = data["counters"][id]
        if id not in COUNTERS: return false
        if id in ["hot","cooled"]:
            if not value is bool: return false
        elif not WorldState._number(value) or float(value)<0 or float(value)>100000000: return false
    return true

func observe(scene: Node3D,delta: float) -> void:
    if state==null: return
    notice_time=maxf(0,notice_time-delta)
    clock-=delta
    if clock>0: return
    clock=.25
    var at: Vector3=scene.beast.position
    var counts: Dictionary=record["counters"]
    counts["coast"]=maxf(float(counts.get("coast",0)),absf(at.x))
    counts["inland"]=maxf(float(counts.get("inland",0)),maxf(0,-at.z))
    counts["evolution"]=maxi(int(counts.get("evolution",0)),scene.evolutions)
    if scene.defcon<=2: counts["hot"]=true
    if counts.get("hot",false) and scene.defcon==5 and scene.hp>0: counts["cooled"]=true
    for site in sites:
        var radius := maxf(100,minf(320,scene.growth_scale*8+80))
        if at.distance_to(site["at"])<=radius and not record["discovered"].get(site["id"],false):
            record["discovered"][site["id"]]=true
            announce("DISCOVERED: "+site["title"])
    evaluate()

func responder_defeated() -> void:
    if state==null: return
    record["counters"]["responders"]=mini(100000000,int(record["counters"].get("responders",0))+1)
    evaluate()

func demolished() -> void:
    if state==null: return
    record["counters"]["demolished"]=mini(100000000,int(record["counters"].get("demolished",0))+1)
    evaluate()

func value(goal: Dictionary) -> int:
    match goal["kind"]:
        "discover": return int(record["discovered"].get(goal["site"],false))
        "sites":
            var total := 0
            for yes in record["discovered"].values(): total+=int(yes)
            return total
        "destroy":
            for site in sites:
                if site["id"]==goal["site"]: return int(state.objects.get(site["object"],{}).get("destroyed",false))
            return 0
        _: return int(record["counters"].get(goal["kind"],0))

func evaluate() -> void:
    for goal in GOALS:
        if not complete(goal["id"]) and value(goal)>=goal["goal"]:
            record["completed"][goal["id"]]=true
            announce("COMPLETE: %s  +10 RENOWN" % goal["title"])
    if complete(record["tracked"]):
        for goal in GOALS:
            if not complete(goal["id"]): record["tracked"]=goal["id"]; break

func complete(id: String) -> bool: return record.get("completed",{}).get(id,false)
func renown() -> int:
    var total := 0
    for goal in GOALS: total+=10*int(complete(goal["id"]))
    return total
func announce(message: String) -> void:
    notice=message
    notice_time=6
func tracked() -> Dictionary:
    for goal in GOALS:
        if goal["id"]==record.get("tracked","banksia"): return goal
    return GOALS[0]
func track(id: String) -> void:
    for goal in GOALS:
        if goal["id"]==id: record["tracked"]=id; return
func target(goal: Dictionary) -> Vector3:
    if goal.has("site"):
        for site in sites:
            if site["id"]==goal["site"]: return site["at"]
    if goal["kind"]=="coast": return Vector3(2560,0,-53)
    if goal["kind"]=="inland": return Vector3(0,0,-2304)
    return Vector3.INF
func guidance(goal: Dictionary,at: Vector3) -> String:
    var point := target(goal)
    if point==Vector3.INF: return goal["detail"]
    var offset := point-at
    var direction := "EAST" if offset.x>0 else "WEST"
    if absf(offset.z)>absf(offset.x): direction="INLAND" if offset.z<0 else "COASTWARD"
    var name := ""
    for site in sites:
        if site["id"]==goal.get("site",""): name=site["title"]+" / "
    return "%s%s / %d units" % [name,direction,roundi(Vector2(offset.x,offset.z).length())]
