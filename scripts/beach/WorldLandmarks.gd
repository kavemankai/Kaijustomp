class_name WorldLandmarks
extends RefCounted
## Additive metadata/art on existing parcels: IDs, footprints and rewards stay compatible.
const SITES := [
    {"id":"banksia", "title":"Banksia Heights", "object":"", "at":Vector3(0,0,-150), "style":"town"},
    {"id":"harbour", "title":"Seabrook Freight Terminal", "object":"g1:-14:-2:0", "chunk":Vector2i(-14,-2), "style":"port"},
    {"id":"civic", "title":"Civic Spire", "object":"g1:12:-12:0", "chunk":Vector2i(12,-12), "style":"civic"},
    {"id":"power", "title":"Ironbark Grid Station", "object":"g1:-8:-13:0", "chunk":Vector2i(-8,-13), "style":"power"},
    {"id":"command", "title":"Highland Command", "object":"g1:22:-19:0", "chunk":Vector2i(22,-19), "style":"command"},
    {"id":"western", "title":"Westhaven Observatory", "object":"g1:-24:-7:0", "chunk":Vector2i(-24,-7), "style":"civic"}]

static func decorate(d: Dictionary) -> void:
    for site in SITES:
        if d["id"]==site["object"]:
            d["landmark"]=site["id"]
            return

static func locations(layout: WorldLayout) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    for site in SITES:
        var item: Dictionary=site.duplicate()
        if not site["object"].is_empty():
            var found := false
            for d in layout.describe(site["chunk"]):
                if d["id"]==site["object"]:
                    item["at"]=d["position"]
                    found=true
                    break
            if not found: continue # Configurable smaller maps omit unavailable sites.
        result.append(item)
    return result

static func art(root: Node3D, id: String, size: Vector2, height: float) -> void:
    var style := ""
    for site in SITES:
        if site["id"]==id: style=site["style"]
    var detail := Node3D.new()
    detail.name="LandmarkIdentity"
    root.add_child(detail)
    var accent := Color("d6ab66")
    if style=="port":
        # Freight facade gantry and spreader share the structure destruction lifecycle.
        for side in [-1,1]:
            CoastalArt.box(detail,Vector3(side*size.x*.34,height*.5,size.y*.51),Vector3(2,height,2),accent)
        CoastalArt.box(detail,Vector3(0,height*.94,size.y*.51),Vector3(size.x*.75,1.5,3),accent)
        CoastalArt.box(detail,Vector3(0,height*.77,size.y*.55),Vector3(8,1,4),CoastalArt.INK)
    elif style=="power":
        for side in [-1,1]:
            CoastalArt.box(detail,Vector3(side*size.x*.3,height*.5,size.y*.51),Vector3(3,height,3),Color("c3c8bb"))
            for y in [.35,.65,.9]:
                CoastalArt.box(detail,Vector3(side*size.x*.3,height*y,size.y*.51),Vector3(7,1,4),accent)
    elif style=="command":
        CoastalArt.oval(detail,Vector3(0,height*.8,size.y*.53),Vector3(12,5,3),Color("c3d3cc"))
        CoastalArt.box(detail,Vector3(0,height*.55,size.y*.53),Vector3(1,height*.7,1),CoastalArt.INK)
        CoastalArt.box(detail,Vector3(0,height*.25,size.y*.53),Vector3(size.x*.65,3,.4),accent)
    else:
        # Gold civic crown bands and a dark clock face read at middle distance.
        for y in [.65,.85,.97]:
            CoastalArt.box(detail,Vector3(0,height*y,0),Vector3(size.x+.5,1,size.y+.5),accent)
        CoastalArt.oval(detail,Vector3(0,height*.8,size.y*.53),Vector3(3,3,.3),CoastalArt.INK)
        CoastalArt.box(detail,Vector3(0,height*.8,size.y*.54),Vector3(.3,2,.2),accent)
    CoastalArt.merge(detail,"LandmarkDetails")
