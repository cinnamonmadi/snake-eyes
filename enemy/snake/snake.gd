extends Enemy

func _ready():
    MOVE_SPEED = 80
    MAX_HEALTH = 2

    USE_STRAFE_RADIUS = false
    USE_PREDICTED_POSITION = false

    TREASURE_BOMB_FRAME = 10
