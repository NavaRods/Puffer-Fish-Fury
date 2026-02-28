extends Area2D

@export var speed = 1100

func _ready():
	$AnimatedSprite2D.play("disparo_agua")

func _process(delta):
	# Vector2.RIGHT es (1, 0). Al rotarlo, se convierte en la dirección deseada.
	var velocidad_vector = Vector2.RIGHT.rotated(rotation) * speed
	position += velocidad_vector * delta

# Se borra al salir de pantalla para no gastar memoria
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# Detecta el choque con las medusas (RigidBody2D)
func _on_body_entered(body):
	if body.is_in_group("mobs"):
		if body.has_method("recibir_danio"):
			body.recibir_danio(1) # Cada bala quita 1 de vida al mob
		queue_free() # La bala siempre desaparece al impactar
