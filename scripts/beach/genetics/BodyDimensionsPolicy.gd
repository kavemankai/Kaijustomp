class_name BodyDimensionsPolicy
extends RefCounted
## Chosen physical growth changes anatomy, never forces an upright body plan.
const AXIAL := ["snake", "worm"]
static func measure(family: String, rank: int) -> Dictionary:
	var r := clampi(rank, 0, 18)
	var n := float(r)
	var base := maxf(1.0, pow(1.12, n))
	var p := {"family":family, "rank":r, "axial":family in AXIAL, "upright_allowed":family in ["ape", "reptile", "biomass"], "scale_metric":base, "length":4.5, "radius":.9, "height":2.5, "width":2.0, "wingspan":0.0, "segments":0}
	match family:
		"snake":
			p["length"] = 5.0 + .9*n + .18*n*n
			p["radius"] = .54 + .045*n
			p["height"] = float(p["radius"])*2.25+.30
			p["width"] = 2.0*float(p["radius"])
			p["segments"] = mini(48, maxi(8, ceili(float(p["length"])/1.8)))
		"worm":
			p["length"] = 6.0 + 1.1*n + .18*n*n
			p["radius"] = .70 + .076*n
			p["height"] = 1.45 + .12*n
			p["width"] = 2.0*float(p["radius"])
			p["segments"] = mini(48, maxi(8, ceili(float(p["length"])/2.0)))
		"bird":
			p["width"] = 1.6 + .11*n
			p["height"] = 2.25 + .13*n
			p["length"] = 3.0 + .12*n
			p["wingspan"] = 4.2 + .65*n + .018*n*n
		"crab":
			p["width"] = 3.1 + .38*n
			p["height"] = 1.6 + .055*n
			p["length"] = 3.2 + .21*n
		"spider":
			p["width"] = 3.0 + .39*n
			p["height"] = 1.6 + .08*n
			p["length"] = 3.1 + .20*n
		"mole":
			p["width"] = 2.0 + .21*n
			p["height"] = 1.6 + .07*n
			p["length"] = 3.6 + .21*n
		"ape":
			p["width"] = 2.1 + .17*n
			p["height"] = 2.8 + .31*n
			p["length"] = 3.1 + .13*n
		"biomass":
			p["width"] = 2.0 + .21*n
			p["height"] = 2.25 + .21*n
			p["length"] = 3.6 + .22*n
		_:
			p["width"] = 2.05 + .18*n
			p["height"] = 2.25 + .22*n
			p["length"] = 4.0 + .24*n
	return p
static func envelope(p: Dictionary) -> float:
	return maxf(float(p["width"])*.5,float(p["radius"]) if p["axial"] else 0.0)+.35
static func visual_axes(p: Dictionary, scale_metric: float) -> Vector3:
	var s := maxf(.01,scale_metric)
	if p["axial"]:
		# Head/neck growth follows girth. Only the world trail grows in length.
		return Vector3(float(p["radius"])*1.9,float(p["height"])/1.7,float(p["radius"])*1.8)/s
	var canonical_width: float={"crab":4.2,"spider":4.2,"ape":3.3,"mole":2.3}.get(p["family"],2.0)
	var canonical_height: float={"crab":1.6,"spider":1.5,"bird":2.5,"mole":1.5}.get(p["family"],2.3)
	return Vector3(float(p["width"])/canonical_width, float(p["height"])/canonical_height, minf(3.0,float(p["length"])/4.0))/s
