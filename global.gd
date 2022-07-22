extends Node

onready var rng = RandomNumberGenerator.new()

var score = 0
var total = 0

func _ready():
    rng.randomize()

func submit_score(value: int):
    score = value
    total += score

func _process(_delta):
    if Input.is_action_just_pressed("toggle_fullscreen"):
        OS.window_fullscreen = not OS.window_fullscreen
