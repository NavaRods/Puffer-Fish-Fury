extends RigidBody2D
class_name MedusaBase

@export var salud: float = 3.0 # Usaremos solo esta
@export var danio: float = 1.0
@export var speed: float = 200.0
@export var valor_puntos: float = 100.0 # Ajusta a tu gusto

signal murio(puntos_ganados)
# var PowerUpEscena = preload("res://power_up.tscn")
var escena_vida = preload("res://power_up.tscn")
var escena_explosion = preload("res://ExplosionMedusa.tscn") # Asegúrate de que la ruta sea correcta

var time = 0.0

func _ready():
	add_to_group("mobs")
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play()
	
	# El impulso inicial (solo si no se sobreescribe en las hijas como la agresiva)
	if linear_velocity == Vector2.ZERO:
		var direction = Vector2.RIGHT.rotated(rotation)
		linear_velocity = direction * speed

func _process(delta):
	time += delta
	# 1. Efecto de balanceo que ya tenías
	time += delta
	var balanceo = sin(time * 2.0) * 0.1
	
	# 2. LA CLAVE: Forzamos al Sprite a tener rotación GLOBAL 0
	# Esto hace que aunque el RigidBody rote 45°, el Sprite rote -45° 
	# para quedarse siempre mirando hacia arriba.
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.global_rotation = 0 + balanceo

# UNIFICAMOS LAS FUNCIONES DE DAÑO
func recibir_danio(cantidad):
	# Si 'cantidad' es 0, podemos asumir que es daño de bala estándar (1.0)
	# Si mandas un valor específico (como el 0.86 del hinchado), lo usará.
	salud -= cantidad
	
	print("Medusa golpeada. Salud restante: ", salud)
	
	if salud <= 0:
		morir_con_puntos()

func morir_con_puntos():
	# 1. EFECTO DE MUERTE (Visual y Sonido)
	var explosion = escena_explosion.instantiate()
	explosion.global_position = global_position
	# Lo añadimos al Main (get_parent() o al current_scene)
	get_tree().current_scene.add_child(explosion)
	
	# Emitimos la señal antes de desaparecer
	murio.emit(valor_puntos)
	
	# Probabilidad del 15% (0.15)
	if randf() <= 0.15:
		# Instanciamos el Power-Up
		var drop = escena_vida.instantiate()
		# Lo ponemos donde estaba la medusa
		drop.global_position = global_position
		# IMPORTANTE: Cambiamos su tipo a 0 (Vida)
		drop.tipo = 0
		# Lo añadimos a la escena principal
		get_tree().current_scene.add_child(drop)
		# get_parent().add_child(p_up)
		
	# Desactivamos colisión por seguridad
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
