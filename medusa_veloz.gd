extends MedusaBase

func _ready():
	# 1. Stats de proyectil
	salud = 1.0
	danio = 1.0
	speed = 550
	valor_puntos = 1.0
	
	# 2. Buscamos al jugador
	var player = get_tree().get_first_node_in_group("player")
	
	if is_instance_valid(player):
		# CALCULAMOS EL VECTOR DE DISPARO
		# (Posición Jugador - Mi posición) nos da el camino exacto
		var vector_hacia_jugador = (player.global_position - global_position).normalized()
		
		# APLICAMOS LA VELOCIDAD FÍSICA HACIA ESE VECTOR
		linear_velocity = vector_hacia_jugador * speed
		
		# ROTACIÓN VISUAL (Cabeza hacia el jugador)
		rotation = vector_hacia_jugador.angle() + PI / 2
		
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play()
		
		# IMPORTANTE: Imprime esto en la consola para depurar si sale disparada
		print("Medusa Veloz disparada hacia: ", player.global_position)
	else:
		# Si no hay jugador, que siga el comportamiento del padre
		super._ready()

	add_to_group("mobs")
