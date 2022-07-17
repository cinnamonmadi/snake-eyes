extends Control

onready var sprite = $sprite

var elder_dying = false

func _ready():
    sprite.connect("animation_finished", self, "_on_animation_finished")

func _process(_delta):
    if sprite.animation != "cya":
        if elder_dying:
            sprite.play("yikes")
        else:
            sprite.play("default")

func cya():
    emit_signal("dying")
    sprite.play("cya")

func _on_animation_finished():
    if sprite.animation == "cya":
        emit_signal("dead")
        queue_free()
