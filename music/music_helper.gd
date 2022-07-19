extends Node2D

onready var music = $music

export var music_loop_delay: float = 0.0
var music_loop_timer: float = 0.0

func _ready():
    pass 

func _process(delta):
    if music_loop_timer > 0:
        music_loop_timer -= delta
        if music_loop_timer <= 0:
            music.play()
    if not music.playing:
        if music_loop_timer == 0:
            music.play()
        else:
            music_loop_timer = music_loop_delay