class_name WorldConfiguration
extends Resource
## Change world extent/seed here without editing gameplay. Existing saves retain their seed.
@export_range(2048,16000,1) var half_width := 10000.0
@export_range(2000,12000,1) var inland_depth := 6000.0
@export var world_seed := 79123
