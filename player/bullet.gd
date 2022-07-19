extends Area2D

const SPEED = 300

var direction = Vector2.ZERO
var is_dead = false

func _ready():
    add_to_group("clear_on_death")

    var _return_value = connect("body_entered", self, "_on_body_entered")

func start(with_heading: Vector2):
    direction = with_heading
    $sprite.rotation = direction.angle()

func _process(delta):
    if is_dead:
        visible = false
        if not $hit_sound.is_playing():
            queue_free()
        return
    var velocity = direction * SPEED * delta
    position += velocity

func _on_body_entered(body):
    if is_dead:
        return
    if body.has_method("handle_player_bullet"):
        body.handle_player_bullet()
        $hit_sound.play()
    is_dead = true
