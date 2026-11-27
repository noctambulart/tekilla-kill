extends RefCounted

enum Cue { EMPTY, WALL, TARGET, RECOVERY, MELEE }

const SAMPLE_RATE := 22050
static var _clips: Dictionary[Cue, AudioStreamWAV] = {}


static func play(parent: Node, cue: Cue) -> void:
	if not _clips.has(cue):
		_clips[cue] = _make_clip(cue)
	var player := AudioStreamPlayer.new()
	player.stream = _clips[cue]
	player.volume_db = -12.0
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func _make_clip(cue: Cue) -> AudioStreamWAV:
	var duration := 0.075
	var frequency := 950.0
	var noise_mix := 0.42
	match cue:
		Cue.WALL:
			duration = 0.09
			frequency = 1750.0
			noise_mix = 0.65
		Cue.TARGET:
			duration = 0.09
			frequency = 165.0
			noise_mix = 0.30
		Cue.RECOVERY:
			duration = 0.12
			frequency = 660.0
			noise_mix = 0.0
		Cue.MELEE:
			duration = 0.10
			frequency = 110.0
			noise_mix = 0.2
	var samples := roundi(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 40 + cue
	for i in range(samples):
		var time := float(i) / SAMPLE_RATE
		var envelope := minf(time * 1200.0, 1.0) * pow(1.0 - time / duration, 4.0)
		var tone := sin(TAU * frequency * time * (1.0 - time / (duration * 3.0)))
		if cue == Cue.RECOVERY:
			tone = sin(TAU * frequency * time) * 0.65 + sin(TAU * frequency * 1.5 * time) * 0.35
		var sample := lerpf(tone, random.randf_range(-1.0, 1.0), noise_mix)
		pcm.encode_s16(i * 2, roundi(sample * envelope * 26000.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = SAMPLE_RATE
	clip.data = pcm
	return clip
