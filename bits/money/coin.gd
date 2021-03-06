extends Bit

onready var global = get_node("/root/Global")
onready var player = get_parent().get_node("player")

onready var collect_sound = $collect_sound

var follow_player = false
export var value = 1

func _ready():
    var _return_value = self.connect("body_entered", self, "_on_body_entered")
    sprite.connect("animation_finished", self, "_on_animation_finished")

func _process(delta):
    if sprite.animation == "idle" and player.position.distance_to(position) <= 60:
        follow_player = true
    if follow_player:
        use_3d_coordinates = false
        position += position.direction_to(player.position) * 80 * delta

func _on_body_entered(body):
    if body.name == "player":
        sprite.play("collect_" + String(global.rng.randi_range(1, 3)))
        collect_sound.play()
        if value == -1:
            player.health = 4
        else:
            player.coins += value

func _on_animation_finished():
    if sprite.animation.begins_with("collect"):
        queue_free()
