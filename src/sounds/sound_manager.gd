extends Node

# define sfx and soundtracks here
# var sfx = $SFX

func play_sound(key):
	var to_play = get(key)
	
	if to_play is AudioStreamPlayer:
		to_play.play()
	else:
		print(key + " not found!")
