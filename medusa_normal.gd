extends MedusaBase # En lugar de RigidBody2D, hereda de tu base

func _ready():
	# Esto cambia la velocidad antes de que el base la use
	salud = 2.0
	danio = 1.0
	speed = 250
	valor_puntos = 1.0
	# Ejecuta el _ready del padre (el que da el impulso y añade al grupo)
	super._ready()
