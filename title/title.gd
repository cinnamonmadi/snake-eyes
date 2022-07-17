extends Node2D

onready var fade = $fade
onready var prompt = $prompt
onready var timer = $timer
onready var intro = $intro

onready var first_level = preload("res://level_first.tscn")

var first_level_scene

enum State {
    FADE_IN,
    WAIT,
    ANIMATE,
    FADE_OUT
}

var state = State.FADE_IN

func _ready():
    timer.connect("timeout", self, "_on_timeout")
    intro.connect("animation_finished", self, "_on_animation_finished")
    fade.fade_in()

func _process(_delta):
    if state == State.FADE_IN and fade.is_finished():
        state = State.WAIT
        timer.start(2.0)
    elif state == State.WAIT and Input.is_action_just_pressed("shoot"):
        state = State.ANIMATE
        timer.stop()
        prompt.visible = false
        intro.play("intro")
        first_level_scene = first_level.instance()
    elif state == State.FADE_OUT and fade.is_finished():
        get_parent().add_child(first_level_scene)
        queue_free()

func _on_timeout():
    prompt.visible = not prompt.visible
    timer.start(0.5)

func _on_animation_finished():
    if intro.animation == "intro":
        state = State.FADE_OUT
        intro.stop()
        intro.frame = 58
        fade.fade_out()
