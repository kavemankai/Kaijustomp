class_name MutationIcons
extends RefCounted
## Original vector anatomical diagrams, cached per family and appearance tier.
static var cache: Dictionary = {}

static func texture(id: String, tier: int) -> Texture2D:
	var key := "%s%d"%[id,mini(3,tier)]
	if cache.has(key): return cache[key]
	var marks: Dictionary = {
		"armour":'<path d="M24 28L30 32L25 38L20 34ZM40 28L44 34L39 38L34 32ZM24 39L29 43L25 49L20 45ZM40 39L44 45L39 49L35 43Z"/>',
		"speed":'<path d="M10 28L18 31L11 39L14 33L8 34ZM49 28L57 31L50 39L53 33L47 34Z"/>',
		"stamina":'<path d="M19 34H23V39H19ZM19 42H23V47H19ZM41 34H45V39H41ZM41 42H45V47H41Z"/>',
		"jaw":'<path d="M23 15Q32 23 41 15L39 24Q32 29 25 24Z"/>',
		"strength":'<path d="M10 25L12 18L14 25L17 18L18 29ZM46 29L47 18L50 25L53 18L54 25Z"/>',
		"health":'<path d="M24 28Q32 22 40 28L39 40Q32 44 25 40Z"/>',
		"regen":'<circle cx="22" cy="44" r="3"/><circle cx="22" cy="51" r="2.5"/><circle cx="42" cy="44" r="3"/><circle cx="42" cy="51" r="2.5"/>'}
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="80" viewBox="0 0 64 80"><rect width="64" height="80" rx="10" fill="#18343c"/><g fill="#61998c"><path d="M27 50Q34 57 30 73Q39 63 37 49Z"/><ellipse cx="32" cy="38" rx="12" ry="19"/><path d="M22 12Q32 5 42 12L40 24Q32 28 24 24Z"/><path d="M23 28L13 24L10 30L22 36ZM41 28L51 24L54 30L42 36ZM22 44L13 50L14 55L26 50ZM42 44L51 50L50 55L38 50Z"/></g><g fill="#efb778">%s</g>' % marks.get(id,"")
	for i in range(3):
		svg += '<circle cx="%d" cy="76" r="2" fill="%s"/>'%[25+i*7,"#efb778" if i<mini(tier,3) else "#446465"]
	svg += '</svg>'
	var image := Image.new()
	image.load_svg_from_string(svg)
	var result := ImageTexture.create_from_image(image)
	cache[key] = result
	return result
