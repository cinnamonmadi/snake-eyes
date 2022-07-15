extends Area2D

const SPEED = 300

var direction = Vector2.ZERO

func _ready():
    pass 

func start(with_heading: Vector2):
    direction = with_heading
    $sprite.rotation = direction.angle()

func _process(delta):
    var velocity = direction * SPEED * delta
    position += velocity