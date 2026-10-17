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
var geography: WorldLayout
var record: Dictionary
var sites: Array[Dictionary]=[]
var notice := ""
var notice_time := 0.0
var clock := 0.0
var current_threat := 5

func setup(world_state: WorldState,layout: WorldLayout) -> void:
    state=world_state
    geography=layout
    sites=WorldLandmarks.locations(layout)
    record=state.events.get("objectives",{"version":1,"discovered":{},"completed":{},"counters":{},"tracked":"banksia"})
    # Additive tracking migration: retain a previously selected non-default goal.
    if not record.has("pins"):
        record["pins"]=[]
        if record.get("tracked","banksia")!="banksia" and not complete(record["tracked"]):
            record["pins"].append(record["tracked"])
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
    if data.has("pins"):
        if not data["pins"] is Array or data["pins"].size()>3: return false
        var seen: Array=[]
        for id in data["pins"]:
            if not id is String or id not in ids or id in seen: return false
            seen.append(id)

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
    current_threat=scene.defcon
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
    for id in record.get("pins",[]).duplicate():
        if complete(id): record["pins"].erase(id)
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
        if goal["id"]!=id or complete(id): continue
        if id in record["pins"]:
            record["pins"].erase(id)
        elif record["pins"].size()<3:
            record["pins"].append(id)
            record["tracked"]=id # Backward-compatible primary selection.
        else:
            announce("THREE PINNED / UNPIN ONE TO CHANGE")
        return

func tracked_goals(at: Vector3) -> Array[Dictionary]:
    var selected: Array[Dictionary]=[]
    for id in record.get("pins",[]):
        for goal in GOALS:
            if goal["id"]==id and not complete(id): selected.append(goal)
    var candidates: Array[Dictionary]=[]
    for i in range(GOALS.size()):
        var goal: Dictionary=GOALS[i]
        if complete(goal["id"]) or goal["id"] in record.get("pins",[]): continue
        candidates.append({"goal":goal,"score":relevance(goal,at),"order":i})
    candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        return a["score"]>b["score"] if a["score"]!=b["score"] else a["order"]<b["order"])
    for candidate in candidates:
        if selected.size()>=3: break
        selected.append(candidate["goal"])
    return selected

func sector_name(at: Vector3) -> String:
    if WorldLayout.authored(at):
        return "STARTING BEACH" if at.z>-82 else ("BANKSIA HEIGHTS" if at.z>-500 else "STARTING INDUSTRY")
    return WorldLayout.DISTRICTS[geography.district(at)].to_upper()

func relevance(goal: Dictionary,at: Vector3) -> float:
    var counts: Dictionary=record["counters"]
    var score := 10.0
    var point := target(goal)
    if goal.has("site") and point!=Vector3.INF:
        # Nearby parcel/sector missions dominate; remote targets remain available to pin.
        var distance := Vector2(point.x-at.x,point.z-at.z).length()
        score=110.0-minf(100,distance/20)
        if WorldLayout.coord(point)==WorldLayout.coord(at): score+=30
        if goal["kind"]=="destroy" and int(counts.get("evolution",0))<22: score-=35
    elif goal["kind"]=="evolution":
        var remaining := maxi(0,int(goal["goal"])-int(counts.get("evolution",0)))
        score=65.0-minf(50,remaining)
    elif goal["kind"]=="coast": score=55 if at.z>-650 else 15
    elif goal["kind"]=="inland": score=55 if at.z<-500 else 20
    elif goal["kind"]=="demolished": score=50 if int(counts.get("evolution",0))>=22 else 12
    elif goal["kind"]=="sites": score=35
    elif goal["kind"]=="responders": score=60 if current_threat<=4 else 14
    elif goal["kind"]=="cooled": score=95 if counts.get("hot",false) and current_threat<5 else 8
    return score+minf(10,10.0*value(goal)/float(goal["goal"]))

func target(goal: Dictionary) -> Vector3:
    if goal.has("site"):
        for site in sites:
            if site["id"]==goal["site"]: return site["at"]
    if goal["kind"]=="coast": return Vector3(2560,0,-53)
    if goal["kind"]=="inland": return Vector3(0,0,-2304)
    return Vector3.INF
func guidance(goal: Dictionary,at: Vector3,compact: bool=false) -> String:
    var point := target(goal)
    if point==Vector3.INF:
        if compact:
            match goal["kind"]:
                "evolution": return "Feed and evolve to E%d" % goal["goal"]
                "demolished": return "Destroy different structures"
                "responders": return "Defeat DEFCON responders"
                "cooled": return "Escape alive to DEFCON 5" if record["counters"].get("hot",false) else "Reach DEFCON 2, then escape"
                "sites": return "Discover named landmarks"
        return goal["detail"]
    var offset := point-at
    var direction := "EAST" if offset.x>0 else "WEST"
    if absf(offset.z)>absf(offset.x): direction="INLAND" if offset.z<0 else "COASTWARD"
    var name := ""
    for site in sites:
        if not compact and site["id"]==goal.get("site",""): name=site["title"]+" / "
    return "%s%s / %d units" % [name,direction,roundi(Vector2(offset.x,offset.z).length())]
