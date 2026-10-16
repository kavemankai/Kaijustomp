class_name CreatureAudio
extends Node
## Self-contained, low-cost creature Foley. Generated once at startup.
## Works offline with no licensed audio or external asset dependencies.
## Replace WAV sources later without changing the gameplay event hooks.

const RATE := 22050
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var next_voice := 0
var foot_clock := 0.0
var breath_clock := 1.6

func _ready() -> void:
	sounds["step"] = _synth("step", 0.31)
	sounds["breath"] = _synth("breath", 1.10)
	sounds["bite"] = _synth("bite", 0.33)
	sounds["shed"] = _synth("shed", 1.40)
	for i in range(3):
		var player := AudioStreamPlayer.new()
		player.volume_db = -12.0
		add_child(player)
		players.append(player)

func _synth(kind: String, seconds: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7099 + kind.length() * 317 + kind.unicode_at(0)
	var frame_count := int(seconds * float(RATE))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var filtered := 0.0
	var phase := 0.0
	for i in range(frame_count):
		var t := float(i) / float(RATE)
		var p := t / seconds
		var random_noise := rng.randf_range(-1.0, 1.0)
		filtered = lerpf(filtered, random_noise, 0.07 if kind != "bite" else 0.35)
		var amp := 0.0
		var freq := 50.0
		var mix := 0.0
		match kind:
			"step":
				amp = pow(maxf(0.0, 1.0 - p), 3.7)
				freq = 60.0 - 24.0 * p
				mix = 0.56 * sin(phase) + 0.36 * filtered + 0.11 * random_noise
			"breath":
				amp = pow(maxf(0.0, sin(p * PI)), 1.1)
				freq = 50.0 + 12.0 * sin(p * PI)
				mix = 0.44 * filtered + 0.065 * sin(phase) + 0.12 * random_noise
			"bite":
				amp = exp(-p * 10.0)
				freq = 100.0 - 75.0 * p
				mix = 0.52 * sin(phase) + 0.52 * random_noise + 0.18 * filtered
			"shed":
				amp = sin(p * PI) * (0.65 + 0.32 * sin(p * TAU * 9.0))
				freq = 36.0 + 22.0 * p
				var crack := random_noise * (0.6 if sin(p * TAU * 14.0) > 0.92 else 0.08)
				mix = 0.36 * sin(phase) + 0.45 * filtered + crack
		phase += TAU * freq / float(RATE)
		var value := clampf(amp * mix * 0.85, -0.97, 0.97)
		var pcm := int(value * 32767.0)
		if pcm < 0:
			pcm += 65536
		bytes[i * 2] = pcm & 255
		bytes[i * 2 + 1] = (pcm >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func play_effect(kind: String) -> void:
	if not sounds.has(kind) or players.is_empty():
		return
	var voice: AudioStreamPlayer = players[next_voice]
	next_voice = (next_voice + 1) % players.size()
	voice.stream = sounds[kind]
	voice.play()

func update_gait(delta: float, moving: bool, sprint: bool) -> void:
	breath_clock -= delta
	if breath_clock <= 0.0:
		play_effect("breath")
		breath_clock = 3.3 if moving else 2.3
	if moving:
		foot_clock += delta
		var cadence := 0.19 if sprint else 0.32
		if foot_clock >= cadence:
			foot_clock -= cadence
			play_effect("step")
	else:
		foot_clock = 0.0
