extends CanvasLayer

onready var color_rect = $ColorRect

enum State {
    FINISHED,
    FADE_IN,
    FADE_OUT
}

var state = State.FINISHED
var fade_duration: float = 0.5
var fade_timer: float = 0.0

func _ready():
    pass 

func is_finished():
    return state == State.FINISHED

func fade_out():
    state = State.FADE_OUT
    fade_timer = fade_duration
    color_rect.color.a = 0.0

func fade_in():
    state = State.FADE_IN
    fade_timer = fade_duration
    color_rect.color.a = 1.0

func _process(delta):
    if state != State.FINISHED:
        fade_timer -= delta
        if fade_timer <= 0:
            if state == State.FADE_OUT:
                color_rect.color.a = 1.0
            elif state == State.FADE_IN:
                color_rect.color.a = 0.0
            state = State.FINISHED

    if state == State.FADE_OUT:
        color_rect.color.a = 1.0 - (fade_timer / fade_duration)
    if state == State.FADE_IN:
        color_rect.color.a = fade_timer / fade_duration
