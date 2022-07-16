extends Area2D

const SPEED = 300

var direction = Vector2.ZERO

func _ready():
    var _return_value = connect("body_entered", self, "_on_body_entered")

func start(with_heading: Vector2):
    direction = with_heading
    $sprite.rotation = direction.angle()

func _process(delta):
    var velocity = direction * SPEED * delta
    position += velocity

func _on_body_entered(body):
    if body.has_method("handle_player_bullet"):
        body.handle_player_bullet()
    queue_free()