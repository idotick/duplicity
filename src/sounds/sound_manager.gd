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


func fade_out(key: String, duration: float) -> void:
	var temp = is_playing[0]
	if key != "":
		temp = get(key)
	
	var sound : AudioStreamPlayer = temp
	var tween : Tween = create_tween()
	
	tween.tween_property(sound, "volume_db", linear_to_db(0.001), duration)
	
	await tween.finished
	
	sound.stop()
	sound.volume_db = 0
	is_playing.erase(sound)
	
	silenced.emit()


func change_volume(key: String, lin: float, duration: float) -> void:
	var temp = is_playing[0]
	if key != "":
		temp = get(key)
	
	var sound : AudioStreamPlayer = temp
	var tween : Tween = create_tween()
	
	tween.tween_property(sound, "volume_db", linear_to_db(lin), duration)


func on_music_finished() -> void:
	RNG.randomize()
	
	for music in is_playing:
		if not music.playing:
			to_replay = music
	
	music_delay.wait_time = RNG.randi_range(3, 10)
	music_delay.start()


func _on_music_delay_timeout() -> void:
	to_replay.play()
