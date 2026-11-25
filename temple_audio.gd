extends Node

const AMBIENCE := preload("res://assets/audio/temple.wav")
const TREMOR := preload("res://assets/audio/tremor.wav")
const OPEN := preload("res://assets/audio/lid_open.wav")
const CLOSE := preload("res://assets/audio/lid_close.wav")
const IMPACT := preload("res://assets/audio/slab_impact.wav")
const EXIT := preload("res://assets/audio/exit.wav")
const AMBIENCE_VOLUME := -6.0

var _ambient: AudioStreamPlayer
var _tremor: AudioStreamPlayer
var _lid: AudioStreamPlayer
var _impact: AudioStreamPlayer
var _exit: AudioStreamPlayer


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_ambient = _player(_loop(AMBIENCE, 12.0), AMBIENCE_VOLUME)
	_tremor = _player(_loop(TREMOR, 2.0), -10.0)
	_lid = _player(null, -7.0)
	_impact = _player(IMPACT, -8.0)
	_exit = _player(EXIT, -7.0)
	_ambient.play()


func set_lid(open: bool) -> void:
	if _lid == null:
		return
	_lid.stream = OPEN if open else CLOSE
	_lid.play()
	if open:
		_tremor.play()
	else:
		_tremor.stop()


func slab_impact() -> void:
	if _impact != null:
		_impact.play()


func reached_exit() -> void:
	if _exit != null:
		_exit.play()


func set_ending_blend(blend: float) -> void:
	if _ambient == null:
		return
	_ambient.volume_db = lerpf(AMBIENCE_VOLUME, -55.0, blend)
	if blend >= 1.0:
		_ambient.stop()


func reset() -> void:
	if _ambient == null:
		return
	_stop_cues()
	_ambient.volume_db = AMBIENCE_VOLUME
	if not _ambient.playing:
		_ambient.play()


func _stop_cues() -> void:
	_tremor.stop()
	_lid.stop()
	_impact.stop()
	_exit.stop()


func _exit_tree() -> void:
	if _ambient != null:
		_ambient.stop()
		_stop_cues()


func _player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	return player


func _loop(stream: AudioStreamWAV, seconds: float) -> AudioStreamWAV:
	var loop := stream.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = roundi(seconds * loop.mix_rate)
	return loop
