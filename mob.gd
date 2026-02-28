extends RigidBody2D

# Variables que el código llenará solo
var health: float = 2.0
var damage: float = 1.0
var speed: float = 200.0
var is_aggressive: bool = false

var player = null

func _ready():
	# 1. AUTO-CONFIGURACIÓN: Mira el nombre del archivo para ponerse sus stats
	var file_name = scene_file_path
	print(file_name, typeof(file_name))
	if "res://MedusaAgresiva" in file_name:
		health = 6.0
		damage = 3.0
		speed = 350.0
		is_aggressive = true
	elif "Fuerte" in file_name:
		health = 4.0
		damage = 2.0
		speed = 120.0
	elif "res://MedusaVeloz.tscn" in file_name:
		health = 1.0
		damage = 0.5
		speed = 1550.0
	else: # Por defecto es la Normal
		health = 2.0
		damage = 1.0
		speed = 250.0

	# 2. CONFIGURACIÓN DE GRUPOS (Vital para que se borren al reiniciar)
	add_to_group("mobs")

	# 3. LÓGICA DE PERSECUCIÓN
	if is_aggressive:
		player = get_tree().get_first_node_in_group("player")
		gravity_scale = 0 
		add_to_group("agresivas")
	
	# Mensaje de confirmación en la consola
	print("Spawn: ", file_name, " | Vida: ", health, " | Vel: ", speed)

func _physics_process(_delta):
	if is_aggressive and player:
		var direction = (player.global_position - global_position).normalized()
		linear_velocity = direction * speed
		rotation = direction.angle()

func take_damage(type: int):
	if type == 0: # DISPARO
		health -= 1.0
	elif type == 1: # ATAQUE FÍSICO
		health -= 0.86 
	
	if health <= 0:
		# Desactivamos colisión para evitar errores antes de borrar
		$CollisionShape2D.set_deferred("disabled", true)
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
