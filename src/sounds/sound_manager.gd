extends Node

signal silenced


@onready var select: AudioStreamPlayer = $Select
@onready var jump: AudioStreamPlayer = $Jump
@onready var dash: AudioStreamPlayer = $Dash
@onready var death: AudioStreamPlayer = $Death
@onready var kabooie: AudioStreamPlayer = $Kabooie
@onready var active_ability: AudioStreamPlayer = $ActiveAbility
@onready var inactive_ability: AudioStreamPlayer = $InactiveAbility

@onready var title_music: AudioStreamPlayer = $TitleMusic
@onready var forest_music: AudioStreamPlayer = $ForestMusic
@onready var cave_music: AudioStreamPlayer = $CaveMusic
@onready var music_delay: Timer = $MusicDelay
@onready var RNG := RandomNumberGenerator.new()

var is_playing : Array[AudioStreamPlayer] = []
var to_replay : AudioStreamPlayer


func play(key: String) -> void:
	var sound : AudioStreamPlayer = get(key)
	
	if sound is AudioStreamPlayer:
		sound.play()
		is_playing.append(sound)
	else:
		print("Recheck if " + key + " is the right sound key.")


func get_current_volume_db(key: String) -> float:
	if is_playing.size() <= 0:
		return 0.0
	
	var temp = is_playing[0]
	if key != "":
		temp = get(key)
	
	var sound : AudioStreamPlayer = temp
	return sound.volume_db


func fade_out(key: String, duration: float) -> void:
	if is_playing.size() <= 0:
		return
	
	var temp = is_playing[0]
	if key != "":
		temp = get(key)
	
	var sound : AudioStreamPlayer = temp
	var tween : Tween = create_tween()
	
	var orig_volume_db = get_current_volume_db(key)
	
	tween.tween_property(sound, "volume_db", linear_to_db(0.001), duration)
	
	await tween.finished
	
	sound.stop()
	sound.volume_db = orig_volume_db
	is_playing.erase(sound)
	
	silenced.emit()


func change_volume(key: String, lin: float, duration: float) -> void:
	if is_playing.size() <= 0:
		return
	
	var temp = is_playing[0]
	if key != "":
		temp = get(key)
	
	var sound : AudioStreamPlayer = temp
	var tween : Tween = create_tween()
	
	tween.tween_property(sound, "volume_db", linear_to_db(lin), duration)


func stop_all() -> void:
	for sound in is_playing:
		sound.stop()


func override(key: String):
	if is_playing.size() <= 0:
		return
	
	var temp = is_playing[0]
	if key != "":
		temp = get(key)
	
	var sound : AudioStreamPlayer = temp
	for child in get_children():
		if child.name == sound.name:
			if not sound.playing:
				sound.play()
			continue
		child.stop()


func on_sfx_finished() -> void:
	for sound in is_playing:
		if !sound.name.ends_with("Music") and not sound.playing:
			is_playing.erase(sound)


func on_music_finished() -> void:
	RNG.randomize()
	
	for sound in is_playing:
		if sound.name.ends_with("Music") and not sound.playing:
			to_replay = sound
	
	music_delay.wait_time = RNG.randi_range(3, 10)
	music_delay.start()


func _on_music_delay_timeout() -> void:
	to_replay.play()
