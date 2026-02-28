extends CanvasLayer

signal start_game

var corazon_escena = preload("res://CorazonUI.tscn") 
var puntos = 0

@onready var contenedor = $ContenedorCorazones

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func actualizar_puntos(puntos):
	$LabelPuntos.text = "Puntos: " + str(puntos)
	
func actualizar_tiempo(valor):
	$LabelTiempo.text = "Tiempo: " + str(valor) + "s"

func actualizar_corazones(salud_actual):
	# 1. Borramos los corazones que existan para no encimarlos
	for hijo in contenedor.get_children():
		hijo.queue_free()
	
	# 2. Creamos tantos corazones como salud tenga el player
	for i in range(salud_actual):
		var nuevo_corazon = corazon_escena.instantiate()
		contenedor.add_child(nuevo_corazon)

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func show_game_over():
	show_message("Game Over")
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout

	$Message.text = "Dodge the Creeps!"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	
func update_score(score):
	$ScoreLabel.text = str(score)

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()

func update_effects_display(text: String):
	$EffectsLabel.text = text

func _on_message_timer_timeout() -> void:
	$Message.hide()
