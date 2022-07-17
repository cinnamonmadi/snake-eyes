extends Node

onready var rng = RandomNumberGenerator.new()

var your_score = 0
var high_scores = []

func _ready():
    rng.randomize()

func submit_score(value: int):
    your_score = value
    high_scores.append(your_score)
    high_scores.sort()
    if high_scores.size() == 4:
        high_scores.remove(0)