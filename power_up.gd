extends Area2D

# 0 = Vida, 1 = Gigante, 2 = Dash
@export_enum("Vida", "Gigante", "Dash", "nada") var tipo: int = 0
var velocidad = 120
var direccion = Vector2.LEFT # Por defecto va a la izquierda

func _ready():
	add_to_group("powerups")
	# Solo mostramos el sprite de regenerar para esta parte
	$PowerupRegenerar.visible = false	
	$PowerupGiganteCroqueta.visible = false
	$PowerupDashCroquetaNuevo.visible = false
	
	# Mostramos solo el que corresponde al tipo
	match tipo:
		0: $PowerupRegenerar.visible = true
		1: $PowerupGiganteCroqueta.visible = true
		2: $PowerupDashCroquetaNuevo.visible = true


func _process(delta):
	# Ahora el movimiento depende de la dirección asignada
	position += direccion * velocidad * delta
	
	# Si sale mucho de los límites, se borra (limpieza automática)
	var margin = 200
	var screen = get_viewport_rect().size
	if position.x < -margin or position.x > screen.x + margin or \
	   position.y < -margin or position.y > screen.y + margin:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Comprobamos si lo que entró es el jugador
	if area.is_in_group("player"):
		# Le decimos al jugador que aplique el efecto de vida
		'''if area.has_method("recolectar_vida"):
			area.recolectar_vida()
			queue_free() # El corazón desaparece al ser recolectado
			'''
		if area.has_method("recolectar_powerup"):
			area.recolectar_powerup(tipo)
			queue_free()
