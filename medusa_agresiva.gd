extends MedusaBase # En lugar de RigidBody2D, hereda de tu base

var player = null
var ultima_direccion = Vector2.ZERO
var esta_aturdida = false

func _ready():
	salud = 3.0
	danio = 1.0
	speed = 330
	valor_puntos = 2.0
	
	# Forzamos la configuración de detección de choques
	contact_monitor = true
	max_contacts_reported = 5
	
	# Añadimos a lgrupo ("Agresivas") para que Main pueda contar cuantas hay
	add_to_group("agresivas")
	
	$AnimatedSprite2D.play("nadar_4")
	# Buscamos al jugador por su grupo
	player = get_tree().get_first_node_in_group("player")
	# No llamamos a super._ready() porque no queremos el impulso inicial recto
	add_to_group("mobs")

func _process(delta):
	# 1. Llamamos al tiempo de la base para el balanceo
	time += delta
	var balanceo = sin(time * 2.0) * 0.1
	
	# 2. Hacemos que el Sprite siga la rotación del cuerpo (RigidBody)
	# que tú ya calculas correctamente en el _physics_process
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.rotation = balanceo 
		# Al usar .rotation (local) en lugar de .global_rotation, 
		# el sprite heredará la rotación del cuerpo que mira al jugador.

func _physics_process(_delta):
	# Si está aturdida por el rebote, no calculamos dirección (dejamos que la física actúe)
	if esta_aturdida:
		return
	# 1. Si el jugador existe y está vivo

	if is_instance_valid(player) and player.visible and player.process_mode == Node.PROCESS_MODE_INHERIT:
		# print("EL JUGADOR ESTA HULLENDO")
		# Calculamos dirección hacia el jugador
		ultima_direccion = (player.global_position - global_position).normalized()
		# Aplicamos movimiento

		linear_velocity = ultima_direccion * speed

		# ROTACIÓN CORREGIDA:
		# .angle() apunta a la derecha. Sumamos PI/2 (90 grados) 
		# para que la parte de ARRIBA de la cabeza sea el frente.
		rotation = ultima_direccion.angle() + PI / 2
	else:
		# print("EL JUGADOR A MUERTO")
		# 2. Si el jugador muere, seguir de largo en la última dirección
		if ultima_direccion != Vector2.ZERO:
			linear_velocity = ultima_direccion * speed
			# Mantenemos la rotación que tenía al momento de perder al jugador
			rotation = ultima_direccion.angle() + PI / 2
		else:
			# Si nunca vio al jugador, va hacia "abajo" de su propia cabeza
			linear_velocity = Vector2.UP.rotated(rotation) * speed

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Borra la medusa cuando sale de pantalla
	
# Cambiamos body: Node por area: Area2D
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		print("¡CHOQUE CON AREA DETECTADO! Rebotando...")
		aplicar_rebote(area.global_position)
		
		# También llamamos al daño aquí
		if area.has_method("recibir_danio"):
			area.recibir_danio(danio, global_position)
		
func aplicar_rebote(posicion_jugador):
	esta_aturdida = true
	print("Rebotando . . . AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAS")
	
	# 1. Efecto Visual: El Sprite da vueltas (Spin)
	if has_node("AnimatedSprite2D"):
		# Creamos un Tween que actúe sobre el sprite
		var tween = create_tween()
		
		# Hacemos que la rotación LOCAL del sprite de 2 vueltas completas (4 * PI)
		# en medio segundo (0.5), usando una transición suave.
		var rotacion_vueltas = 4 * PI # 2 vueltas (360° * 2)
		
		# tween_property(objeto, propiedad, valor_final, duracion)
		tween.tween_property($AnimatedSprite2D, "rotation", rotacion_vueltas, 0.5)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
		# Al terminar el tween (0.5s), reseteamos la rotación local a 0
		# para que el balanceo del _process vuelva a funcionar normalmente.
		tween.finished.connect(func(): $AnimatedSprite2D.rotation = 0)
	
	linear_velocity = Vector2.ZERO
	
	# Calculamos la dirección opuesta al jugador
	var direccion_retroceso = (global_position - posicion_jugador).normalized()
	
	# Aplicamos una fuerza de impulso hacia atrás
	# Usamos apply_central_impulse para un golpe seco y físico
	apply_central_impulse(direccion_retroceso * 300) 
	
	# Esperamos medio segundo antes de volver a atacar
	await get_tree().create_timer(0.5).timeout
	esta_aturdida = false
	
'''func _physics_process(_delta):
	# Intentar encontrar al jugador si no lo tenemos o si el que teníamos ya no sirve
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	# Si el jugador existe y está vivo
	if is_instance_valid(player) and player.visible:
		# Calculamos dirección hacia el jugador
		ultima_direccion = (player.global_position - global_position).normalized()
		
		# Aplicamos movimiento
		linear_velocity = ultima_direccion * speed
		
		# ROTACIÓN CORREGIDA:
		# .angle() apunta a la derecha. Sumamos PI/2 (90 grados) 
		# para que la parte de ARRIBA de la cabeza sea el frente.
		rotation = ultima_direccion.angle() + PI / 2
		
	else:
		pass
		# 2. Si el jugador muere o no está, seguir de largo
		if ultima_direccion != Vector2.ZERO:
			linear_velocity = ultima_direccion * speed
		else:
			# Movimiento por defecto si nunca lo vio
			linear_velocity = Vector2(0, speed).rotated(rotation)'''
