extends CanvasLayer

func _ready():
	hide() # Empezamos ocultos

func _input(event):
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" es ESC por defecto
		toggle_pausa()

func toggle_pausa():
	var nuevo_estado = !get_tree().paused
	get_tree().paused = nuevo_estado
	visible = nuevo_estado
	var musica = get_parent().get_node("BackSong")
	# Si pausamos, liberamos el ratón para poder hacer clic
	if nuevo_estado:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		musica.volume_db = -15 # Baja el volumen (en decibelios)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # O el modo que uses
		musica.volume_db = 0  # Vuelve al volumen normal

func _on_continuar_pressed():
	toggle_pausa()

func _on_reiniciar_pressed(): # Menu de inicio
	get_tree().paused = false
	hide()
	# get_tree().reload_current_scene()
	get_parent().new_game()

func _on_menu_principal_pressed():
	get_tree().paused = false
	# Cambia "res://MenuInicio.tscn" por la ruta de tu menú real
	get_tree().change_scene_to_file("res://Main.tscn")
