extends GPUParticles2D

func _ready():
	$MuerteSong.play()
	emitting = true
	# Esperamos a que el sonido y las partículas terminen para borrar la escena
	await get_tree().create_timer(1.0).timeout 
	queue_free()
