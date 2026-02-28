extends MedusaBase # En lugar de RigidBody2D, hereda de tu base

func _ready():
	# Esto cambia la velocidad antes de que el base la use
	salud = 5.0
	danio = 2.0
	speed = 200
	valor_puntos = 4.0
	# Ejecuta el _ready del padre (el que da el impulso y añade al grupo)
	super._ready()
