extends Node

@export var mob_scenes: Array[PackedScene] = [] # 0:Normal, 1:Fuerte, 2:Veloz, 3:Agresiva
@export var player_scene: PackedScene
@export var powerup_scene: PackedScene

var tiempo = 0
var player_instancia = null
var puntos = 0

func _ready() -> void:
	# $HUD.update_score(score)
	puntos = 0
	tiempo = 0
	# Conectamos la señal de que terminó para que se repita
	$BackSong.finished.connect(_on_back_song_finished)
	$BackSong.play()
	$HUD.actualizar_puntos(puntos)
	$HUD.actualizar_tiempo(tiempo)
	
func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$BackSong.stop()
	$DeathSound2.play()
	

func new_game():
	puntos = 0
	tiempo = 0
	$HUD.actualizar_tiempo(tiempo)
	$HUD.show_message("Get Ready")
	$HUD.actualizar_puntos(puntos)
	
	if is_instance_valid(player_instancia):
		player_instancia.queue_free()
	
	# 2. Creamos un nuevo Player desde la "plantilla"
	player_instancia = player_scene.instantiate()
	add_child(player_instancia)
	player_instancia.add_to_group("player")
	player_instancia.hit.connect(game_over)
	player_instancia.start($StartPosition.position)
	# $player.start($StartPosition.position)
	# Limpia enemigos anteriores
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("powerups", "queue_free")
	
	$BackSong.volume_db = 0 # O el volumen original que uses
	if not $BackSong.playing:
		$BackSong.play()
	$StartTimer.start()

func sumar_puntos(cantidad):
	puntos += cantidad
	$HUD.actualizar_puntos(puntos)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()

# --- LÓGICA DE ENEMIGOS ---
func _on_mob_timer_timeout():
	if mob_scenes.is_empty(): return 

	var speed_min = 150.0
	var speed_max = 250.0

	# Spawn de la medusa principal
	var mob_escogido = _seleccionar_mob_por_rareza()
	_spawn_single_mob(mob_escogido, speed_min, speed_max)
	
	if randf() <= 0.10:
		spawn_powerup_aleatorio()

func spawn_powerup_aleatorio():
	if not powerup_scene: return
	
	var p_up = powerup_scene.instantiate()
		
	# --- RAREZA SOLO PARA UTILIDAD ---
	var suerte = randf()
	if suerte < 0.15:  
		p_up.tipo = 2 # DASH (30% - 40%)
	elif suerte < 0.30:                
		p_up.tipo = 1 # HINCHADO (60% - 70%)
	else:
		p_up.tipo = 3 # NADA
		
	
	# --- POSICIÓN Y DIRECCIÓN (Igual que antes, 4 bordes) ---
	var screen_size = get_viewport().get_visible_rect().size
	var lado = randi() % 4
	var pos_inicio = Vector2.ZERO
	var dir_final = Vector2.ZERO
	var margen = 60

	match lado:
		0: # Arriba
			pos_inicio = Vector2(randf_range(margen, screen_size.x - margen), -margen)
			dir_final = Vector2(randf_range(-0.5, 0.5), 1)
		1: # Abajo
			pos_inicio = Vector2(randf_range(margen, screen_size.x - margen), screen_size.y + margen)
			dir_final = Vector2(randf_range(-0.5, 0.5), -1)
		2: # Izquierda
			pos_inicio = Vector2(-margen, randf_range(margen, screen_size.y - margen))
			dir_final = Vector2(1, randf_range(-0.5, 0.5))
		3: # Derecha
			pos_inicio = Vector2(screen_size.x + margen, randf_range(margen, screen_size.y - margen))
			dir_final = Vector2(-1, randf_range(-0.5, 0.5))

	p_up.position = pos_inicio
	if "direccion" in p_up:
		p_up.direccion = dir_final.normalized()
	
	add_child(p_up)
	
func soltar_corazon_en_posicion(pos_medusa):
	# Probabilidad de soltar vida (ejemplo: 15% de probabilidad)
	if randf() <= 0.15: 
		var corazon = powerup_scene.instantiate()
		corazon.tipo = 0 # VIDA
		corazon.position = pos_medusa
		
		# IMPORTANTE: El corazón no debe salir volando, 
		# le damos una dirección muy lenta o cero para que "flote" ahí.
		if "direccion" in corazon:
			corazon.direccion = Vector2.ZERO 
			corazon.velocidad = 0 # Se queda quieto donde murió la medusa
			
		add_child(corazon)

func _spawn_single_mob(escena, s_min, s_max):
	var mob = escena.instantiate()
	
	# Ubicación aleatoria en el Path
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position
	
	# Dirección inicial
	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	
	mob.murio.connect(sumar_puntos)

	add_child(mob)
	
	# Si la medusa es Veloz o Agresiva, ellas manejan su velocidad.
	# Si es Normal o Fuerte, el Main les asigna velocidad aquí.
	if mob.linear_velocity.length() == 0 and not mob.get("is_aggressive"):
		var final_speed = randf_range(s_min, s_max)
		mob.linear_velocity = Vector2(final_speed, 0.0).rotated(direction)

func _seleccionar_mob_por_rareza() -> PackedScene:
	var n = randf()
	
	# Probabilidades: 
	# Agresiva (5%), Veloz (14%), Fuerte (15%), Normal (66%)
	if n >= 0.95:
		# Límite de 3 agresivas en pantalla para no saturar
		if get_tree().get_nodes_in_group("agresivas").size() < 3:
			return mob_scenes[3]
		return mob_scenes[0]
	
	if n < 0.66:
		return mob_scenes[0] # Normal
	elif n < 0.81:
		return mob_scenes[1] # Fuerte
	else:
		return mob_scenes[2] # Veloz

func _on_score_timer_timeout() -> void:
	tiempo += 1
	$HUD.actualizar_tiempo(tiempo)

func _on_hud_start_game() -> void:
	new_game()


func _on_player_hit() -> void:
	pass # Replace with function body.


func _on_power_up_timer_timeout() -> void:
	spawn_powerup_aleatorio()
	
	# Cambiamos el tiempo para el PRÓXIMO power-up de forma aleatoria
	# Hará que el jugador nunca sepa cuándo vendrá el siguiente.
	$PowerupTimer.wait_time = randf_range(12.0, 25.0) 
	$PowerupTimer.start()

func _on_back_song_finished() -> void:
	$BackSong.play()
