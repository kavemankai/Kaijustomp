class_name MobileTouchController
extends Control

signal movement_vector_updated(vector: Vector2)
signal tap_action_triggered()

@export var deadzone_radius: float = 15.0
@export var joystick_max_drag: float = 80.0

var joystick_active: bool = false
var joystick_touch_index: int = -1
var touch_center: Vector2 = Vector2.ZERO
var current_drag_pos: Vector2 = Vector2.ZERO
var current_output: Vector2 = Vector2.ZERO

var right_touch_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _process(delta: float) -> void:
	if right_touch_time > 0.0:
		right_touch_time += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var half_w: float = get_viewport_rect().size.x * 0.5
		if event.pressed:
			if event.position.x < half_w and not joystick_active:
				joystick_active = true
				joystick_touch_index = event.index
				touch_center = event.position
				current_drag_pos = event.position
			elif event.position.x >= half_w:
				right_touch_time = 0.001
		else:
			if joystick_active and event.index == joystick_touch_index:
				joystick_active = false
				joystick_touch_index = -1
				current_output = Vector2.ZERO
				movement_vector_updated.emit(Vector2.ZERO)
			elif right_touch_time > 0.0:
				if right_touch_time < 0.25:
					tap_action_triggered.emit()
				right_touch_time = 0.0

	elif event is InputEventScreenDrag:
		if joystick_active and event.index == joystick_touch_index:
			current_drag_pos = event.position
			var drag_offset: Vector2 = event.position - touch_center
			var distance: float = drag_offset.length()
			
			if distance < deadzone_radius:
				current_output = Vector2.ZERO
			else:
				var clamped_len: float = min(distance, joystick_max_drag)
				var norm_dir: Vector2 = drag_offset.normalized()
				current_output = norm_dir * ((clamped_len - deadzone_radius) / (joystick_max_drag - deadzone_radius))
				
			movement_vector_updated.emit(current_output)

func _draw() -> void:
	if joystick_active:
		draw_arc(touch_center, joystick_max_drag, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 3.0)
		draw_circle(touch_center + current_output * joystick_max_drag, 24.0, Color(0.2, 1.0, 0.8, 0.65))
