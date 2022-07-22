extends Node2D

var music 

export var music_loop_delay: float = 0.0
var music_loop_timer: float = 0.0
var is_playing = true

func _ready():
    music = get_child(get_node("/root/Global").rng.randi_range(0, get_child_count() - 1))

func stop():
    music.stop()
    is_playing = false

func _process(delta):
    if not is_playing:
        return
    if music_loop_timer > 0:
        music_loop_timer -= delta
        if music_loop_timer <= 0:
            music.play()
    if not music.playing:
        if music_loop_timer == 0:
            music.play()
        else:
            music_loop_timer = music_loop_delay
