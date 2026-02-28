extends Area2D

@onready var icon = $Sprite2D

enum PowerType {
	DASH,
	SHIELD,
	ENEMY_SMALL,
	ENEMY_MORE,
	ENEMY_FAST,
	PLAYER_BIG,
	PLAYER_SLOW,
	SCORE_PLUS_5,
	SCORE_PLUS_10,
	SCORE_PLUS_50,
	SCORE_MINUS_5,
	SCORE_MINUS_10,
	SCORE_MINUS_50,
	KILL_ALL
}

@export var type: PowerType
signal collected(power_type)

func _ready():
	# No es necesario usar connect() manualmente si lo haces desde el editor, 
	# pero si prefieres por código, asegúrate de que no esté duplicado.
	
	# Diccionario de texturas para limpiar el match (opcional pero más limpio)
	_setup_visuals()

func _setup_visuals():
	var path = "res://assets/powerups/pu_"
	var texture_name = ""
	
	match type:
		PowerType.DASH: texture_name = "dash"
		PowerType.SHIELD: texture_name = "shield"
		PowerType.ENEMY_SMALL: texture_name = "enemy_small"
		PowerType.ENEMY_MORE: texture_name = "enemy_more"
		PowerType.ENEMY_FAST: texture_name = "enemy_fast"
		PowerType.PLAYER_BIG: texture_name = "player_big"
		PowerType.PLAYER_SLOW: texture_name = "player_slow"
		PowerType.SCORE_PLUS_5: texture_name = "score_plus_5"
		PowerType.SCORE_PLUS_10: texture_name = "score_plus_10"
		PowerType.SCORE_PLUS_50: texture_name = "score_plus_50"
		PowerType.SCORE_MINUS_5: texture_name = "score_minus_5"
		PowerType.SCORE_MINUS_10: texture_name = "score_minus_10"
		PowerType.SCORE_MINUS_50: texture_name = "score_minus_50"
		PowerType.KILL_ALL: texture_name = "kill_all"
	
	if texture_name != "":
		icon.texture = load(path + texture_name + ".png")

func _on_area_entered(area):
	if area.is_in_group("player"): # Mucho más confiable que el nombre
		collected.emit(type)
		queue_free()
