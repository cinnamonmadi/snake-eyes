extends Area2D

var SPEED = 300

var direction = Vector2.ZERO

func _ready():
    add_to_group("clear_on_death")

    var _return_value = connect("body_entered", self, "_on_body_entered")

func start(with_heading: Vector2):
    direction = with_heading
    $sprite.rotation = direction.angle()

func _process(delta):
    var velocity = direction * SPEED * delta
    position += velocity

func _on_body_entered(body):
    if body.has_method("handle_enemy_bullet"):
        body.handle_enemy_bullet()
    queue_free()
