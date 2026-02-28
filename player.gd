extends Area2D

@export var bullet_scene: PackedScene
@export var speed = 200
var screen_size
var esta_invencible = false

signal hit

var is_puffed = false # Estado de pez globo
var salud = 5
var ultima_direccion = Vector2.RIGHT

var esta_hinchado = false
var timer_hinchado: Timer

var esta_en_dash = false
var timer_dash: Timer

var radio_capsula_original: float = 0.0
var altura_capsula_original: float = 0.0

# var puede_hacer_dash = true
var timer_duracion_powerup: Timer
var timer_cooldown_dash: Timer
var esta_invulnerable_por_dash = false
var esta_dasheando: bool = false

# Estados del Dash
var tiene_powerup_activo = false  # ¿Tengo los 15 segundos de poder?
var esta_en_pleno_impulso = false # ¿Estoy volando hacia el mouse justo ahora?
var puede_usar_espacio = true     # ¿Ya pasó el medio segundo de espera?

@export var fuerza_dash = 1500    # Velocidad del impulso explosivo
var velocity = Vector2.ZERO       # Variable para el movimiento


func _ready() -> void:
	
	$TimerCooldownDash.timeout.connect(func(): puede_usar_espacio = true)
	
	timer_hinchado = Timer.new()
	add_child(timer_hinchado)
	timer_hinchado.one_shot = true
	timer_hinchado.timeout.connect(_deshinchar)
	
	timer_dash = Timer.new()
	add_child(timer_dash)
	timer_dash.one_shot = true
	timer_dash.timeout.connect(_terminar_dash)
	
	screen_size = get_viewport_rect().size
	# Al empezar, le decimos al HUD que dibuje los 5 iniciales
	# Suponiendo que el HUD es hermano del Player o está en el Main
	# $SpriteNadar.play("pez_1")
	
	if $CollisionShape2D.shape is CapsuleShape2D:
		radio_capsula_original = $CollisionShape2D.shape.radius
		altura_capsula_original = $CollisionShape2D.shape.height
	
		
	actualizar_interfaz_vida()
	hide()

func recibir_danio(cantidad: int, posicion_atacante: Vector2 = Vector2.ZERO):
	
	# Si es invencible, ignoramos el golpe
	if esta_invencible or esta_en_pleno_impulso:
		return
	
	$HurtSound.play()
	salud -= cantidad
	actualizar_interfaz_vida()
	
	var direccion_empuje = (global_position - posicion_atacante).normalized()
	position += direccion_empuje * 30 # Aumenté a 30 para que se note más
	
	if salud <= 0:
		morir()
	else:
		activar_invulnerabilidad()
		
func activar_invulnerabilidad():
	esta_invencible = true
	$TimerInvencible.start()
	
	# Efecto visual de parpadeo (opcional)
	var tween = create_tween().set_loops(5)
	tween.tween_property($SpriteNadar, "modulate:a", 0.5, 0.1)
	tween.tween_property($SpriteNadar, "modulate:a", 1.0, 0.1)

# Conecta la señal timeout del TimerInvencible
func _on_timer_invencible_timeout():
	esta_invencible = false
	$SpriteNadar.modulate.a = 1.0 # Aseguramos que sea visible

func actualizar_interfaz_vida():
	# Buscamos el HUD en la escena y llamamos a la función que creamos
	get_parent().get_node("HUD").actualizar_corazones(salud)


func _process(delta):
	# 1. Rotación
	look_at(get_global_mouse_position())
	rotation += PI
	
	# 2. Volteo (Flip)
	var debe_voltear = get_global_mouse_position().x >= global_position.x
	$SpriteNadar.flip_v = debe_voltear
	$SpriteDisparo.flip_v = debe_voltear
	$SpriteHinchado.flip_v = debe_voltear
	$SpriteDash.flip_v = debe_voltear
	$SpriteHinchadoDash.flip_v = debe_voltear

	# 3. Movimiento e Impulso
	if not esta_en_pleno_impulso:
		var input_dir = Vector2.ZERO
		if Input.is_action_pressed("move_right"): input_dir.x += 1
		if Input.is_action_pressed("move_left"): input_dir.x -= 1
		if Input.is_action_pressed("move_down"): input_dir.y += 1
		if Input.is_action_pressed("move_up"): input_dir.y -= 1
		
		velocity = input_dir.normalized() * (speed / 2 if esta_hinchado else speed) if input_dir.length() > 0 else Vector2.ZERO
			
		if Input.is_action_just_pressed("ui_select"):
			ejecutar_impulso_ataque()
			
		if Input.is_action_just_pressed("disparar") and not esta_hinchado:
			disparar()
	
	# 4. Aplicar posición y actualizar visuales
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	actualizar_visuales_estado()

func disparar():
	if $TimerDisparo.is_stopped():
		var bala = bullet_scene.instantiate()
		bala.global_position = $PuntoDisparo.global_position
		bala.rotation = rotation + PI
		get_parent().add_child(bala)
		
		$TimerDisparo.start()
		$ShootSound.play()
		
		# Solo activamos la animación, actualizar_visuales_estado se encarga del resto
		$SpriteDisparo.play("pez_disparando")
		actualizar_visuales_estado()

# Esta función se activa cuando termina CUALQUIER animación
func _on_animated_sprite_2d_animation_finished():
	# Si la animación que terminó es la de disparo...
	if $SpriteDisparo.animation == "pez_disparando":
		# 1. RESTAURAR ESCALA: Volvemos al tamaño original (100%)
		$SpriteNadar.scale = Vector2(1, 1)
		
		# 2. Volver a nadar
		$SpriteNadar.play("pez_1")

func actualizar_animacion():
	$SpriteNadar.animation = "pez_1"
	$SpriteNadar.scale = Vector2(1.0, 1.0)
	$SpriteNadar.play("pez_1")

	# Girar a la izquierda o derecha
	#if velocity.x != 0:
		#$AnimatedSprite2D.flip_h = velocity.x > 0

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si lo que tocamos es una medusa (RigidBody2D)
	# Es importante que tus medusas estén en el grupo "mobs"
	if body.is_in_group("mobs") or body is RigidBody2D:
		print("¡Impacto con medusa detectado!")
		if esta_en_pleno_impulso:
			# DAÑO DE DASH (2 puntos)
			if body.has_method("recibir_danio"):
				var daño_final = 2.0 if esta_en_pleno_impulso else 1.0
				body.recibir_danio(daño_final)
				$"DañoDash".play()
				print("¡Impacto crítico de Dash!")
			
			# Empuje extra fuerte al enemigo por el choque
			if body is RigidBody2D:
				var dir = (body.global_position - global_position).normalized()
				body.apply_central_impulse(dir * 1200)
				
		elif esta_hinchado:
			$GolpeHinchado.play()
			# 1. GANAR PUNTOS POR GOLPE
			# Llamamos al Main para sumar una pequeña cantidad (ej. 10 puntos) por el choque
			if get_parent().has_method("sumar_puntos"):
				get_parent().sumar_puntos(1.0)
			
			# 2. LÓGICA DE DAÑO SELECTIVO (Solo a Agresivas)
			# Verificamos si es la medusa agresiva (por su script o clase)
			if body.is_in_group("agresivas") == true:
				# print("Dañamdo a la Medusa !!!!!!!!!!!!!!!")
				if body.has_method("recibir_danio"):
					body.recibir_danio(1.0) # 1 punto de daño
					# print("¡Daño infligido a medusa agresiva!")
			
			
			# 2. IMPULSO FÍSICO A LA MEDUSA
			if body is RigidBody2D:
				var direccion = (body.global_position - global_position).normalized()
				var fuerza_empuje = 600 # Fuerza base
				
				# SI ES VELOZ, EL EMPUJE ES MUCHO MÁS FUERTE
				# (Asegúrate de que tus medusas veloces estén en el grupo "veloz")
				if body.is_in_group("veloz"):
					fuerza_empuje = 1600 # Casi el doble de fuerza
					print("¡SUPER REBOTE VELOZ!")
				
				# Aplicamos un impulso mucho más fuerte (800-1000) ya que no las matamos
				body.apply_central_impulse(direccion * fuerza_empuje)
				
				# Animación de rebote para el Player (Efecto de choque)
				var direccion_rebote = -direccion
				var tween = create_tween()
				var posicion_rebote = global_position + (direccion_rebote * 40)
				tween.tween_property(self, "global_position", posicion_rebote, 0.3).set_trans(Tween.TRANS_QUINT)
				
				print("¡Medusa repelida!")
		else:
			var danio_a_recibir = body.danio if "danio" in body else 1
			recibir_danio(danio_a_recibir)
		
		# 2. Si el enemigo es la medusa agresiva, la obligamos a rebotar
		if body.has_method("aplicar_rebote"):
			body.aplicar_rebote(global_position)

func morir():
	hide() # El pez desaparece
	hit.emit() # Avisa al Main para mostrar el Game Over
	# process_mode = Node.PROCESS_MODE_DISABLED
	# Desactivamos la colisión para no procesar más choques
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false) 
	set_process(false)
	get_tree().call_group("player", "queue_free")

func start(pos):
	position = pos
	show()
	is_puffed = false
	$CollisionShape2D.disabled = false
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	set_process(true)

func _deshinchar():
	esta_hinchado = false
	is_puffed = false
	
	# Volvemos a la forma de colisión original
	if $CollisionShape2D.shape is CapsuleShape2D:
		# Regresamos EXACTAMENTE a los valores originales guardados
		var tween = create_tween().set_parallel(true)
		tween.tween_property($CollisionShape2D.shape, "radius", radio_capsula_original, 0.3)
		tween.tween_property($CollisionShape2D.shape, "height", altura_capsula_original, 0.3)

	# 2. Restauramos visibilidad de sprites
	# $SpriteHinchado.hide()
	# $SpriteHinchado.stop()
	# $SpriteNadar.show()
	# $SpriteNadar.play("pez_1")
	
	# modulate = Color(1, 1, 1) # Por si habías cambiado el color
	print("Regreso a la normalidad")
	actualizar_visuales_estado()

func recolectar_powerup(tipo_recibido):
	match tipo_recibido:
		0: 
			recolectar_vida()
			$RecogerVida.play()
		1: 
			hinchar_pez()
			$HinchadoSong.play()
		2:
			activar_dash()
			$Obtenerdash.play()

func recolectar_vida():
	# Aumentamos salud pero sin pasar el máximo (ejemplo: 5)
	salud = min(salud + 1, 5) 
	
	# Actualizamos los corazones en tu pantalla
	actualizar_interfaz_vida() 
	
	print("Vida recuperada: ", salud)
	
func hinchar_pez():
	esta_hinchado = true
	is_puffed = true
	timer_hinchado.start(15.0) 
	
	# 1. Gestión de Sprites: Apagamos los normales, encendemos el gigante
	# $SpriteNadar.hide()
	# $SpriteDisparo.hide()
	# $SpriteHinchado.show()
	# $SpriteHinchado.play("hinchado") 
	
	# Escalamos SOLO la forma de colisión para que coincida con el sprite gigante
	# Asumiendo que usas un CircleShape2D, ajustamos su radio
	if $CollisionShape2D.shape is CapsuleShape2D:
		var radio_objetivo = radio_capsula_original * 2.5 # Ajusta según tu sprite
		var altura_objetivo = altura_capsula_original * 2.5
		
		var tween = create_tween().set_parallel(true) # Paralelo para que cambien a la vez
		tween.tween_property($CollisionShape2D.shape, "radius", radio_objetivo, 0.3)
		tween.tween_property($CollisionShape2D.shape, "height", altura_objetivo, 0.3)
	
	# Opcional: El pez se vuelve más lento al estar inflado
	actualizar_visuales_estado()
	print("¡MODO EMBESTIDA!")

func activar_dash():
	tiene_powerup_activo = true
	$TimerDuracionDash.start(15.0) # Iniciamos los 15 segundos
	actualizar_visuales_estado()

	
func ejecutar_impulso_explosivo():
	
	# El impulso dura muy poco (0.2s) para que sea un "latigazo"
	var duracion_vuelo = 0.2
	
	# Calculamos dirección al mouse
	var direccion_mouse = (get_global_mouse_position() - global_position).normalized()
	velocity = direccion_mouse * 1500 # Fuerza del impacto
	
	# Esperamos a que termine el impulso para devolver el control
	await get_tree().create_timer(duracion_vuelo).timeout
	
	esta_invulnerable_por_dash = false
	# No reseteamos velocity a 0 aquí para que no se frene en seco, 
	# el _process se encargará en el siguiente frame.
	
'''func activar_dash():
	esta_en_dash = true
	timer_dash.start(10.0) 
	speed = 800 
	
	# CORRECCIÓN: Solo escalamos la colisión SI ya está hinchado
	if esta_hinchado:
		if $CollisionShape2D.shape is CapsuleShape2D:
			var radio_obj = radio_capsula_original * 2.5
			var altura_obj = altura_capsula_original * 2.5
			var tween = create_tween().set_parallel(true)
			tween.tween_property($CollisionShape2D.shape, "radius", radio_obj, 0.2)
			tween.tween_property($CollisionShape2D.shape, "height", altura_obj, 0.2)
	else:
		# Si es normal, nos aseguramos de que la colisión sea la pequeña
		# (Por si acaso venías de un estado bugeado)
		if $CollisionShape2D.shape is CapsuleShape2D:
			$CollisionShape2D.shape.radius = radio_capsula_original
			$CollisionShape2D.shape.height = altura_capsula_original
	
	actualizar_visuales_estado()'''
'''func ejecutar_dash_ataque():
	if not puede_hacer_dash: return
	
	puede_hacer_dash = false
	esta_haciendo_impulso = true # Estado de ráfaga
	esta_invulnerable_por_dash = true
	timer_cooldown_dash.start()
	
	# El impulso de ataque dura muy poco (ej: 0.2 segundos)
	var timer_impulso = get_tree().create_timer(0.2)
	timer_impulso.timeout.connect(func(): esta_haciendo_impulso = false)
	
	# Calculamos dirección hacia el mouse y aplicamos fuerza inmediata
	var direccion_mouse = (get_global_mouse_position() - global_position).normalized()
	velocity = direccion_mouse * 1300 
	
	actualizar_visuales_estado()'''

func _terminar_dash():
	esta_en_dash = false
	esta_invulnerable_por_dash = false
	speed = 400
	
	# Reutilizamos tu lógica de colisión para volver a la normalidad
	if not esta_hinchado:
		if $CollisionShape2D.shape is CapsuleShape2D:
			var tween = create_tween().set_parallel(true)
			tween.tween_property($CollisionShape2D.shape, "radius", radio_capsula_original, 0.3)
			tween.tween_property($CollisionShape2D.shape, "height", altura_capsula_original, 0.3)
	
	actualizar_visuales_estado()
	
	# Si YA NO estamos hinchados, devolvemos la colisión a la normalidad
	if not esta_hinchado:
		if $CollisionShape2D.shape is CapsuleShape2D:
			var tween = create_tween().set_parallel(true)
			tween.tween_property($CollisionShape2D.shape, "radius", radio_capsula_original, 0.3)
			tween.tween_property($CollisionShape2D.shape, "height", altura_capsula_original, 0.3)
	
	actualizar_visuales_estado()
	
	
func actualizar_visuales_estado():
	# Ocultamos todos primero
	$SpriteNadar.hide()
	$SpriteHinchado.hide()
	$SpriteDash.hide()
	$SpriteHinchadoDash.hide()
	$SpriteDisparo.hide()

	# PRIORIDAD 1: Dash (Impulso explosivo)
	if esta_en_pleno_impulso:
		if esta_hinchado:
			$SpriteHinchadoDash.show()
			$SpriteHinchadoDash.play("hinchado_dash")
		else:
			$SpriteDash.show()
			$SpriteDash.play("pez_dash")
	
	# PRIORIDAD 2: Disparo (Solo si la animación está corriendo)
	elif $SpriteDisparo.is_playing() and $SpriteDisparo.animation == "pez_disparando":
		$SpriteDisparo.show()

	# PRIORIDAD 3: Hinchado
	elif esta_hinchado:
		$SpriteHinchado.show()
		$SpriteHinchado.play("hinchado")
	
	# PRIORIDAD 4: Normal
	else:
		$SpriteNadar.show()
		# Solo play si nos movemos
		if velocity.length() > 0:
			$SpriteNadar.play("pez_1")
		else:
			$SpriteNadar.stop()
			
	# Feedback del Powerup
	modulate = Color(1.5, 1.5, 1.5) if tiene_powerup_activo else Color(1, 1, 1)


func _on_timer_duracion_dash_timeout() -> void:
	tiene_powerup_activo = false
	actualizar_visuales_estado()
	
func ejecutar_impulso_ataque():
	# Solo si tengo el power-up y no estoy en enfriamiento
	if not tiene_powerup_activo or not puede_usar_espacio:
		return
	
	$DashSound.play()
	# Bloqueamos el uso repetido
	puede_usar_espacio = false
	esta_en_pleno_impulso = true
	$TimerCooldownDash.start() # Reinicia el medio segundo de espera
	
	# Calculamos dirección hacia el ratón
	var direccion = (get_global_mouse_position() - global_position).normalized()
	velocity = direccion * fuerza_dash
	
	# El impulso dura un instante (0.2s)
	await get_tree().create_timer(0.2).timeout
	esta_en_pleno_impulso = false
	
	actualizar_visuales_estado()


func _on_timer_cooldown_dash_timeout() -> void:
	if $SpriteDisparo.animation == "pez_disparando":
		$SpriteDisparo.hide()
		actualizar_visuales_estado()


func _on_sprite_disparo_animation_finished() -> void:
	if $SpriteDisparo.animation == "pez_disparando":
		$SpriteDisparo.stop() # Detenemos la animación
		actualizar_visuales_estado() # Esto ocultará el disparo y mostrará al pez normal


func _on_timer_power_ups_timeout() -> void:
	pass # Replace with function body.
