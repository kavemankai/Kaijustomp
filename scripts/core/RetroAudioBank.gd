class_name RetroAudioBank
extends Node

const MIX_RATE: int = 22050
const POOL_SIZE: int = 8

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var player_idx: int = 0
var last_play_time: Dictionary = {}

func _ready() -> void:
	# Keep playing while the level-up modal pauses the tree, so the fanfare is not cut off.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		players.append(p)

	streams["roar"] = _synth_kaiju_roar()
	streams["footstep"] = _synth_footstep()
	streams["shoot"] = _synth_laser_shoot()
	streams["building_crush"] = _synth_building_crush()
	streams["enemy_explode"] = _synth_enemy_explode()
	streams["player_hurt"] = _synth_player_hurt()
	streams["pickup_xp"] = _synth_pickup_xp()
	streams["level_up"] = _synth_level_up()

func play_sfx(sfx_name: String, min_interval_sec: float = 0.04, pitch_scale: float = 1.0) -> void:
	if not streams.has(sfx_name):
		return
	var now: float = Time.get_ticks_msec() * 0.001
	var last: float = last_play_time.get(sfx_name, -10.0)
	if (now - last) < min_interval_sec:
		return
	last_play_time[sfx_name] = now

	var p: AudioStreamPlayer = players[player_idx]
	player_idx = (player_idx + 1) % POOL_SIZE
	p.stream = streams[sfx_name]
	p.pitch_scale = pitch_scale * randf_range(0.92, 1.08)
	p.play()

func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var count: int = samples.size()
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var s: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, s)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav

func _synth_kaiju_roar() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.75)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = sin(clampf(t / 0.75, 0.0, 1.0) * PI)
		var freq: float = 95.0 + sin(t * 24.0) * 18.0 - t * 30.0
		phase += (freq * TAU) / float(MIX_RATE)
		var carrier: float = sin(phase + sin(t * 140.0) * 2.5)
		var grit: float = randf_range(-0.35, 0.35)
		out[i] = clampf((carrier * 0.75 + grit) * env * 0.7, -1.0, 1.0)
	return _make_wav(out)

func _synth_footstep() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.16)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = exp(-t * 22.0)
		var freq: float = 65.0 * exp(-t * 8.0)
		phase += (freq * TAU) / float(MIX_RATE)
		out[i] = (sin(phase) * 0.8 + randf_range(-0.2, 0.2)) * env * 0.6
	return _make_wav(out)

func _synth_laser_shoot() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.09)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = exp(-t * 28.0)
		var freq: float = 780.0 - t * 5200.0
		phase += (maxf(freq, 120.0) * TAU) / float(MIX_RATE)
		out[i] = (1.0 if sin(phase) > 0.0 else -1.0) * env * 0.25
	return _make_wav(out)

func _synth_building_crush() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.45)
	var out := PackedFloat32Array()
	out.resize(count)
	var low_filter: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = exp(-t * 5.5)
		var raw_noise: float = randf_range(-1.0, 1.0)
		low_filter = lerpf(low_filter, raw_noise, 0.22)
		out[i] = clampf(low_filter * env * 1.4, -1.0, 1.0)
	return _make_wav(out)

func _synth_enemy_explode() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.22)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = exp(-t * 14.0)
		phase += (110.0 * exp(-t * 6.0) * TAU) / float(MIX_RATE)
		out[i] = (sin(phase) * 0.5 + randf_range(-0.6, 0.6)) * env * 0.5
	return _make_wav(out)

func _synth_player_hurt() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.14)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var env: float = exp(-t * 18.0)
		phase += (160.0 * TAU) / float(MIX_RATE)
		out[i] = sin(phase + randf_range(-0.5, 0.5)) * env * 0.55
	return _make_wav(out)

func _synth_pickup_xp() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.11)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var freq: float = 587.33 if t < 0.05 else 880.0
		var env: float = exp(-t * 16.0)
		phase += (freq * TAU) / float(MIX_RATE)
		out[i] = sin(phase) * env * 0.32
	return _make_wav(out)

func _synth_level_up() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.42)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	for i in range(count):
		var t: float = float(i) / float(MIX_RATE)
		var step: int = clampi(int(t / 0.10), 0, 3)
		var env: float = exp(-fmod(t, 0.105) * 10.0)
		phase += (notes[step] * TAU) / float(MIX_RATE)
		out[i] = (0.6 * sin(phase) + 0.4 * signf(sin(phase))) * env * 0.35
	return _make_wav(out)
